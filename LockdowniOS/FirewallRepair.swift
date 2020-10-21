//
//  FirewallRepair.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 21.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift

enum FirewallRepair {
    
    enum Result {
        case repairAttempted
        case failed(Swift.Error?)
        case noAction
    }
    
    enum Context: CustomDebugStringConvertible {
        case backgroundRefresh
        case homeScreenDidLoad
        
        var debugDescription: String {
            switch self {
            case .backgroundRefresh:
                return "Background Check"
            case .homeScreenDidLoad:
                return "Home"
            }
        }
    }
    
    static func run(context: Context, completion: @escaping (FirewallRepair.Result) -> Void = { _ in }) {
        // Check 2 conditions for firewall restart, but reload manager first to get non-stale one
        FirewallController.shared.refreshManager(completion: { error in
            if let e = error {
                DDLogError("Error refreshing Manager in \(context): \(e)")
                completion(.failed(e))
                return
            }
            if getUserWantsFirewallEnabled() && (FirewallController.shared.status() == .connected || FirewallController.shared.status() == .invalid) {
                DDLogInfo("user wants firewall enabled and connected/invalid, testing blocking in \(context)")
                // 1) if app has just been upgraded or is new install
                if (appHasJustBeenUpgradedOrIsNewInstall()) {
                    DDLogInfo("\(context.debugDescription.uppercased()): APP UPGRADED, REFRESHING DEFAULT BLOCK LISTS, WHITELISTS, RESTARTING FIREWALL")
                    setupFirewallDefaultBlockLists()
                    setupLockdownWhitelistedDomains()
                    FirewallController.shared.restart(completion: {
                        error in
                        if error != nil {
                            DDLogError("Error restarting firewall on \(context) App Upgraded Check: \(error!)")
                        }
                        completion(.repairAttempted)
                    })
                }
                // 2) Check that Firewall is still working correctly, restart it if it's not
                else {
                    Client.getBlockedDomainTest().done {
                        DDLogError("\(context) Fetch Test: Connected to \(testFirewallDomain) even though it's supposed to be blocked, restart the Firewall")
                        FirewallController.shared.restart(completion: {
                            error in
                            if error != nil {
                                DDLogError("Error restarting firewall on \(context): \(error!)")
                            }
                            completion(.repairAttempted)
                        })
                    }.catch { error in
                        let nsError = error as NSError
                        if nsError.domain == NSURLErrorDomain {
                            DDLogInfo("\(context) Fetch Test: Successful blocking of \(testFirewallDomain) with NSURLErrorDomain error: \(nsError)")
                        }
                        else {
                            DDLogInfo("\(context) Fetch Test: Successful blocking of \(testFirewallDomain), but seeing non-NSURLErrorDomain error: \(error)")
                        }
                        completion(.noAction)
                    }
                }
            }
            else {
                completion(.noAction)
            }
        })
    }
}
