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
    addLockdownWhitelistedDomainIfNotExists(domain: "3stripes.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "aiv-cdn.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "akamaihd.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "akamaized.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "ally.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "amazon.com") // This domain is not used for tracking (the tracker amazon-adsystem.com is blocked), but it does sometimes stop Secure Tunnel VPN users from viewing Amazon reviews. Users may un-whitelist this if they wish.
    addLockdownWhitelistedDomainIfNotExists(domain: "americanexpress.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "api.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple-cloudkit.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple.news")
    addLockdownWhitelistedDomainIfNotExists(domain: "archive.is")
    addLockdownWhitelistedDomainIfNotExists(domain: "att.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "att.com.edgesuite.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "att.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "bamgrid.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "bestbuy.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "bitwarden.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "brightcove.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "cbs.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "cbsaavideo.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "cbsi.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "cbsi.video")
    addLockdownWhitelistedDomainIfNotExists(domain: "cbsnews.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "cdn-apple.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "chase.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "citi.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "cloudfront.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "coinbase.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "comcast.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "confirmedvpn.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "creditkarma.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "cwtv.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "digicert.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "disney-plus.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "disneyplus.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "ebtedge.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "espn.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "fastly.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "fastly.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "firstdata.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "fubo.tv")
    addLockdownWhitelistedDomainIfNotExists(domain: "gamestop.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "go.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "googlevideo.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "grindr.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hbc.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hbo.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hbomax.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hotstar.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "houzz.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hopper.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hulu.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "huluim.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "icloud-content.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "icloud.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "kroger.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "letsencrypt.org")
    addLockdownWhitelistedDomainIfNotExists(domain: "livenation.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "lowes.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "lync.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "m.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "marcopolo.me")
    addLockdownWhitelistedDomainIfNotExists(domain: "mastercard.ca")
    addLockdownWhitelistedDomainIfNotExists(domain: "mastercard.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "mastercard.us")
    addLockdownWhitelistedDomainIfNotExists(domain: "mbanking-services.mobi")
    addLockdownWhitelistedDomainIfNotExists(domain: "me.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "meijer.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "microsoft.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "microsoftonline.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "mobile.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "movetv.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "mzstatic.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "nba.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "nbcuni.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "netflix.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "neulion.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "nflxvideo.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "nike.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "office.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "office.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "office365.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "opentable.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "outlook.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "peacocktv.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "personalcapital.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "philo.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "quibi.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "quickplay.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "researchgate.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "saks.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "saksfifthavenue.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "scholar.google.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "skype.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "skypeforbusiness.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "slickdeals.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "sling.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "southwest.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "spotify.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "stan.com.au")
    addLockdownWhitelistedDomainIfNotExists(domain: "stan.video")
    addLockdownWhitelistedDomainIfNotExists(domain: "stripe.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "syncbak.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "t.co")
    addLockdownWhitelistedDomainIfNotExists(domain: "tapbots.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "tapbots.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "telegram.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "teslamotors.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "ticketmaster.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "ttvnw.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "twimg.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "uplynk.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "usbank.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "verisign.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "visa.ca")
    addLockdownWhitelistedDomainIfNotExists(domain: "visa.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "vudu.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "xfinity.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "youtube.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "zoom.us")
    
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
