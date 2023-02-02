//
//  EnableVPNIntentHandler.swift
//  LockdownIntents
//
//  Created by Alexander Parshakov on 12/7/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Intents

final class EnableVPNIntentHandler: NSObject, EnableVPNIntentHandling {
    
    func resolve(intent: EnableVPNIntent, completion: @escaping (EnableVPNIntentResponse) -> Void) {
        completion(EnableVPNIntentResponse(code: .success, userActivity: nil))
    }
    
    func confirm(intent: EnableVPNIntent, completion: @escaping (EnableVPNIntentResponse) -> Void) {
        completion(EnableVPNIntentResponse(code: .ready, userActivity: nil))
    }
    
    func handle(intent: EnableVPNIntent, completion: @escaping (EnableVPNIntentResponse) -> Void) {
        if LatestKnowledge.isVPNEnabled {
            completion(EnableVPNIntentResponse(code: .failure, userActivity: nil))
        } else {
            BaseUserService.shared.updateUserSubscription { subscription in
                guard subscription?.hasVPN == true else {
                    completion(EnableVPNIntentResponse(code: .notVpnSubscriber, userActivity: nil))
                    return
                }
                
                VPNController.shared.setEnabled(true)
                
                // wait 0.5s
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // force a network check
                    reachability?.whenReachable = { _ in
                        // do nothing
                    }
                    // update Latest Knowledge
                    LatestKnowledge.isVPNEnabled = true
                    // send the success code
                    completion(EnableVPNIntentResponse(code: .success, userActivity: nil))
                }
            }
        }
    }
}

