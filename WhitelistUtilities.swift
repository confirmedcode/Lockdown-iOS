//
//  WhitelistUtilities.swift
//  LockdowniOS
//
//  Created by Johnny Lin on 8/7/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import NetworkExtension

// MARK: - Constants

let kLockdownWhitelistedDomains = "whitelisted_domains"
let kUserWhitelistedDomains = "whitelisted_domains_user"

func getAllWhitelistedDomains() -> Array<String> {
    let lockdownWhitelistedDomains = getLockdownWhitelistedDomains()
    let userWhitelistedDomains = getUserWhitelistedDomains()
    
    var allWhitelistedDomains = Array<String>()
    
    for (key, value) in lockdownWhitelistedDomains {
        if (value as AnyObject).boolValue {
            allWhitelistedDomains.append(key)
        }
    }
    for (key, value) in userWhitelistedDomains {
        if (value as AnyObject).boolValue {
            allWhitelistedDomains.append(key)
        }
    }
    
    return allWhitelistedDomains
}

// MARK: - User blocked domains

func getUserWhitelistedDomains() -> Dictionary<String, Any> {
    if let domains = defaults.dictionary(forKey: kUserWhitelistedDomains) {
        return domains
    }
    return Dictionary()
}

func addUserWhitelistedDomain(domain: String) {
    var domains = getUserWhitelistedDomains()
    domains[domain] = NSNumber(value: true)
    defaults.set(domains, forKey: kUserWhitelistedDomains)
}

func setUserWhitelistedDomain(domain: String, enabled: Bool) {
    var domains = getUserWhitelistedDomains()
    domains[domain] = NSNumber(value: enabled)
    defaults.set(domains, forKey: kUserWhitelistedDomains)
}

func deleteUserWhitelistedDomain(domain: String) {
    var domains = getUserWhitelistedDomains()
    domains[domain] = nil
    defaults.set(domains, forKey: kUserWhitelistedDomains)
}

// MARK: - Lockdown whitelisted domains

func setupLockdownWhitelistedDomains() {
    addLockdownWhitelistedDomainIfNotExists(domain: "creditkarma.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hulu.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "netflix.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "api.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "m.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "mobile.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "houzz.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "icloud.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "skype.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "slickdeals.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "confirmedvpn.com")
}

func addLockdownWhitelistedDomainIfNotExists(domain: String) {
    // only add it if it doesn't exist, and add it as true
    var domains = getLockdownWhitelistedDomains()
    if domains[domain] == nil {
        domains[domain] = NSNumber(value: true)
    }
    defaults.set(domains, forKey: kLockdownWhitelistedDomains)
}

func getLockdownWhitelistedDomains() -> Dictionary<String, Any> {
    if let domains = defaults.dictionary(forKey: kLockdownWhitelistedDomains) {
        return domains;
    }
    return Dictionary()
}

func setLockdownWhitelistedDomain(domain: String, enabled: Bool) {
    var domains = getLockdownWhitelistedDomains()
    domains[domain] = NSNumber(value: enabled)
    defaults.set(domains, forKey: kLockdownWhitelistedDomains)
}
