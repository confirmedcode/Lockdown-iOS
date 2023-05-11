//
//  LockdownUser.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

final class LockdownUser {
    private(set) var currentSubscription: Subscription?
    
    func updateSubscription(to newSubscription: Subscription?) {
        currentSubscription = newSubscription
    }
}
