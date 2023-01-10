//
//  UserService.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/2/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
//

import CocoaLumberjackSwift
import PromiseKit

protocol UserService: AnyObject {
    var user: LockdownUser { get }
    
    func updateUserSubscription(completion: @escaping (Subscription?) -> Void)
}

final class BaseUserService: UserService {
    
    static let shared: UserService = BaseUserService()
    
    var user = LockdownUser()
    
    func updateUserSubscription(completion: @escaping (Subscription?) -> Void) {
        if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
            DDLogInfo("plan status: have confirmed API credentials, using them")
            firstly {
                try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
            }
            .then { (signin: SignIn) -> Promise<SubscriptionEvent> in
                DDLogInfo("plan status: signin result: \(signin)")
                return try Client.subscriptionEvent()
            }
            .then { (result: SubscriptionEvent) -> Promise<[Subscription]> in
                DDLogInfo("plan status: subscriptionevent result: \(result)")
                return try Client.activeSubscriptions()
            }.done { subscriptions in
                DDLogInfo("active-subs: \(subscriptions)")
                NotificationCenter.default.post(name: AccountUI.accountStateDidChange, object: self)
                
                self.user.updateSubscription(to: subscriptions.first)
                completion(subscriptions.first)
            }
            .catch { error in
                if let apiError = error as? ApiError {
                    DDLogError("Error loading plan: API error code - \(apiError.code)")
                } else {
                    DDLogError("Error loading plan: Non-API Error - \(error.localizedDescription)")
                }
                self.user.updateSubscription(to: nil)
                completion(nil)
            }
        } else {
            firstly {
                try Client.signIn()
            }.then { _ in
                try Client.activeSubscriptions()
            }.done { subscriptions in
                DDLogInfo("active-subs: \(subscriptions)")
                NotificationCenter.default.post(name: AccountUI.accountStateDidChange, object: self)
                
                self.user.updateSubscription(to: subscriptions.first)
                completion(subscriptions.first)
            }.catch { error in
                DDLogError("Error reloading subscription: \(error.localizedDescription)")
                if let apiError = error as? ApiError {
                    DDLogError("Error loading plan: API error code - \(apiError.code)")
                } else {
                    DDLogError("Error loading plan: Non-API Error - \(error.localizedDescription)")
                }
                self.user.updateSubscription(to: nil)
                completion(nil)
            }
        }
    }
}
