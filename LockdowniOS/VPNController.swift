//
//  VPNController.swift
//  Lockdown
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import CocoaLumberjackSwift

let kVPNLocalizedDescription = "Lockdown VPN"

class VPNController: NSObject {
    
    static let shared = VPNController()
    
    let manager = NEVPNManager.shared()
    
    private override init() {
        super.init()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in })
    }
    
    func status() -> NEVPNStatus {
        return manager.connection.status
    }
    
    func restart() {
        // Don't let this affect userWantsVPNOn/Off config
        VPNController.shared.setEnabled(false, completion: {
            error in
            // TODO: Handle the error
            VPNController.shared.setEnabled(true)
        })
    }
 
    func setEnabled(_ enabled: Bool, completion: @escaping (_ error: Error?) -> Void = {_ in }) {
        DDLogInfo("VPNController set enabled: \(enabled)")
        setUserWantsVPNEnabled(enabled)
        if (enabled) {
            setUpAndEnableVPN { error in
                completion(error)
            }
        }
        else {
            manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
                self.manager.isEnabled = false
                self.manager.isOnDemandEnabled = false
                self.manager.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                    // TODO: will this ever error?
                    completion(error)
                })
            })
        }
    }
    
    private func setUpAndEnableVPN(completion: @escaping (_ error: Error?) -> Void) {
        guard let vpnCredentials = getVPNCredentials() else {
            // TODO: handle error
            return completion("No VPN credentials found while enabling VPN")
        }
        
        let serverAddress = getSavedVPNRegion().serverPrefix + vpnSourceID + "." + vpnDomain
        let localIdentifier = vpnCredentials.id
        let identityData = Data(base64Encoded: vpnCredentials.keyBase64)
        
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            let p = NEVPNProtocolIKEv2()
            
            p.serverAddress = serverAddress
            p.serverCertificateIssuerCommonName = vpnRemoteIdentifier
            p.remoteIdentifier = vpnRemoteIdentifier
            
            p.certificateType = NEVPNIKEv2CertificateType.ECDSA256
            p.authenticationMethod = NEVPNIKEAuthenticationMethod.certificate
            p.localIdentifier = localIdentifier
            p.useExtendedAuthentication = false
            p.disconnectOnSleep = false
            p.enablePFS = true
            
            p.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group19
            p.childSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM
            p.childSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA512
            p.childSecurityAssociationParameters.lifetimeMinutes = 1440
            
            p.ikeSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group19
            p.ikeSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM
            p.ikeSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA512
            p.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
            
            p.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.high
            p.identityData = identityData
            p.identityDataPassword = ""
            
            self.manager.protocolConfiguration = p
            self.manager.isEnabled = true
            self.manager.isOnDemandEnabled = true
            let connectRule = NEOnDemandRuleConnect()
            connectRule.interfaceTypeMatch = .any
            self.manager.onDemandRules = [connectRule]
            DDLogInfo("VPN status before loading: \(self.manager.connection.status)")
            self.manager.localizedDescription! = kVPNLocalizedDescription
            self.manager.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                if let e = error {
                    DDLogError("Saving VPN Error \(e)")
                    if ((e as NSError).code == 4) { // if config is stale, probably multithreading bug
                        DDLogInfo("Stale config, trying again")
                        self.setUpAndEnableVPN(completion: { error in
                            completion(error)
                        })
                    }
                    else {
                        completion(e)
                    }
                }
                else {
                    completion(nil)
                }
            })
        })
    }
    
}
