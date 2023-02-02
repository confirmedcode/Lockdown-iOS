//
//  IntentService.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/7/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import CocoaLumberjackSwift
import Intents

final class IntentService {
    
    static func donateIntents() {
        INPreferences.requestSiriAuthorization { status in
            switch status {
            case .authorized:
                DDLogInfo("User allowed access to Siri.")
                
                self.donateDisableVPNIntent()
                self.donateEnableVPNIntent()
            default:
                DDLogInfo("User denied access to Siri.")
            }
        }
    }
    
    private static func donateDisableVPNIntent() {
        let intent = DisableVPNIntent()
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate(completion: nil)
    }
    
    private static func donateEnableVPNIntent() {
        let intent = EnableVPNIntent()
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate(completion: nil)
    }
}
