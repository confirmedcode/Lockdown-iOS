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

func deviceHasRestarted() -> Bool {
    let currentSystemUptime: TimeInterval = ProcessInfo.processInfo.systemUptime
    let lastSystemUptime = UserDefaults.standard.double(forKey: "SystemUpTime")
    DDLogInfo("SYSTEM RESTART CHECK: LAST UPTIME \(lastSystemUptime) | CURRENT \(currentSystemUptime)")
    UserDefaults.standard.set(currentSystemUptime, forKey: "SystemUpTime")
    if (currentSystemUptime < lastSystemUptime || lastSystemUptime == 0) {
        DDLogInfo("SYSTEM RESTART CHECK: RESTARTED - LAST UPTIME \(lastSystemUptime) | CURRENT \(currentSystemUptime)")
        return true
    }
    DDLogInfo("SYSTEM RESTART CHECK: NOT RESTARTED")
    return false
}

func appHasJustBeenUpgradedOrIsNewInstall() -> Bool {
    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    let versionOfLastRun = UserDefaults.standard.object(forKey: "VersionOfLastRun") as? String
    DDLogInfo("APP UPGRADED CHECK: LAST RUN \(versionOfLastRun ?? "n/a") | CURRENT \(currentVersion ?? "n/a")")
    UserDefaults.standard.set(currentVersion, forKey: "VersionOfLastRun")
    if (versionOfLastRun == nil || versionOfLastRun != currentVersion) {
        // either first time this check has occurred, or app was updated since last run
        DDLogInfo("APP UPGRADED CHECK: TRUE - LAST RUN \(versionOfLastRun ?? "n/a") | CURRENT \(currentVersion ?? "n/a")")
        return true
    } else {
        // nothing changed
        DDLogInfo("APP UPGRADED CHECK: FALSE")
        return false
    }
}

let reachability = Reachability()

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

// MARK: - API Credentials

let kAPICredentialsEmail = "APICredentialsEmail"
let kAPICredentialsPassword = "APICredentialsPassword"

struct APICredentials {
    var email: String = ""
    var password: String = ""
}

func setAPICredentials(email: String, password: String) throws {
    print("Setting API Credentials with email: \(email)")
    if (email == "") {
        throw "Email was blank"
    }
    if (password == "") {
        throw "Password was blank"
    }
    do {
        try keychain.set(email, key: kAPICredentialsEmail)
        try keychain.set(password, key: kAPICredentialsPassword)
    }
    catch {
        throw "Unable to set API credentials on keychain"
    }
}

func clearAPICredentials() {
    try? keychain.remove(kAPICredentialsEmail)
    try? keychain.remove(kAPICredentialsPassword)
}

func getAPICredentials() -> APICredentials? {
    print("Getting stored API credentials")
    var email: String? = nil
    do {
        email = try keychain.get(kAPICredentialsEmail)
        if email == nil {
            print("No stored API credential email")
            return nil
        }
    }
    catch {
        print("Error getting stored API credentials email: \(error)")
        return nil
    }
    var password: String? = nil
    do {
        password = try keychain.get(kAPICredentialsPassword)
        if password == nil {
            print("No stored API credential password")
            return nil
        }
    }
    catch {
        print("Error getting stored API credentials password: \(error)")
        return nil
    }
    print("Returning stored API credentials with email: \(email!)")
    return APICredentials(email: email!, password: password!)
}

let kAPICredentialsConfirmed = "APICredentialsConfirmed"

func getAPICredentialsConfirmed() -> Bool {
    return defaults.bool(forKey: kAPICredentialsConfirmed)
}

func setAPICredentialsConfirmed(confirmed: Bool) {
    defaults.set(confirmed, forKey: kAPICredentialsConfirmed)
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
    static let tunnelsDarkBlue = UIColor(red: 0/255.0, green: 117/255.0, blue: 157/255.0, alpha: 1.0)
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
