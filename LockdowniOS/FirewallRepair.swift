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
                DDLogInfo("Always refresh the firewall to increase reliability - only happens every 3 hours")
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
                    completion(.repairAttempted)
                })
            }
            else {
                completion(.noAction)
            }
        })
    }
}
