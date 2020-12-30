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
        DDLogInfo("Repair: Starting")
        // Check 2 conditions for firewall restart, but reload manager first to get non-stale one
        FirewallController.shared.refreshManager(completion: { error in
            if let e = error {
                DDLogError("Error refreshing Manager in \(context): \(e)")
                completion(.failed(e))
                return
            }
            DDLogInfo("Repair: refreshed manager")
            DDLogInfo("Repair: userWantsFirewallEnabled \(getUserWantsFirewallEnabled())")
            DDLogInfo("Repair: firewallStatus \(FirewallController.shared.status())")
            if getUserWantsFirewallEnabled() && (FirewallController.shared.status() == .connected || FirewallController.shared.status() == .invalid) {
                DDLogInfo("Firewall repair: user wants enabled")
                if (context == .homeScreenDidLoad) {
                    DDLogInfo("Home screen context - only reload if new version")
                    if (appHasJustBeenUpgradedOrIsNewInstall()) {
                        DDLogInfo("\(context.debugDescription.uppercased()): APP UPGRADED, REFRESHING DEFAULT BLOCK LISTS, WHITELISTS, RESTARTING FIREWALL")
                        setupFirewallDefaultBlockLists()
                        setupLockdownWhitelistedDomains()
                        FirewallController.shared.restart(completion: {
                            error in
                            if error != nil {
                                DDLogError("Error restarting firewall on \(context): \(error!)")
                            }
                            completion(.repairAttempted)
                        })
                    }
                }
                else if (context == .backgroundRefresh) {
                    DDLogInfo("Background context: Always refresh the firewall to increase reliability - only happens every 3 hours")
                    if (appHasJustBeenUpgradedOrIsNewInstall()) {
                        DDLogInfo("\(context.debugDescription.uppercased()): APP UPGRADED, REFRESHING DEFAULT BLOCK LISTS, WHITELISTS, RESTARTING FIREWALL")
                        setupFirewallDefaultBlockLists()
                        setupLockdownWhitelistedDomains()
                    }
                    FirewallController.shared.restart(completion: {
                        error in
                        if error != nil {
                            DDLogError("Error restarting firewall on \(context): \(error!)")
                        }
                        DDLogInfo("Repair: restart complete, testing to see if it worked")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            Client.getBlockedDomainTest().done {
                                DDLogError("Repair Fetch Test Failed: Connected to \(testFirewallDomain) even though it's supposed to be blocked")
                                completion(.repairAttempted)
                            }.catch { error in
                                let nsError = error as NSError
                                if nsError.domain == NSURLErrorDomain {
                                    DDLogInfo("Repair Fetch Test Success: Successful blocking of \(testFirewallDomain) with NSURLErrorDomain error: \(nsError)")
                                }
                                else {
                                    DDLogInfo("Repair Fetch Test Success: Successful blocking of \(testFirewallDomain), but seeing non-NSURLErrorDomain error: \(error)")
                                }
                                completion(.repairAttempted)
                            }
                        }
                    })
                }
            }
            else {
                completion(.noAction)
            }
        })
    }
}
