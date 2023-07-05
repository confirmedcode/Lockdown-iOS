//
//  UserService.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
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
        firstly {
            signIn()
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
            // TODO: to change later when there will be data on the server
            completion(nil)
        }
    }
    
    private func signIn() -> Promise<()> {
        if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
            DDLogInfo("plan status: have confirmed API credentials, using them")
            return firstly {
                try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
            }
            .then { (signin: SignIn) -> Promise<SubscriptionEvent> in
                DDLogInfo("plan status: signin result: \(signin)")
                return try Client.subscriptionEvent()
            }
            .then { result in
                DDLogInfo("plan status: subscriptionevent result: \(result)")
                return Promise { seal in seal.fulfill(()) }
            }
        } else {
            return firstly {
                try Client.signIn()
            }.then { _ in
                Promise { seal in seal.fulfill(()) }
            }
        }
    }
}

