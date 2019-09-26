//
//  FirewallController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed, Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import CocoaLumberjackSwift
import PromiseKit

let kFirewallTunnelLocalizedDescription = "Lockdown Configuration"

class FirewallController: NSObject {
    
    static let shared = FirewallController()
    
    var manager: NETunnelProviderManager?
    
    private override init() {
        super.init()
        refreshManager()
    }
    
    func refreshManager(completion: @escaping (_ error: Error?) -> Void = {_ in }) {
        // get the reference to the latest manager in Settings
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
            if let managers = managers, managers.count > 0 {
                if (self.manager == managers[0]) {
                    DDLogInfo("Encountered same manager while refreshing manager, not replacing it.")
                    completion(nil)
                }
                self.manager = nil
                self.manager = managers[0]
            }
            completion(error)
        }
    }
    
    func status() -> NEVPNStatus {
        if manager != nil {
            return manager!.connection.status
        }
        else {
            return .invalid
        }
    }

    func restart(completion: @escaping (_ error: Error?) -> Void = {_ in }) {
        // Don't let this affect userWantsFirewallOn/Off config
        FirewallController.shared.setEnabled(false, completion: {
            error in
            // TODO: Handle the error (throw?)
            if error != nil {
                DDLogError("Error disabling on Firewall restart: \(error!)")
            }
            FirewallController.shared.setEnabled(true, completion: {
                error in
                if error != nil {
                    DDLogError("Error enabling on Firewall restart: \(error!)")
                }
                completion(error)
            })
        })
    }
    
    func setEnabled(_ enabled: Bool, isUserExplicitToggle: Bool = false, completion: @escaping (_ error: Error?) -> Void = {_ in }) {
        DDLogInfo("FirewallController set enabled: \(enabled)")
        // only change this boolean if it's user action
        if (isUserExplicitToggle) {
            setUserWantsFirewallEnabled(enabled)
        }
        // just to be sure, reload the managers to make sure we don't make multiple configs
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
            if let managers = managers, managers.count > 0 {
                self.manager = nil
                self.manager = managers[0]
            }
            else {
                self.manager = nil
                self.manager = NETunnelProviderManager()
                self.manager!.protocolConfiguration = NETunnelProviderProtocol()
            }
            self.manager!.localizedDescription = kFirewallTunnelLocalizedDescription
            self.manager!.protocolConfiguration?.serverAddress = kFirewallTunnelLocalizedDescription
            self.manager!.isEnabled = enabled
            self.manager!.isOnDemandEnabled = enabled
            
            let connectRule = NEOnDemandRuleConnect()
            connectRule.interfaceTypeMatch = .any
            self.manager!.onDemandRules = [connectRule]
            self.manager!.saveToPreferences(completionHandler: { (error) -> Void in
                // TODO: Handle each case specifically
                if let e = error as? NEVPNError {
                    DDLogError("VPN Error while saving state: \(enabled) \(e)")
                    switch e.code {
                    case .configurationDisabled:
                        break;
                    case .configurationInvalid:
                        break;
                    case .configurationReadWriteFailed:
                        break;
                    case .configurationStale:
                        break;
                    case .configurationUnknown:
                        break;
                    case .connectionFailed:
                        break;
                    }
                }
                else if let e = error {
                    DDLogError("Error saving config for enabled state: \(enabled): \(e)")
                }
                else {
                    DDLogInfo("Successfully saved config for enabled state: \(enabled)")
                }
                self.refreshManager(completion: { error in
                    completion(nil)
                })
            })
        }
    }
    
}
