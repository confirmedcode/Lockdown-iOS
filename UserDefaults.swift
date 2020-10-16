//
//  UserDefaults.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 28.09.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation

let defaults = UserDefaults(suiteName: "group.com.confirmed")!

let kUserWantsFirewallEnabled = "user_wants_firewall_enabled"
let kUserWantsVPNEnabled = "user_wants_vpn_enabled"

enum LatestKnowledge {
    
    private static let kLatestKnowledgeIsFirewallEnabled = "kLatestKnowledgeIsFirewallEnabled"
    private static let kLatestKnowledgeIsVPNEnabled = "kLatestKnowledgeIsVPNEnabled"
    
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

enum PacketTunnelProviderLogs {
    
    static let dateFormatter: DateFormatter = {
        $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
        $0.formatterBehavior = .behavior10_4
        $0.locale = .init(identifier: "en_US_POSIX")
        return $0
    }(DateFormatter())
    
    static let userDefaultsKey = "com.confirmed.lockdown.ne_temporaryLogs"
    
    static func log(_ string: String) {
        let string = "\(dateFormatter.string(from: Date())) \(string)"
        if var array = defaults.stringArray(forKey: userDefaultsKey) {
            array.append(string)
            defaults.setValue(array, forKey: userDefaultsKey)
        } else {
            defaults.setValue([string], forKey: userDefaultsKey)
        }
    }
    
    static var allEntries: [String] {
        return defaults.stringArray(forKey: userDefaultsKey) ?? []
    }
    
    static func clear() {
        defaults.setValue(Array<String>(), forKey: userDefaultsKey)
    }
}
