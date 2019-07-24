//
//  IPSecV3.swift
//  ConfirmediOS
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import CocoaLumberjackSwift

class IPSecV3: NSObject, ConfirmedVPNProtocol {
    static let protocolName: String = "IPSEC"
    static let localizedName: String = "Confirmed VPN"
    
    var supportedRegions: Array<ServerRegion> = [.usEast, .usWest, .canada, .euIreland, .euLondon, .euFrankfurt, .sydney, .tokyo, .singapore, .mumbai, .seoul, .brazil]
    
    func setupVPN(completion: @escaping (_ error: Error?) -> Void) {
        ipsecManager = NEVPNManager.shared()
        let savedRegion = Utils.getSavedRegion()
        let endpoint = endpointForRegion(region: savedRegion)
        let localId = Global.keychain[Global.kConfirmedID]
        let p12base64 = Global.keychain[Global.kConfirmedP12Key]
        
        if localId == nil || p12base64 == nil {
            completion(NSError.init(domain: "Lockdown VPN", code: 1, userInfo: nil))
            return
        }
        
        let p12Data = Data(base64Encoded: p12base64!)
            
        ipsecManager?.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            let p = NEVPNProtocolIKEv2()
            
            p.serverAddress = endpoint
            p.serverCertificateIssuerCommonName = Global.remoteIdentifier
            p.remoteIdentifier = Global.remoteIdentifier
            
            p.certificateType = NEVPNIKEv2CertificateType.ECDSA256
            p.authenticationMethod = NEVPNIKEAuthenticationMethod.certificate
            p.localIdentifier = localId
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
            p.identityData = p12Data
            p.identityDataPassword = Global.vpnPassword
            
            self.ipsecManager?.protocolConfiguration = p
            self.ipsecManager?.isOnDemandEnabled = true
            
            
            let connectRule = NEOnDemandRuleConnect()
            connectRule.interfaceTypeMatch = .any
            
            self.ipsecManager?.onDemandRules = [connectRule]
            DDLogInfo("VPN status:  \(self.ipsecManager?.connection.status)")
            self.ipsecManager?.localizedDescription! = Global.vpnName
            
            self.ipsecManager?.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                if let e = error {
                    DDLogError("Saving Error \(e)")
                    
                    if ((error! as NSError).code == 4) { //if config is stale, probably multithreading bug. Can this be fixed w/ a lock?
                        DDLogInfo("Trying again")
                        self.setupVPN(completion: { error in
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
    
    func endpointForRegion(region : ServerRegion) -> String {
        return "\(region.rawValue)\(Global.sourceID).\(Global.vpnDomain)"
    }
    
    func enableVPN() {
        
        ipsecManager?.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            self.ipsecManager?.isOnDemandEnabled = true
            self.ipsecManager?.isEnabled = true
            let connectRule = NEOnDemandRuleConnect()
            connectRule.interfaceTypeMatch = .any
            self.ipsecManager?.onDemandRules = [connectRule]
            
            self.ipsecManager?.protocolConfiguration?.disconnectOnSleep = false
            self.ipsecManager?.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                do {
                    DDLogInfo("Starting VPN")
                    try NEVPNManager.shared().connection.startVPNTunnel();
                }
                catch {
                    DDLogError("Failed to start vpn: \(error)")
                }
            })
        })
        
        setupWhitelistingProxy()
    }
    
    func connectToVPN() {
        setupVPN(completion: { error in
            if let e = error {
                Auth.getKey(callback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
                    if status {
                        self.setupVPN(completion: { error in
                            self.enableVPN()
                        })
                    }
                    else {
                        if errorCode == Global.kInternetDownError {
                            NotificationCenter.post(name: .internetDownNotification)
                        }
                    }
                })
            }
            else {
                self.enableVPN()
            }
        })
    }
    
    func disconnectFromVPNOnly() {
        self.ipsecManager?.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            NEVPNManager.shared().isOnDemandEnabled = false
            self.ipsecManager?.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                do {
                    self.ipsecManager?.connection.stopVPNTunnel();
                }
            })
        })
    }
    
    func disconnectFromVPN() {
        disconnectFromVPNOnly()
        disableWhitelistingProxy(completion: {error in})
    }
    
    /*
     * disable proxy
     * should be synchronized with VPN state
     */
    func disableWhitelistingProxy(completion: @escaping (_ error: Error?) -> Void) {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            
            NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
                if let managers = managers {
                    let manager: NETunnelProviderManager
                    if managers.count > 0 {
                        manager = managers[0]
                    }else{
                        manager = NETunnelProviderManager()
                        manager.protocolConfiguration = NETunnelProviderProtocol()
                    }
                    
                    manager.isEnabled = false
                    manager.isOnDemandEnabled = false
                    let connectRule = NEOnDemandRuleConnect()
                    connectRule.interfaceTypeMatch = .any
                    manager.onDemandRules = [connectRule]
                    manager.saveToPreferences(completionHandler: { (error) -> Void in
                        completion(error)
                    })
                }else{
                    completion(error)
                }
            }
        })
        
    }

    func setupWhitelistingProxy() {
        
        Utils.setupWhitelistedDefaults()
        let vpnManager = NEVPNManager.shared()
        vpnManager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if !vpnManager.isEnabled {
                return
            }
            
            NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
                if let managers = managers {
                    let manager: NETunnelProviderManager
                    if managers.count > 0 {
                        manager = managers[0]
                    } else {
                        manager = NETunnelProviderManager()
                        manager.protocolConfiguration = NETunnelProviderProtocol()
                    }
                    
                    manager.localizedDescription = "Lockdown VPN Configuration"
                    manager.protocolConfiguration?.serverAddress = IPSecV3.localizedName
                    manager.isEnabled = true
                    manager.isOnDemandEnabled = true
                    
                    let connectRule = NEOnDemandRuleConnect()
                    connectRule.interfaceTypeMatch = .any
                    manager.onDemandRules = [connectRule]
                    manager.saveToPreferences(completionHandler: { (error) -> Void in
                        
                    })
                }else{
                    
                }
            }
        })
    }
    
    func getStatus(completion: @escaping (_ status: NEVPNStatus) -> Void) -> Void {
        if self.ipsecManager == nil {
            completion(.invalid)
        }
        else {
            self.ipsecManager?.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
                completion(self.ipsecManager?.connection.status ?? .invalid)
            })
        }
    }
    
    var ipsecManager: NEVPNManager?

}
