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
import UniformTypeIdentifiers

// MARK: - Constants

let kLockdownBlockedDomains = "lockdown_domains"
let kUserBlockedDomains = "lockdown_domains_user"
let kUserBlockedLists = "lockdown_lists_user"

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
    var accessLevel: String = "advanced"
}

struct LockdownDefaults : Codable {
    var lockdownDefaults : Dictionary<String, LockdownGroup>
}

struct UserBlockListsGroup: Codable {
    var name: String
    var enabled: Bool = false
    var domains: Set<String> = []
    var description: String?
}

struct UserBlockListsDefaults: Codable {
    var userBlockListsDefaults: Dictionary<String, UserBlockListsGroup>
}

//struct Domains: Codable {
//    var name: String
//    var isBlocked: Bool = true
//}

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
        ipRanges: [:],
        accessLevel: "basic")
    
    let clickbait = LockdownGroup.init(
        version: 29,
        internalID: "clickbait",
        name: NSLocalizedString("Clickbait", comment: "The title of a list of trackers"),
        iconURL: "clickbait_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "clickbait"),
        ipRanges: [:],
        accessLevel: "basic")
    
    let emailOpens = LockdownGroup.init(
        version: 30,
        internalID: "email_opens",
        name: NSLocalizedString("Email Trackers", comment: "The title of a list of trackers"),
        iconURL: "email_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "email_opens"),
        ipRanges: [:],
        accessLevel: "basic")
    
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
        ipRanges: [:],
        accessLevel: "basic")
    
    let marketingScripts = LockdownGroup.init(
        version: 31,
        internalID: "marketing_scripts",
        name: NSLocalizedString("Marketing Trackers", comment: "The title of a list of trackers"),
        iconURL: "marketing_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "marketing"),
        ipRanges: [:],
        accessLevel: "basic")
    
    let marketingScriptsII = LockdownGroup.init(
        version: 30,
        internalID: "marketing_beta_scripts",
        name: NSLocalizedString("Marketing Trackers II", comment: "The title of a list of trackers"),
        iconURL: "marketing_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "marketing_beta"),
        ipRanges: [:])

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
        ipRanges: [:],
        accessLevel: "basic")
    
    let generalAds = LockdownGroup.init(
        version: 40,
        internalID: "general_ads",
        name: NSLocalizedString("General Marketing", comment: "The title of a list of trackers"),
        iconURL: "ads_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "general_ads"),
        ipRanges: [:],
        accessLevel: "basic")
    
    let reporting = LockdownGroup.init(
        version: 29,
        internalID: "reporting",
        name: NSLocalizedString("Reporting", comment: "The title of a list of trackers"),
        iconURL: "reporting_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "reporting"),
        ipRanges: [:],
        accessLevel: "basic")
    
    let amazonTrackers = LockdownGroup.init(
        version: 32,
        internalID: "amazon_trackers",
        name: NSLocalizedString("Amazon Trackers", comment: "The title of a list of trackers"),
        iconURL: "amazon_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "amazon_trackers"),
        ipRanges: [:],
        warning: "This blocks Amazon referral link tracking too, so enabling this list may cause errors when clicking certain links on Amazon.",
        accessLevel: "basic")
    
    let ifunnyTrackers = LockdownGroup.init(
        version: 2,
        internalID: "ifunnyTrackers",
        name: NSLocalizedString("iFunny Trackers", comment: "The title of a list of trackers"),
        iconURL: "icn_vpn",
        enabled: false,
        domains: getDomainBlockList(filename: "ifunny_trackers"),
        ipRanges: [:])
    
    let advancedGaming = LockdownGroup.init(
        version: 2,
        internalID: "advancedGaming",
        name: NSLocalizedString("Advanced Gaming", comment: "The title of a list of trackers"),
        iconURL: "icn_vpn",
        enabled: false,
        domains: getDomainBlockList(filename: "advanced_gaming"),
        ipRanges: [:])
    
    let tiktokTrackers = LockdownGroup.init(
        version: 1,
        internalID: "tiktokTrackers",
        name: NSLocalizedString("Tiktok Trackers", comment: "The title of a list of trackers"),
        iconURL: "icn_vpn",
        enabled: false,
        domains: getDomainBlockList(filename: "tiktok_trackers"),
        ipRanges: [:])
    
    let scams = LockdownGroup.init(
        version: 2,
        internalID: "scams",
        name: NSLocalizedString("Scams", comment: "The title of a list of trackers"),
        iconURL: "icn_vpn",
        enabled: false,
        domains: getDomainBlockList(filename: "scams"),
        ipRanges: [:])
    
    let junesJourneyTrackers = LockdownGroup.init(
        version: 2,
        internalID: "junesJourneyTrackers",
        name: NSLocalizedString("Junes Journey Trackers", comment: "The title of a list of trackers"),
        iconURL: "icn_vpn",
        enabled: false,
        domains: getDomainBlockList(filename: "junes_journey_trackers"),
        ipRanges: [:])
    
    let advancedAnalytics = LockdownGroup.init(
        version: 1,
        internalID: "advancedAnalytics",
        name: NSLocalizedString("Advanced Analytics", comment: "The title of a list of trackers"),
        iconURL: "icn_vpn",
        enabled: false,
        domains: getDomainBlockList(filename: "advanced_analytics"),
        ipRanges: [:])
    
    let defaultLockdownSettings = [
        advancedAnalytics,
        junesJourneyTrackers,
        scams,
        tiktokTrackers,
        advancedGaming,
        ifunnyTrackers,
        snapchatAnalytics,
        gameAds,
        clickbait,
        emailOpens,
        facebookInc,
        facebookSDK,
        marketingScripts,
        marketingScriptsII,
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
    let userListsBlockedDomains = getBlockedLists()
    
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
    
    for (_, value) in userListsBlockedDomains.userBlockListsDefaults {
        if value.enabled {
            for domain in value.domains {
                allBlockedDomains.append(domain)
            }
        }
    }
    
    return allBlockedDomains
}

func getTotalEnabled() -> Array<String> {
    let lockdownBlockedDomains = getLockdownBlockedDomains()
    
    var total = Array<String>()
    for (_, ldValue) in lockdownBlockedDomains.lockdownDefaults {
        if ldValue.enabled {
            for (key, value) in ldValue.domains {
                if value {
                    total.append(key)
                }
            }
        }
    }
    
    return total
}

func getTotalDisabled() -> Array<String> {
    let lockdownBlockedDomains = getLockdownBlockedDomains()
    
    var total = Array<String>()
    for (_, ldValue) in lockdownBlockedDomains.lockdownDefaults {
        if !ldValue.enabled {
            for (key, value) in ldValue.domains {
                if value {
                    total.append(key)
                }
            }
        }
    }
    
    return total
}

func getIsCombinedBlockListEmpty() -> Bool {
    return (getAllBlockedDomains() + getAllWhitelistedDomains()).isEmpty
}

// MARK: - Curated Lockdown blocked domains

func getLockdownBlockedDomains() -> LockdownDefaults {
    guard let lockdownDefaultsData = defaults.object(forKey: kLockdownBlockedDomains) as? Data else {
        return LockdownDefaults(lockdownDefaults: [:])
    }
    guard let lockdownDefaults = try? PropertyListDecoder().decode(LockdownDefaults.self, from: lockdownDefaultsData) else {
        return LockdownDefaults(lockdownDefaults: [:])
    }
    return lockdownDefaults
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

// MARK: - User blocked lists

func getBlockedLists() -> UserBlockListsDefaults {
    guard let listsDefaultsData = defaults.object(forKey: kUserBlockedLists) as? Data else {
        return UserBlockListsDefaults(userBlockListsDefaults: [:])
    }
    
    guard let listDefaults = try? JSONDecoder().decode(UserBlockListsDefaults.self, from: listsDefaultsData) else {
        return UserBlockListsDefaults(userBlockListsDefaults: [:])
    }
    return listDefaults
}

func addBlockedList(listName: String) {
    var data = getBlockedLists()
    if !data.userBlockListsDefaults.keys.contains(listName) {
        data.userBlockListsDefaults[listName] = UserBlockListsGroup(name: listName, enabled: false)
        let encodedData = try? JSONEncoder().encode(data)
        defaults.set(encodedData, forKey: kUserBlockedLists)
    }
}

func changeBlockedListName(from listName: String, to newListName: String) {
    var data = getBlockedLists()
    data.userBlockListsDefaults[newListName] = data.userBlockListsDefaults[listName]
    data.userBlockListsDefaults[newListName]?.name = newListName
    data.userBlockListsDefaults[listName] = nil
    let encodedData = try? JSONEncoder().encode(data)
    defaults.set(encodedData, forKey: kUserBlockedLists)
}

func deleteBlockedList(listName: String) {
    var data = getBlockedLists()
    data.userBlockListsDefaults[listName] = nil
    let encodedData = try? JSONEncoder().encode(data)
    defaults.set(encodedData, forKey: kUserBlockedLists)
}

func addDomainToBlockedList(domain: String, for listName: String) {
    var data = getBlockedLists()
    data.userBlockListsDefaults[listName]?.domains.insert(domain)
    let encodedData = try? JSONEncoder().encode(data)
    defaults.set(encodedData, forKey: kUserBlockedLists)
}

extension UserBlockListsGroup {
    func generateCurrentTimeStamp () -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_hh_mm_ss"
        return (formatter.string(from: Date()) as NSString) as String
    }
    
    func exportToURL() -> URL? {
        let timeStamp = generateCurrentTimeStamp()
        let fileName = "LOCKDOWN_\(NSDate.now)"
        guard let encoded = try? JSONEncoder().encode(self) else { return nil }
        
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
        
        guard let path = documents?.appendingPathComponent("/\(fileName).csv") else {
            return nil
        }
        
        do {
            try encoded.write(to: path, options: .atomicWrite)
            print(fileName)
            return path
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    static func importData(from url: URL) {
        
//        if #available(iOSApplicationExtension 14.0, *) {
//            let supportedFiles: [UTType] = [UTType.data]
//
////            let controller = UIDocumentPickerViewController
//
//
//
//        } else {
//            // Fallback on earlier versions
//        }
        
        guard let data = try? Data(contentsOf: url)
//            let list = try? JSONDecoder().decode(UserBlockListsGroup.self, from: data)
                
        else { return }
        defaults.set(data, forKey: kUserBlockedLists)
        try? FileManager.default.removeItem(at: url)
    }
}

//extension Domains {
//    
//    func generateCurrentTimeStamp () -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy_MM_dd_hh_mm_ss"
//        return (formatter.string(from: Date()) as NSString) as String
//    }
//    
//    func exportToURL() -> URL? {
//        
//        let timeStamp = generateCurrentTimeStamp()
//        let fileName = "LOCKDOWN_\(NSDate.now)"
//        guard let encoded = try? JSONEncoder().encode(self) else { return nil }
//        
//        let documents = FileManager.default.urls(
//            for: .documentDirectory,
//            in: .userDomainMask
//        ).first
//        
//        guard let path = documents?.appendingPathComponent("/\(fileName).csv") else {
//            return nil
//        }
//        
//        do {
//            try encoded.write(to: path, options: .atomicWrite)
//            print(fileName)
//            return path
//        } catch {
//            print(error.localizedDescription)
//            return nil
//        }
//    }
//    
//    static func importData(from url: URL) {
//        guard
//            let data = try? Data(contentsOf: url),
//            let domain = try? JSONDecoder().decode(Domains.self, from: data)
//                
//                
//        else { return }
//        addDomainToBlockedList(domain: domain.name, for: "oop")
//        
//        
//        try? FileManager.default.removeItem(at: url)
//    }
//}
