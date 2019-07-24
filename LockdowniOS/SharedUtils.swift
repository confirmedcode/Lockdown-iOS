//
//  SharedUtils.swift
//
//  Shared functions between Mac & iOS
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

#if os(iOS)
    import UIKit
#endif
import Foundation
import NetworkExtension
import CocoaLumberjackSwift
import CoreTelephony

class SharedUtils: CoreUtils {
    
    public static let kActiveProtocol = "ConfirmedActiveProtocol"
    
    static func getSavedRegion() -> ServerRegion {
        DDLogInfo("API Version - \(Global.vpnSavedRegionKey)")
        if let reg = UserDefaults.standard.string(forKey: Global.vpnSavedRegionKey), let serverRegion = ServerRegion.init(rawValue: reg) {
            DDLogInfo("Getting saved region - \(reg)")
            return serverRegion
        }
        else {
            //intelligently determine area based on current region
            let theLocale = NSLocale.autoupdatingCurrent
            
            var nearestRegion = ServerRegion.usWest
            
            if theLocale.regionCode! == "US" {
                let theTZ = TimeZone.autoupdatingCurrent.abbreviation()!
                if theTZ == "EST" || theTZ == "EDT" || theTZ == "CST" {
                    nearestRegion = ServerRegion.usEast
                }
            }
            if theLocale.regionCode! == "GB" {
                nearestRegion = ServerRegion.euLondon
            }
            if theLocale.regionCode! == "IE" {
                nearestRegion = ServerRegion.euLondon
            }
            if theLocale.regionCode! == "CA"  {
                nearestRegion = ServerRegion.canada
            }
            if theLocale.regionCode! == "KO"  {
                nearestRegion = ServerRegion.seoul
            }
            if theLocale.regionCode! == "ID" /* Indonesia */ || theLocale.regionCode! == "SG" /* Singapore */ || theLocale.regionCode! == "MY" /* Malaysia */ || theLocale.regionCode! == "PH" /* Phillipines */ || theLocale.regionCode! == "TH" /* Thailand */ || theLocale.regionCode! == "TW" /* Taiwan */ || theLocale.regionCode! == "VN" /* Vietnam */ {
                nearestRegion = ServerRegion.singapore
            }
            if theLocale.regionCode! == "DE" || theLocale.regionCode! == "FR" || theLocale.regionCode! == "IT" || theLocale.regionCode! == "PT" || theLocale.regionCode! == "ES" || theLocale.regionCode! == "AT" || theLocale.regionCode! == "PL" || theLocale.regionCode! == "RU" || theLocale.regionCode! == "UA" || theLocale.regionCode! == "NG" || theLocale.regionCode! == "TR" /* Turkey */ || theLocale.regionCode! == "ZA" /* South Africa */  {
                nearestRegion = ServerRegion.euFrankfurt
            }
            if theLocale.regionCode! == "AU" || theLocale.regionCode! == "NZ" {
                nearestRegion = ServerRegion.sydney
            }
            if theLocale.regionCode! == "AE" || theLocale.regionCode! == "IN" || theLocale.regionCode! == "PK" || theLocale.regionCode! == "BD" || theLocale.regionCode! == "QA" /* Qatar */ || theLocale.regionCode! == "SA" /* Saudi */{ //UAE
                nearestRegion = ServerRegion.mumbai
            }
            if theLocale.regionCode! == "EG" { //EGYPT
                nearestRegion = ServerRegion.euFrankfurt
            }
            if theLocale.regionCode! == "JP" {
                nearestRegion = ServerRegion.tokyo
            }
            if theLocale.regionCode! == "BR" || theLocale.regionCode! == "CO" || theLocale.regionCode! == "VE" || theLocale.regionCode! == "AR" {
                nearestRegion = ServerRegion.brazil
            }
            
            setSavedRegion(region: nearestRegion);
            return nearestRegion; // default region
        }
    }
    
    static func setSavedRegion(region: ServerRegion) {
        let defaults = UserDefaults.standard
        defaults.set(region.rawValue, forKey: Global.vpnSavedRegionKey)
        defaults.synchronize()
    }
    
    static func setKeyForDefaults(inDomain : Dictionary<String, Any>, key : String, val : NSNumber, defaultKey : String) {
        var domain = inDomain
        let defaults = UserDefaults(suiteName: userDefaultsSuite)!
        
        domain[key] = val
        defaults.set(domain, forKey: defaultKey)
        defaults.synchronize()
    }
    
    static func removeKeyForDefaults(inDomain : Dictionary<String, Any>, key : String, defaultKey : String) {
        var domain = inDomain
        let defaults = UserDefaults(suiteName: userDefaultsSuite)!
        
        domain[key] = nil
        defaults.set(domain, forKey: defaultKey)
        
        defaults.synchronize()
    }
    
    
    // return an error message or a nil string
    static func validateCredentialFormat(email : String, password : String, passwordConfirmation : String) -> String? {
        if !Utils.isValidEmail(emailAddress: email) {
            return "Please enter a valid e-mail."
        }
        
        if password != passwordConfirmation {
            return "Your passwords do not match."
        }
        
        if password.count < 5 {
            return "Please use a password with at least 8 letters."
        }
        
        return nil
    }
    
    static func isValidEmail(emailAddress:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: emailAddress)
    }
    
    static func getVersionString() -> String {
        return "v" + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) + "-" + Global.apiVersionPrefix()
    }
    
    static func getUserLockdown() -> Dictionary<String, Any> {
        let defaults = UserDefaults(suiteName: "group.com.confirmed")!
        //LockdownDefaults
        
        
        if let domains = defaults.dictionary(forKey:Global.kUserLockdownDomains) {
            return domains
        }
        return Dictionary()
    }
    
    static func setDomainForUserLockdown(key : String, val : NSNumber?) {
        var domains = getUserLockdown()
        domains[key] = val
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(domains, forKey: Global.kUserLockdownDomains)
        defaults.synchronize()
    }
    
    static func addDomainToUserLockdown(key : String) {
        var domains = getUserLockdown()
        domains[key] = NSNumber.init(value: true)
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(domains, forKey: Global.kUserLockdownDomains)
        defaults.synchronize()
    }
    
    static func setupRules() -> Array<String> {
        let defaults = UserDefaults(suiteName: userDefaultsSuite)!
        var domains = defaults.dictionary(forKey:"whitelisted_domains") as? Dictionary<String, Any>
        
        if domains == nil {
            domains = Dictionary()
        }
        
        defaults.set(domains, forKey: "whitelisted_domains")
        defaults.synchronize()
        
        var userDomains = defaults.dictionary(forKey:"whitelisted_domains_user") as? Dictionary<String, Any>
        
        if userDomains == nil {
            userDomains = Dictionary()
        }
        
        defaults.set(userDomains, forKey: "whitelisted_domains_user")
        defaults.synchronize()
        
        var whitelistedDomains = Array<String>.init()
        
        for (key, value) in domains! {
            if (value as AnyObject).boolValue {
                var formattedKey = key
                if key.split(separator: ".").count == 1 {
                    formattedKey = "*." + key
                }
                whitelistedDomains.append(formattedKey)
            }
        }
        
        for (key, value) in userDomains! {
            if (value as AnyObject).boolValue {
                var formattedKey = key
                if key.split(separator: ".").count == 1 {
                    formattedKey = "*." + key
                }
                whitelistedDomains.append(key)
            }
        }
        
        return whitelistedDomains
    }
    
    static func checkForSwitchedEnvironments() {
        if !Utils.isAppInProduction() {
            let defaults = UserDefaults.standard
            if let lastEnvironment = defaults.string(forKey: Global.kLastEnvironment) {
                if lastEnvironment != Global.vpnDomain {
                    Global.keychain[Global.kConfirmedReceiptKey] = nil
                    Global.keychain[Global.kConfirmedP12Key] = nil
                    Global.keychain[Global.kConfirmedID] = nil
                    Global.keychain[Global.kConfirmedEmail] = nil
                    Global.keychain[Global.kConfirmedPassword] = nil
                    Auth.clearCookies()
                    defaults.removeObject(forKey: Global.vpnSavedRegionKey)
                    defaults.set(Global.vpnDomain, forKey: Global.kLastEnvironment)
                    defaults.synchronize()
                }
            }
            else {
                defaults.set(Global.vpnDomain, forKey: Global.kLastEnvironment)
                defaults.synchronize()
            }
        }
    }
    
    static func isAppInProduction() -> Bool {
        #if os(iOS)
            if Config.appConfiguration == AppConfiguration.AppStore || Global.forceProduction {
                return true
            }
            else {
                return false
            }
        #else
            #if DEBUG
                if !Global.forceProduction {
                    return false
                }
                else {
                    return true
                }
            #else
                return true
            #endif
        #endif
    }
    
    static func getSource() -> String {
        if Global.isVersion(version: .v1API) || Global.isVersion(version: .v2API) {
            return "both"
        }
        return ""
    }
    
    
    static func setActiveProtocol(activeProtocol : String) {
        if let defaults = UserDefaults(suiteName: SharedUtils.userDefaultsSuite) {
            defaults.set(activeProtocol, forKey: kActiveProtocol)
            defaults.synchronize()
        }
    }
    
    static func getActiveProtocol() -> String {
        if let defaults = UserDefaults(suiteName: SharedUtils.userDefaultsSuite), let activeProtocol = defaults.value(forKey: kActiveProtocol) as? String {
            return activeProtocol
        }
        else {
            let networkInfo = CTTelephonyNetworkInfo()
            if let countryCode = (Locale.current as NSLocale).object(forKey: .countryCode) as? String, let carrier = networkInfo.subscriberCellularProvider, let carrierName = carrier.carrierName{
                setActiveProtocol(activeProtocol: IPSecV3.protocolName)
                if countryCode == "AE" && carrierName.lowercased() == "etisalat" {
                    //setActiveProtocol(activeProtocol: IPSecV3.protocolName)
                    //return OpenVPN.protocolName
                }
            }
            
            setActiveProtocol(activeProtocol: IPSecV3.protocolName)
        }
        
        
        return IPSecV3.protocolName
    }
}

