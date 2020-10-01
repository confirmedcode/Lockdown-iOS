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
    addLockdownWhitelistedDomainIfNotExists(domain: "amazon.com") // This domain is not used for tracking (the tracker amazon-adsystem.com is blocked), but it does sometimes stop Secure Tunnel VPN users from viewing Amazon reviews. Users may un-whitelist this if they wish.
    addLockdownWhitelistedDomainIfNotExists(domain: "api.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple.news")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple-cloudkit.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "archive.is")
    addLockdownWhitelistedDomainIfNotExists(domain: "bamgrid.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "cdn-apple.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "coinbase.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "confirmedvpn.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "creditkarma.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "digicert.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "disney-plus.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "disneyplus.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "firstdata.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "go.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hbc.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hbo.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hbomax.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "houzz.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hulu.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "huluim.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "icloud-content.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "icloud.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "kroger.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "letsencrypt.org")
    addLockdownWhitelistedDomainIfNotExists(domain: "lowes.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "m.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "marcopolo.me")
    addLockdownWhitelistedDomainIfNotExists(domain: "mobile.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "mzstatic.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "netflix.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "nflxvideo.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "quibi.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "saks.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "saksfifthavenue.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "skype.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "slickdeals.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "southwest.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "spotify.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "t.co")
    addLockdownWhitelistedDomainIfNotExists(domain: "tapbots.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "tapbots.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "teslamotors.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "twimg.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "usbank.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "verisign.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "vudu.com")
    
    setAsFalseLockdownWhitelistedDomain(domain: "nianticlabs.com")
}

func addLockdownWhitelistedDomainIfNotExists(domain: String) {
    // only add it if it doesn't exist, and add it as true
    var domains = getLockdownWhitelistedDomains()
    if domains[domain] == nil {
        domains[domain] = NSNumber(value: true)
    }
    defaults.set(domains, forKey: kLockdownWhitelistedDomains)
}

func setAsFalseLockdownWhitelistedDomain(domain: String) {
    var domains = getLockdownWhitelistedDomains()
    domains[domain] = NSNumber(value: false)
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
