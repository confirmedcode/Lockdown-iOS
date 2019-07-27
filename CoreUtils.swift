//
//  CoreUtils.swift
//  Lockdown
//
//  Cross-platform Utils with as few pod dependencies as possible (to allow includsion in extensions)
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class CoreUtils: NSObject {

    #if os(iOS)
    static let userDefaultsSuite = "group.com.confirmed"
    #else
    static let userDefaultsSuite = "group.com.confirmed.tunnelsMac"
    #endif
    
    //MARK: - Whitelisting helper functions
    
    static func getUserWhitelist() -> Dictionary<String, Any> {
        let defaults = Global.sharedUserDefaults()
        
        if let domains = defaults.dictionary(forKey:Global.kUserWhitelistedDomains) {
            return domains
        }
        return Dictionary()
    }
    
    static func getConfirmedLockdown() -> LockdownDefaults {
        let defaults = UserDefaults(suiteName: "group.com.confirmed")!
        
        guard let lockdownDefaultsData = defaults.object(forKey: Global.kConfirmedLockdownDomains) as? Data else {
            return LockdownDefaults.init(lockdownDefaults: [:])
        }
        
        guard let lockdownDefaults = try? PropertyListDecoder().decode(LockdownDefaults.self, from: lockdownDefaultsData) else {
            return LockdownDefaults.init(lockdownDefaults: [:])
        }
        
        return lockdownDefaults
    }
    
    static func loadDomainBlockList(filename: String) -> Dictionary<String, Bool> {
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
    
    static func loadIPv4BlockList(filename: String) -> Dictionary<String, IPRange> {
        var domains = [String : IPRange]()
        guard let path = Bundle.main.path(forResource: filename, ofType: "txt") else {
            return domains
        }
        do {
            let content = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
            let lines = content.components(separatedBy: "\n")
            for line in lines {
                // CIDR
                if line.contains("/") {
                    if let subnetBits = Int(line.split(separator: "/")[1]) {
                        let d = String(line.split(separator: "/")[0])
                        let mask = 0xffffffff ^ ((1 << (32 - subnetBits)) - 1)
                        let subnetMask = String.init(format: "%d.%d.%d.%d", (mask & 0x00ff000000) >> 24, (mask & 0x00ff0000) >> 16, (mask & 0x0000ff00) >> 8, (mask & 0xff))
                        
                        domains[d] = IPRange.init(subnetMask: subnetMask, enabled: true, IPv6: false, subnetBits: subnetBits)
                    }
                }
                // not CIDR, just feed the IP itself
                else {
                    domains[line] = IPRange.init(subnetMask: "255.255.255.255", enabled: true, IPv6: false, subnetBits: 0)
                }
            }
        } catch _ as NSError {
        }
        return domains
    }
    
    static func loadIPv6BlockList(filename: String) -> Dictionary<String, IPRange> {
        var domains = [String : IPRange]()
        guard let ipv6Path = Bundle.main.path(forResource: filename, ofType: "txt") else {
            return domains
        }
        do {
            let content = try String(contentsOfFile:ipv6Path, encoding: String.Encoding.utf8)
            let lines = content.components(separatedBy: "\n")
            for line in lines {
                if line.contains("/") {
                    if let subnetBits = Int(line.split(separator: "/")[1]) {
                        let d = String(line.split(separator: "/")[0])
                        let subnetMask = "\(subnetBits)"
                        domains[d] = IPRange.init(subnetMask: subnetMask, enabled: true, IPv6: true, subnetBits: subnetBits)
                    }
                }
            }
        } catch _ as NSError {
        }
        return domains
    }
    
    static func setupLockdownDefaults() {
        
        let defaults = Global.sharedUserDefaults()
        var domains = getConfirmedLockdown()
        
        let clickbait = LockdownGroup.init(
            version: 20,
            internalID: "clickbait",
            name: "Clickbait",
            iconURL: "clickbait_icon",
            enabled: false,
            domains: loadDomainBlockList(filename: "clickbait"),
            ipRanges: [:])
        
        let crypto = LockdownGroup.init(
            version: 20,
            internalID: "crypto_mining",
            name: "Crypto Mining",
            iconURL: "crypto_icon",
            enabled: true,
            domains: loadDomainBlockList(filename: "crypto_mining"),
            ipRanges: [:])
        
        let emailOpens = LockdownGroup.init(
            version: 20,
            internalID: "email_opens",
            name: "Email Opens (Beta)",
            iconURL: "email_icon",
            enabled: false,
            domains: loadDomainBlockList(filename: "email_opens"),
            ipRanges: [:])
        
        let facebookInc = LockdownGroup.init(
            version: 20,
            internalID: "facebook_inc",
            name: "Facebook Inc (Beta)",
            iconURL: "facebook_icon",
            enabled: false,
            domains: loadDomainBlockList(filename: "facebook_inc"),
            ipRanges: [:])
        
        let facebookSDK = LockdownGroup.init(
            version: 20,
            internalID: "facebook_sdk",
            name: "Facebook SDK",
            iconURL: "facebook_white_icon",
            enabled: true,
            domains: loadDomainBlockList(filename: "facebook_sdk"),
            ipRanges: [:])
        
        let marketingScripts = LockdownGroup.init(
            version: 20,
            internalID: "marketing_scripts",
            name: "Marketing Scripts",
            iconURL: "marketing_icon",
            enabled: true,
            domains: loadDomainBlockList(filename: "marketing"),
            ipRanges: [:])
        
        let ransomware = LockdownGroup.init(
            version: 20,
            internalID: "ransomware",
            name: "Ransomware",
            iconURL: "ransomware_icon",
            enabled: false,
            domains: loadDomainBlockList(filename: "ransomware"),
            ipRanges: [:])
        
        let defaultLockdownSettings = [clickbait,
                                       crypto,
                                       emailOpens,
                                       facebookInc,
                                       facebookSDK,
                                       marketingScripts,
                                       ransomware];
        
        for var def in defaultLockdownSettings {
            if let current = domains.lockdownDefaults[def.internalID], current.version >= def.version {}
            else {
                if let current = domains.lockdownDefaults[def.internalID] {
                    def.enabled = current.enabled // don't replace whether it was disabled
                }
                domains.lockdownDefaults[def.internalID] = def
            }
        }
        
        for (key, value) in domains.lockdownDefaults {
            if let current = domains.lockdownDefaults[value.name] {
                domains.lockdownDefaults.removeValue(forKey: value.name)
            }
        }
       
        defaults.set(try? PropertyListEncoder().encode(domains), forKey: Global.kConfirmedLockdownDomains)
        defaults.synchronize()
    }
    
    static func getConfirmedWhitelist() -> Dictionary<String, Any> {
        let defaults = Global.sharedUserDefaults()
        
        if let domains = defaults.dictionary(forKey:Global.kConfirmedWhitelistedDomains) {
            return domains
        }
        return Dictionary()
    }
    
    static func addDomainToUserWhitelist(key : String) {
        var domains = getUserWhitelist()
        domains[key] = NSNumber.init(value: true)
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(domains, forKey: Global.kUserWhitelistedDomains)
        defaults.synchronize()
    }
    
    static func removeDomainFromUserWhitelist(key : String) {
        var domains = getUserWhitelist()
        domains[key] = nil
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(domains, forKey: Global.kUserWhitelistedDomains)
        defaults.synchronize()
    }
    
    static func setDomainForUserWhitelist(key : String, val : NSNumber?) {
        var domains = getUserWhitelist()
        domains[key] = val
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(domains, forKey: Global.kUserWhitelistedDomains)
        defaults.synchronize()
    }
    
    static func addKeyToDefaults(inDomain : Dictionary<String, Any>, key : String) -> Dictionary<String, Any> {
        var domains = inDomain
        if domains[key] == nil {
            domains[key] = NSNumber.init(value: true)
        }
        
        return domains
    }
    
    
    /*
     * called frequently to allow updates
     */
    static func setupWhitelistedDefaults() {
        let defaults = Global.sharedUserDefaults()
        var domains = defaults.dictionary(forKey:"whitelisted_domains")
        
        if domains == nil {
            domains = Dictionary()
        }
        
        //add default keys
        //domains = Utils.addKeyToDefaults(inDomain: domains!, key: "*.ipchicken.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "hulu.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "netflix.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "api.twitter.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "mobile.twitter.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "houzz.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "apple.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "icloud.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "skype.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "confirmedvpn.com")
        domains = self.addKeyToDefaults(inDomain: domains!, key: "confirmedvpn.co") //deprecated API versions
        
        defaults.set(domains, forKey: "whitelisted_domains")
        defaults.synchronize()
    }
    
    static func setupWhitelistedDomains() {
        let defaults = UserDefaults(suiteName: userDefaultsSuite)!
        var domains = defaults.dictionary(forKey:"whitelisted_domains")
        
        if domains == nil {
            domains = Dictionary()
        }
        
        defaults.set(domains, forKey: "whitelisted_domains")
        defaults.synchronize()
        
        var userDomains = defaults.dictionary(forKey:"whitelisted_domains_user")
        
        if userDomains == nil {
            userDomains = Dictionary()
        }
        
        defaults.set(userDomains, forKey: "whitelisted_domains_user")
        defaults.synchronize()
        
        setupWhitelistedDefaults()
    }
    
    /*
     * decide API version if not chosen
     * maximize V2 users
     * base on whether last saved region exists, and whether it had a source ID
     */
    static func chooseAPIVersion() {
        if UserDefaults.standard.string(forKey: Global.kConfirmedAPIVersion) == nil {
            UserDefaults.standard.set(APIVersionType.v3API, forKey: Global.kConfirmedAPIVersion)
            UserDefaults.standard.synchronize()
            
            NotificationCenter.post(name: .switchingAPIVersions)
        }
    }
    
}

extension String {
    //Base64 encode a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        
        return nil
    }
    
    //Base64 decode a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func trimAfterPhrase(phrase : String) -> String{
        if let range = self.range(of: phrase) {
            let substring = self[...range.upperBound]
            return String(substring)
        }
        
        return self //return original if not found
    }
    
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        //return NSLocalizedString(self, tableName: tableName, value: "***\(self)***", comment: "") USE THIS TO DEBUG MISSING STRINGS
        return NSLocalizedString(self, tableName: tableName, value: "\(self)", comment: "")
    }
}

struct IPRange : Codable {
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
    var ipRanges : Dictionary<String, IPRange>
}

struct LockdownDefaults : Codable {
    var lockdownDefaults : Dictionary<String, LockdownGroup>
}
