//
//  FirewallUtilities.swift
//  LockdowniOS
//
//  Created by Johnny Lin on 8/4/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import NetworkExtension
import WidgetKit

// MARK: - Constants

let kLockdownBlockedDomains = "lockdown_domains"
let kUserBlockedDomains = "lockdown_domains_user"

// MARK: - data structures

struct ConfirmedIPRange : Codable {
    var subnetMask : String
    var enabled : Bool
    var IPv6 : Bool
    var subnetBits : Int
}

struct LockdownGroup : Codable {
    //format of a lockdown default
    //key: name
    //value: dictionary { iconUrl: String, enabled : Boolean, domains : [String : Enabled], IPRange: [IPAddress : [subnet : String, enabled : Boolean]}
    var version : Int
    var internalID: String
    var name: String
    var iconURL : String
    var enabled : Bool
    var domains : Dictionary<String, Bool>
    var ipRanges : Dictionary<String, ConfirmedIPRange>
    var warning: String?
}

struct LockdownDefaults : Codable {
    var lockdownDefaults : Dictionary<String, LockdownGroup>
}

// MARK: - Block Metrics & Block Log

let currentCalendar = Calendar.current
let blockLogDateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a_"
    return formatter
}()

enum MetricsUpdate {
    
    enum Mode {
        case incrementAndLog(host: String)
        case resetIfNeeded
        
        var incrementBy: Int {
            switch self {
            case .incrementAndLog:
                return 1
            case .resetIfNeeded:
                return 0
            }
        }
    }
    
    enum RescheduleNotifications {
        case always
        case never
        case withEnergySaving
        
        var allowsScheduling: Bool {
            switch self {
            case .always, .withEnergySaving:
                return true
            case .never:
                return false
            }
        }
    }
}

func updateMetrics(_ mode: MetricsUpdate.Mode, rescheduleNotifications: MetricsUpdate.RescheduleNotifications) {
    
    let date = Date()
    
    // TOTAL - increment total
    let totalMetrics = getTotalMetrics()
    let updatedTotal = totalMetrics + mode.incrementBy
    
    defaults.set(updatedTotal, forKey: kTotalMetrics)
    
    if (100 ... 200) ~= updatedTotal, rescheduleNotifications.allowsScheduling {
        OneTimeActions.performOnce(ifHasNotSeen: .oneHundredTrackingAttemptsBlockedNotification) {
            PushNotifications.shared.scheduleOnboardingNotification(
                options: rescheduleNotifications == .withEnergySaving ? [.energySaving] : []
            )
        }
    }
    
    // WEEKLY - reset metrics on new week and increment week
    let currentWeek = currentCalendar.component(.weekOfYear, from: date)
    if currentWeek != defaults.integer(forKey: kActiveWeek) {
        defaults.set(0, forKey: kWeekMetrics)
        defaults.set(currentWeek, forKey: kActiveWeek)
    }
    let weekMetrics = getWeekMetrics()
    defaults.set(Int(weekMetrics + mode.incrementBy), forKey: kWeekMetrics)
    
    // DAY - reset metric on new day and increment day and log
    // set day metric
    let currentDay = currentCalendar.component(.day, from: date)
    if currentDay != defaults.integer(forKey: kActiveDay) {
        defaults.set(0, forKey: kDayMetrics)
        defaults.set(currentDay, forKey: kActiveDay)
        BlockDayLog.shared.clear()
    }
    defaults.set(Int(getDayMetrics() + mode.incrementBy), forKey: kDayMetrics)
    
    if #available(iOSApplicationExtension 14.0, iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    switch mode {
    case .incrementAndLog(host: let host):
        guard BlockDayLog.shared.isDisabled == false else {
            // block log disabled
            break
        }
        
        // set log
        BlockDayLog.shared.append(host: host, date: date)
    case .resetIfNeeded:
        // no-act
        break
    }
    
    switch rescheduleNotifications {
    case .always:
        PushNotifications.shared.rescheduleWeeklyUpdate(options: [])
    case .withEnergySaving:
        PushNotifications.shared.rescheduleWeeklyUpdate(options: [.energySaving])
    case .never:
        // no-act
        break
    }
}

// MARK: - Blocked domains and lists

func setupFirewallDefaultBlockLists() {
    var lockdownBlockedDomains = getLockdownBlockedDomains()
    
    let snapchatAnalytics = LockdownGroup.init(
        version: 27,
        internalID: "snapchatAnalytics",
        name: NSLocalizedString("Snapchat Trackers", comment: "The title of a list of trackers"),
        iconURL: "snapchat_analytics_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "snapchat_analytics"),
        ipRanges: [:])
    
    let gameAds = LockdownGroup.init(
        version: 30,
        internalID: "gameAds",
        name: NSLocalizedString("Game Marketing", comment: "The title of a list of trackers"),
        iconURL: "game_ads_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "game_ads"),
        ipRanges: [:])
    
    let clickbait = LockdownGroup.init(
        version: 29,
        internalID: "clickbait",
        name: NSLocalizedString("Clickbait", comment: "The title of a list of trackers"),
        iconURL: "clickbait_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "clickbait"),
        ipRanges: [:])
    
    let crypto = LockdownGroup.init(
        version: 29,
        internalID: "crypto_mining",
        name: NSLocalizedString("Crypto Mining", comment: "The title of a list of trackers"),
        iconURL: "crypto_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "crypto_mining"),
        ipRanges: [:],
        warning: "This block list is currently under maintenance and will be updated soon.")
    
    let emailOpens = LockdownGroup.init(
        version: 30,
        internalID: "email_opens",
        name: NSLocalizedString("Email Trackers", comment: "The title of a list of trackers"),
        iconURL: "email_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "email_opens"),
        ipRanges: [:])
    
    let facebookInc = LockdownGroup.init(
        version: 33,
        internalID: "facebook_inc",
        name: NSLocalizedString("Facebook & WhatsApp", comment: "The title of a list of trackers"),
        iconURL: "facebook_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "facebook_inc"),
        ipRanges: [:],
        warning: "This list is intended to completely block Facebook-owned apps. Do not enable it if you use apps owned by Facebook like WhatsApp, Facebook Messenger, and Instagram.")
    
    let facebookSDK = LockdownGroup.init(
        version: 28,
        internalID: "facebook_sdk",
        name: NSLocalizedString("Facebook Trackers", comment: "The title of a list of trackers"),
        iconURL: "facebook_white_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "facebook_sdk"),
        ipRanges: [:])
    
    let marketingScripts = LockdownGroup.init(
        version: 31,
        internalID: "marketing_scripts",
        name: NSLocalizedString("Marketing Trackers", comment: "The title of a list of trackers"),
        iconURL: "marketing_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "marketing"),
        ipRanges: [:])
    
    let marketingScriptsII = LockdownGroup.init(
        version: 30,
        internalID: "marketing_beta_scripts",
        name: NSLocalizedString("Marketing Trackers II", comment: "The title of a list of trackers"),
        iconURL: "marketing_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "marketing_beta"),
        ipRanges: [:])

    let ransomware = LockdownGroup.init(
        version: 29,
        internalID: "ransomware",
        name: NSLocalizedString("Ransomware", comment: "The title of a list of trackers"),
        iconURL: "ransomware_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "ransomware"),
        ipRanges: [:],
        warning: "This block list is currently under maintenance and will be updated soon.")

    let googleShoppingAds = LockdownGroup.init(
        version: 35,
        internalID: "google_shopping_ads",
        name: NSLocalizedString("Google Shopping", comment: "The title of a list of trackers"),
        iconURL: "google_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "google_shopping_ads"),
        ipRanges: [:],
        warning: "This blocks background Google tracking, but also blocks the shopping results at the top of Google search results. This is on by default for maximum privacy, but if you like the Google Shopping results, you can turn blocking off.")
    
    let dataTrackers = LockdownGroup.init(
        version: 35,
        internalID: "data_trackers",
        name: NSLocalizedString("Data Trackers", comment: "The title of a list of trackers"),
        iconURL: "user_data_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "data_trackers"),
        ipRanges: [:])
    
    let generalAds = LockdownGroup.init(
        version: 40,
        internalID: "general_ads",
        name: NSLocalizedString("General Marketing", comment: "The title of a list of trackers"),
        iconURL: "ads_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "general_ads"),
        ipRanges: [:])
    
    let reporting = LockdownGroup.init(
        version: 29,
        internalID: "reporting",
        name: NSLocalizedString("Reporting", comment: "The title of a list of trackers"),
        iconURL: "reporting_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "reporting"),
        ipRanges: [:])
    
    let amazonTrackers = LockdownGroup.init(
        version: 32,
        internalID: "amazon_trackers",
        name: NSLocalizedString("Amazon Trackers", comment: "The title of a list of trackers"),
        iconURL: "amazon_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "amazon_trackers"),
        ipRanges: [:],
        warning: "This blocks Amazon referral link tracking too, so enabling this list may cause errors when clicking certain links on Amazon.")
    
    let defaultLockdownSettings = [snapchatAnalytics,
                                   gameAds,
                                   clickbait,
                                   crypto,
                                   emailOpens,
                                   facebookInc,
                                   facebookSDK,
                                   marketingScripts,
                                   marketingScriptsII,
                                   ransomware,
                                   googleShoppingAds,
                                   dataTrackers,
                                   generalAds,
                                   reporting,
                                   amazonTrackers];
    
    for var defaultGroup in defaultLockdownSettings {
        if let current = lockdownBlockedDomains.lockdownDefaults[defaultGroup.internalID], current.version >= defaultGroup.version {
            // no version change, no action needed
        } else {
            if let current = lockdownBlockedDomains.lockdownDefaults[defaultGroup.internalID] {
                defaultGroup.enabled = current.enabled // don't replace whether it was disabled
            }
            lockdownBlockedDomains.lockdownDefaults[defaultGroup.internalID] = defaultGroup
        }
    }
    
    for (_, value) in lockdownBlockedDomains.lockdownDefaults {
        if lockdownBlockedDomains.lockdownDefaults[value.name] != nil {
            lockdownBlockedDomains.lockdownDefaults.removeValue(forKey: value.name)
        }
    }
    
    defaults.set(try? PropertyListEncoder().encode(lockdownBlockedDomains), forKey: kLockdownBlockedDomains)
}

func getDomainBlockList(filename: String) -> Dictionary<String, Bool> {
    var domains = [String : Bool]()
    guard let path = Bundle.main.path(forResource: filename, ofType: "txt") else {
        return domains
    }
    do {
        let content = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
        let lines = content.components(separatedBy: "\n")
        for line in lines {
            if (line.trimmingCharacters(in: CharacterSet.whitespaces) != "" && !line.starts(with: "#")) {
                domains[line] = true;
            }
        }
    } catch _ as NSError {
    }
    return domains
}

func getAllBlockedDomains() -> Array<String> {
    let lockdownBlockedDomains = getLockdownBlockedDomains()
    let userBlockedDomains = getUserBlockedDomains()
    
    var allBlockedDomains = Array<String>()
    for (_, ldValue) in lockdownBlockedDomains.lockdownDefaults {
        if ldValue.enabled {
            for (key, value) in ldValue.domains {
                if value {
                    allBlockedDomains.append(key)
                }
            }
        }
    }
    for (key, value) in userBlockedDomains {
        if (value as AnyObject).boolValue {
            allBlockedDomains.append(key)
        }
    }
    
    return allBlockedDomains
}

func getIsCombinedBlockListEmpty() -> Bool {
    return (getAllBlockedDomains() + getAllWhitelistedDomains()).isEmpty
}

// MARK: - User blocked domains

func getUserBlockedDomains() -> Dictionary<String, Any> {
    if let domains = defaults.dictionary(forKey: kUserBlockedDomains) {
        return domains
    }
    return Dictionary()
}

func addUserBlockedDomain(domain: String) {
    var domains = getUserBlockedDomains()
    domains[domain] = NSNumber(value: true)
    defaults.set(domains, forKey: kUserBlockedDomains)
}

func setUserBlockedDomain(domain: String, enabled: Bool) {
    var domains = getUserBlockedDomains()
    domains[domain] = NSNumber(value: enabled)
    defaults.set(domains, forKey: kUserBlockedDomains)
}

func deleteUserBlockedDomain(domain: String) {
    var domains = getUserBlockedDomains()
    domains[domain] = nil
    defaults.set(domains, forKey: kUserBlockedDomains)
}

// MARK: - Lockdown blocked domains

func getLockdownBlockedDomains() -> LockdownDefaults {
    guard let lockdownDefaultsData = defaults.object(forKey: kLockdownBlockedDomains) as? Data else {
        return LockdownDefaults(lockdownDefaults: [:])
    }
    guard let lockdownDefaults = try? PropertyListDecoder().decode(LockdownDefaults.self, from: lockdownDefaultsData) else {
        return LockdownDefaults(lockdownDefaults: [:])
    }
    return lockdownDefaults
}

// MARK: - Unused
//
//func getBlockedIPv4List(filename: String) -> Dictionary<String, IPRange> {
//    var domains = [String : IPRange]()
//    guard let path = Bundle.main.path(forResource: filename, ofType: "txt") else {
//        return domains
//    }
//    do {
//        let content = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
//        let lines = content.components(separatedBy: "\n")
//        for line in lines {
//            // CIDR
//            if line.contains("/") {
//                if let subnetBits = Int(line.split(separator: "/")[1]) {
//                    let d = String(line.split(separator: "/")[0])
//                    let mask = 0xffffffff ^ ((1 << (32 - subnetBits)) - 1)
//                    let subnetMask = String.init(format: "%d.%d.%d.%d", (mask & 0x00ff000000) >> 24, (mask & 0x00ff0000) >> 16, (mask & 0x0000ff00) >> 8, (mask & 0xff))
//
//                    domains[d] = IPRange.init(subnetMask: subnetMask, enabled: true, IPv6: false, subnetBits: subnetBits)
//                }
//            }
//                // not CIDR, just feed the IP itself
//            else {
//                domains[line] = IPRange.init(subnetMask: "255.255.255.255", enabled: true, IPv6: false, subnetBits: 0)
//            }
//        }
//    } catch _ as NSError {
//    }
//    return domains
//}
//
//func getBlockedIPv6List(filename: String) -> Dictionary<String, IPRange> {
//    var domains = [String : IPRange]()
//    guard let ipv6Path = Bundle.main.path(forResource: filename, ofType: "txt") else {
//        return domains
//    }
//    do {
//        let content = try String(contentsOfFile:ipv6Path, encoding: String.Encoding.utf8)
//        let lines = content.components(separatedBy: "\n")
//        for line in lines {
//            if line.contains("/") {
//                if let subnetBits = Int(line.split(separator: "/")[1]) {
//                    let d = String(line.split(separator: "/")[0])
//                    let subnetMask = "\(subnetBits)"
//                    domains[d] = IPRange.init(subnetMask: subnetMask, enabled: true, IPv6: true, subnetBits: subnetBits)
//                }
//            }
//        }
//    } catch _ as NSError {
//    }
//    return domains
//}
