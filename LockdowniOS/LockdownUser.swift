//
//  LockdownUser.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import Foundation

final class LockdownUser {
    private(set) var currentSubscription: Subscription?
    
    @CodableUserDefaults(key: "cahedUsedSubscription")
    private var cachedUserSubscription: Subscription?
    
    private let graceTimeInterval = TimeInterval(7 * 24 * 60 * 60) // 7 days
    
    func updateSubscription(to newSubscription: Subscription?) {
        currentSubscription = newSubscription
        updateCachedSubscription(to: newSubscription)
    }
    
    private func updateCachedSubscription(to newSubscription: Subscription?) {
        guard let newSubscription else {
            return
        }
        
        cachedUserSubscription = newSubscription
    }
    
    func cachedSubscription() -> Subscription? {
        guard let subscription = cachedUserSubscription else {
            return nil
        }
        
        guard subscription.expirationDate.addingTimeInterval(graceTimeInterval) > Date() else {
            cachedUserSubscription = nil
            return nil
        }
        return subscription
    }
    
    func resetCache() {
        cachedUserSubscription = nil
    }
}
