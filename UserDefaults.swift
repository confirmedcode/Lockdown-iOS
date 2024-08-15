//
//  UserDefaults.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 28.09.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation

let defaults = UserDefaults(suiteName: "group.com.confirmed")!

enum LatestKnowledge {
    
    static var isFirewallEnabled: Bool {
        get {
            return defaults.bool(forKey: kLatestKnowledgeIsFirewallEnabled)
        }
        set {
            defaults.setValue(newValue, forKey: kLatestKnowledgeIsFirewallEnabled)
        }
    }
    
    static var isVPNEnabled: Bool {
        get {
            return defaults.bool(forKey: kLatestKnowledgeIsVPNEnabled)
        }
        set {
            defaults.setValue(newValue, forKey: kLatestKnowledgeIsVPNEnabled)
        }
    }
}

func setUserWantsFirewallEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: kUserWantsFirewallEnabled)
}

func getUserWantsFirewallEnabled() -> Bool {
    return defaults.bool(forKey: kUserWantsFirewallEnabled)
}

func setUserWantsVPNEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: kUserWantsVPNEnabled)
}

func getUserWantsVPNEnabled() -> Bool {
    return defaults.bool(forKey: kUserWantsVPNEnabled)
}
