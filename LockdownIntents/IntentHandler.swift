//
//  IntentHandler.swift
//  LockdownIntents
//
//  Created by Alexander Parshakov on 12/7/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Intents

final class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        if intent is EnableVPNIntent {
            return EnableVPNIntentHandler()
        } else if intent is DisableVPNIntent {
            return DisableVPNIntentHandler()
        } else {
            fatalError("Unknown intent type: \(intent)")
        }
    }
}
