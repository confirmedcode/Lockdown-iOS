//
//  SharedConstants.swift
//  LockdowniOS
//
//  Created by Johnny Lin on 8/8/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//
// These are constants and functions shared by the main app and the extensions

import Foundation
import CocoaLumberjackSwift
import KeychainAccess
import Reachability

let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"

var appInstallDate: Date? {
    if let documentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
        if let installDate = try! FileManager.default.attributesOfItem(atPath: documentsFolder.path)[.creationDate] as? Date {
            return installDate
        }
    }
    return nil
}

let reachability = Reachability()

let defaults = UserDefaults(suiteName: "group.com.confirmed")!
let keychain = Keychain(service: "com.confirmed.tunnels").synchronizable(true)

// MARK: - VPN Credentials

let kVPNCredentialsKeyBase64 = "VPNCredentialsKeyBase64"
let kVPNCredentialsId = "VPNCredentialsId"

let kICloudContainer = "iCloud.com.confirmed.lockdown"
let kOpenFirewallTunnelRecord = "OpenFirewallTunnelRemotely"
let kCloseFirewallTunnelRecord = "CloseFirewallTunnelRemotely"
let kRestartFirewallTunnelRecord = "RestartFirewallTunnelRemotely"

struct VPNCredentials {
    var id: String = ""
    var keyBase64: String = ""
}

func setVPNCredentials(id: String, keyBase64: String) throws {
    DDLogInfo("Setting VPN Credentials: \(id), base64: \(keyBase64)")
    if (id == "") {
        throw "ID was blank"
    }
    if (keyBase64 == "") {
        throw "Key was blank"
    }
    do {
        try keychain.set(id, key: kVPNCredentialsId)
        try keychain.set(keyBase64, key: kVPNCredentialsKeyBase64)
    }
    catch {
        throw "Unable to set VPN credentials on keychain"
    }
}

func getVPNCredentials() -> VPNCredentials? {
    DDLogInfo("Getting stored VPN credentials")
    var id: String? = nil
    do {
        id = try keychain.get(kVPNCredentialsId)
        if id == nil {
            DDLogError("No stored credential id")
            return nil
        }
    }
    catch {
        DDLogError("Error getting stored VPN credentials id: \(error)")
        return nil
    }
    var keyBase64: String? = nil
    do {
        keyBase64 = try keychain.get(kVPNCredentialsKeyBase64)
        if keyBase64 == nil {
            DDLogError("No stored credential keyBase64")
            return nil
        }
    }
    catch {
        DDLogError("Error getting stored VPN credentials keyBase64: \(error)")
        return nil
    }
    DDLogInfo("Returning stored VPN credentials: \(id!) \(keyBase64!)")
    return VPNCredentials(id: id!, keyBase64: keyBase64!)
}


// MARK: - User wants Firewall/VPN Enabled

let kUserWantsFirewallEnabled = "user_wants_firewall_enabled"
let kUserWantsVPNEnabled = "user_wants_vpn_enabled"

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


// MARK: - VPN Region

let kSavedVPNRegionServerPrefix = "vpn_region_server_prefix"

struct VPNRegion {
    var regionDisplayName: String = ""
    var regionDisplayNameShort: String = ""
    var regionFlagEmoji: String = ""
    var serverPrefix: String = ""
}

let vpnRegions:[VPNRegion] = [
    VPNRegion(regionDisplayName: NSLocalizedString("United States - West", comment: ""),
              regionDisplayNameShort: NSLocalizedString("USA West", comment: ""),
              regionFlagEmoji: "🇺🇸",
              serverPrefix: "us-west"),
    VPNRegion(regionDisplayName: NSLocalizedString("United States - East", comment: ""),
              regionDisplayNameShort: NSLocalizedString("USA East", comment: ""),
              regionFlagEmoji: "🇺🇸",
              serverPrefix: "us-east"),
    VPNRegion(regionDisplayName: NSLocalizedString("United Kingdom", comment: ""),
              regionDisplayNameShort: NSLocalizedString("United Kingdom", comment: ""),
              regionFlagEmoji: "🇬🇧",
              serverPrefix: "eu-london"),
    VPNRegion(regionDisplayName: NSLocalizedString("Ireland", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Ireland", comment: ""),
              regionFlagEmoji: "🇮🇪",
              serverPrefix: "eu-ireland"),
    VPNRegion(regionDisplayName: NSLocalizedString("Germany", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Germany", comment: ""),
              regionFlagEmoji: "🇩🇪",
              serverPrefix: "eu-frankfurt"),
    VPNRegion(regionDisplayName: NSLocalizedString("Canada", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Canada", comment: ""),
              regionFlagEmoji: "🇨🇦",
              serverPrefix: "canada"),
    VPNRegion(regionDisplayName: NSLocalizedString("India", comment: ""),
              regionDisplayNameShort: NSLocalizedString("India", comment: ""),
              regionFlagEmoji: "🇮🇳",
              serverPrefix: "ap-mumbai"),
    VPNRegion(regionDisplayName: NSLocalizedString("Japan", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Japan", comment: ""),
              regionFlagEmoji: "🇯🇵",
              serverPrefix: "ap-tokyo"),
    VPNRegion(regionDisplayName: NSLocalizedString("Australia", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Australia", comment: ""),
              regionFlagEmoji: "🇦🇺",
              serverPrefix: "ap-sydney"),
    VPNRegion(regionDisplayName: NSLocalizedString("South Korea", comment: ""),
              regionDisplayNameShort: NSLocalizedString("South Korea", comment: ""),
              regionFlagEmoji: "🇰🇷",
              serverPrefix: "ap-seoul"),
    VPNRegion(regionDisplayName: NSLocalizedString("Singapore", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Singapore", comment: ""),
              regionFlagEmoji: "🇸🇬",
              serverPrefix: "ap-singapore"),
    VPNRegion(regionDisplayName: NSLocalizedString("Brazil", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Brazil", comment: ""),
              regionFlagEmoji: "🇧🇷",
              serverPrefix: "sa")
]

func getVPNRegionForServerPrefix(serverPrefix: String) -> VPNRegion {
    DDLogError("Getting VPN region for server prefix: \(serverPrefix)")
    for vpnRegion in vpnRegions {
        if vpnRegion.serverPrefix == serverPrefix {
            return vpnRegion
        }
    }
    DDLogError("Could not find VPN region for server prefix: \(serverPrefix)")
    return vpnRegions[0]
}

func getSavedVPNRegion() -> VPNRegion {
    DDLogInfo("getSavedVPNRegion")
    if let savedVPNRegionServerPrefix = defaults.string(forKey: kSavedVPNRegionServerPrefix) {
        return getVPNRegionForServerPrefix(serverPrefix: savedVPNRegionServerPrefix)
    }
    
    // get default savedRegion by locale
    let locale = NSLocale.autoupdatingCurrent
    if let regionCode = locale.regionCode {
        switch regionCode {
        case "US":
            if let timezone = TimeZone.autoupdatingCurrent.abbreviation() {
                if timezone == "EST" || timezone == "EDT" || timezone == "CST" {
                    return getVPNRegionForServerPrefix(serverPrefix: "us-east")
                }
            }
            else {
                return getVPNRegionForServerPrefix(serverPrefix: "us-west")
            }
        case "GB":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-london")
        case "IE":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-london")
        case "CA":
            return getVPNRegionForServerPrefix(serverPrefix: "canada")
        case "KO":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-seoul")
        case "ID", "SG", "MY", "PH", "TH", "TW", "VN":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-singapore")
        case "DE", "FR", "IT", "PT", "ES", "AT", "PL", "RU", "UA", "NG", "TR", "ZA":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-frankfurt")
        case "AU", "NZ":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-sydney")
        case "AE", "IN", "PK", "BD", "QA", "SA":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-mumbai")
        case "EG":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-frankfurt")
        case "JP":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-tokyo")
        case "BR", "CO", "VE", "AR":
            return getVPNRegionForServerPrefix(serverPrefix: "sa")
        default:
            return vpnRegions[0]
        }
    }
    return vpnRegions[0]
}

func setSavedVPNRegion(vpnRegion: VPNRegion) {
    defaults.set(vpnRegion.serverPrefix, forKey: kSavedVPNRegionServerPrefix)
}

// MARK: - Extensions

extension String: Error { // Error makes it easy to throw errors as one-liners
    
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
}

extension UIColor {
    static let tunnelsBlue = UIColor(red: 0/255.0, green: 173/255.0, blue: 231/255.0, alpha: 1.0)
    static let tunnelsWarning = UIColor(red: 231/255.0, green: 76/255.0, blue: 68/255.0, alpha: 1.0)
}

extension UnicodeScalar {
    var hexNibble:UInt8 {
        let value = self.value
        if 48 <= value && value <= 57 {
            return UInt8(value - 48)
        }
        else if 65 <= value && value <= 70 {
            return UInt8(value - 55)
        }
        else if 97 <= value && value <= 102 {
            return UInt8(value - 87)
        }
        fatalError("\(self) not a legal hex nibble")
    }
}

extension Data {
    init(hex: String) {
        let scalars = hex.unicodeScalars
        var bytes = Array<UInt8>(repeating: 0, count: (scalars.count + 1) >> 1)
        for (index, scalar) in scalars.enumerated() {
            var nibble = scalar.hexNibble
            if index & 1 == 0 {
                nibble <<= 4
            }
            bytes[index >> 1] |= nibble
        }
        self = Data(bytes: bytes)
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

enum AppConfiguration {
    case Debug
    case TestFlight
    case AppStore
}

struct Config {
    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var appConfiguration: AppConfiguration {
        if isDebug {
            return .Debug
        } else if isTestFlight {
            return .TestFlight
        } else {
            return .AppStore
        }
    }
}

// MARK: - Fonts
let fontMedium14 = UIFont(name: "Montserrat-Medium", size: 14)!
let fontMedium15 = UIFont(name: "Montserrat-Medium", size: 15)!
let fontMedium16 = UIFont(name: "Montserrat-Medium", size: 16)!
let fontMedium18 = UIFont(name: "Montserrat-Medium", size: 18.0)!
let fontSemiBold15_5 = UIFont(name: "Montserrat-SemiBold", size: 15.5)!
let fontSemiBold17 = UIFont(name: "Montserrat-SemiBold", size: 17)!
let fontBold15 = UIFont(name: "Montserrat-Bold", size: 15)!
