//
//  VPNController.swift
//  ConfirmediOS
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import CocoaLumberjackSwift

class VPNController: NSObject {
    
    static let shared = VPNController()
    
    private override init() {
        super.init()
        setupProtocols()
        NotificationCenter.default.addObserver(self, selector: #selector(vpnStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
     
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
        }
        NEVPNManager.shared().loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
        })
    }
    
    @objc func vpnStatusDidChange(_ notification: Notification) {
        if let object = notification.object as? NETunnelProviderSession {
            if object.manager.localizedDescription == IPSecV3.localizedName {
                ipsec.ipsecManager = object.manager
            }
            
            print("DescriptionTunnel \(object.manager.localizedDescription)")
        }
        else if let object = notification.object as? NEVPNConnection{
            if object.manager.localizedDescription == IPSecV3.localizedName {
                ipsec.ipsecManager = object.manager
            }
        }
        
        NotificationCenter.default.post(name: .vpnStatusChanged, object: notification.object)
    }
    
    //MARK: - PROXY METHODS
    /*
        * proxy is used for whitelisting
        * route traffic directly to site for approved domains
     */
    func setupWhitelistingProxy() {
        
        Utils.setupWhitelistedDefaults()
        let vpnManager = NEVPNManager.shared()
        vpnManager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in

            
            NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
                if let managers = managers {
                    let manager: NETunnelProviderManager
                    if managers.count > 0 {
                        manager = managers[0]
                    } else {
                        manager = NETunnelProviderManager()
                        manager.protocolConfiguration = NETunnelProviderProtocol()
                    }
                    
                    manager.localizedDescription = "Lockdown Tunnel"
                    manager.protocolConfiguration?.serverAddress = "Lockdown"
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
    
    /*
        * disable & re-enable proxy
        * primarily to reload whitelist rules
     */
    func toggleWhitelistingProxy() {
        disableWhitelistingProxy(proxyDisabledCallback: {(error) -> Void in
            self.setupWhitelistingProxy()
        })
    }
    
    /*
        * disable proxy
        * should be synchronized with VPN state
     */
    func disableWhitelistingProxy(proxyDisabledCallback: ((_ error: Error?) -> Void)? = nil) {
        currentProtocol?.disableWhitelistingProxy(completion: {error in
            proxyDisabledCallback?(error)
        })
        
    }
    
    //MARK: - VPN FUNCTIONS
    
    /*
        * only called internally
        * check for appropriate parameters and set up/install
        * enable on completion of setup
    */
    
    /*
        * master function for initiating VPN connections
     */
    func connectToVPN() {
        currentProtocol?.connectToVPN()
        
    }
    
    func disconnectFromVPN() {
        currentProtocol?.disconnectFromVPN()
    }
    
    func connectToLockdown() {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            VPNController.shared.setupWhitelistingProxy()
        })
    }
    
    func stopLockdown() {
        VPNController.shared.disableWhitelistingProxy()
    }
    
    /*
        * ensure the VPN & whitelisting proxy are in sync
        * proxy follows status of VPN
     */
    func syncVPNAndWhitelistingProxy() {
        return;
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if manager.connection.status == .connected || manager.connection.status == .connecting || manager.isOnDemandEnabled {
                VPNController.shared.setupWhitelistingProxy()
            }
            else {
                VPNController.shared.disableWhitelistingProxy()
            }
        })
    }
    
    func forceVPNOff() {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if !manager.isEnabled {
                return
            }
            DDLogInfo("Loading Error \(String(describing: error))")
            var p = NEVPNProtocolIKEv2()
            if let pc = manager.protocolConfiguration {
                p = pc as! NEVPNProtocolIKEv2
            }
            
            //null the address
            p.serverAddress = "local." + Global.vpnDomain
            p.serverCertificateIssuerCommonName = "local." + Global.vpnDomain
            p.remoteIdentifier = "local." + Global.vpnDomain
            
            p.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.high
           
            manager.protocolConfiguration = p
            manager.isOnDemandEnabled = false
            manager.isEnabled = false
            manager.localizedDescription! = Global.vpnName
            
            manager.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                if let e = error {
                    DDLogError("Error with saving config \(e)")
                }
            })
        })
        
        disableWhitelistingProxy()
    }
    
    func reloadWhitelistRules() {
        //currentProtocol?.disconnectFromVPN()
        DispatchQueue.main.async {
            //self.currentProtocol?.connectToVPN()
            self.toggleWhitelistingProxy()
        }
    }
    
    func setupProtocols() {
        availableProtocols.append(ipsec)
        
        updateProtocol()
    }
    
    func updateProtocol() {
        currentProtocol = ipsec
        
        currentProtocol?.endpointForRegion(region: Utils.getSavedRegion()) //calling this method will choose a new region if unsupported (rare)
    }
    
    func lockdownState(completion: @escaping (_ status: NEVPNStatus) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
            if let managers = managers {
                let manager: NETunnelProviderManager
                if managers.count > 0 {
                    manager = managers[0]
                } else {
                    manager = NETunnelProviderManager()
                    manager.protocolConfiguration = NETunnelProviderProtocol()
                }
                completion(manager.connection.status)
            }
            else {
                completion(.invalid)
            }
        }
    }
    
    func vpnState(completion: @escaping (_ status: NEVPNStatus) -> Void) -> Void {
        //NEED TO MAKE ASYNC OR HAVE WAY TO MAKE SURE THIS IS LOADED
        if currentProtocol == nil {
            setupProtocols()
        }
        
        if let proto = currentProtocol {
            proto.getStatus(completion: { status in
                completion(status)
            })
        }
        else {
            completion(.invalid)
        }
    }

    let ipsec = IPSecV3.init()
    
    var availableProtocols = [ConfirmedVPNProtocol]()
    var currentProtocol : ConfirmedVPNProtocol? = nil
    
}
