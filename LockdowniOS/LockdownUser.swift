//
//  LockdownUser.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/2/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
//

final class LockdownUser {
    private(set) var currentSubscription: Subscription?
    
    func updateSubscription(to newSubscription: Subscription?) {
        currentSubscription = newSubscription
    }
}
