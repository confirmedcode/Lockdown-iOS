//
//  DisableVPNIntentHandler.swift
//  LockdownIntents
//
//  Created by Alexander Parshakov on 12/7/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Intents

final class DisableVPNIntentHandler: NSObject, DisableVPNIntentHandling {
    
    func resolve(intent: DisableVPNIntent, completion: @escaping (DisableVPNIntentResponse) -> Void) {
        completion(DisableVPNIntentResponse(code: .success, userActivity: nil))
    }
    
    func confirm(intent: DisableVPNIntent, completion: @escaping (DisableVPNIntentResponse) -> Void) {
        completion(DisableVPNIntentResponse(code: .ready, userActivity: nil))
    }
    
    func handle(intent: DisableVPNIntent, completion: @escaping (DisableVPNIntentResponse) -> Void) {
        // if the VPN is enabled, disable it, send the success code, and update LatestKnowledge
        if LatestKnowledge.isVPNEnabled {
            VPNController.shared.setEnabled(false)
            completion(DisableVPNIntentResponse(code: .success, userActivity: nil))
            LatestKnowledge.isVPNEnabled = false
        } else {
            // otherwise, send the failure code because VPN doesn't need to be disabled
            // using the failure response code below sends the predefined response
            completion(DisableVPNIntentResponse(code: .failure, userActivity: nil))
        }
    }
}
