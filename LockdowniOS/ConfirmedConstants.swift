//
//  Global.swift
//  Confirmed VPN
//
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Foundation
#endif
import KeychainAccess
import Reachability

class Global {
    static let reachability = Reachability()
    static let keychain = Keychain(service: "com.confirmed.tunnels").synchronizable(true)
    
    static let forceProduction = true //switch on to force prod routes
    static var sourceID : String {
        get {
            if Global.isVersion(version: .v1API) {
                return ""
            }
            else if Global.isVersion(version: .v2API){
                return "-090718" //certificate chain
            }
            else {
                return "-111818" //certificate chain
            }
        }
    }
    
    static func isVersion(version : APIVersionType) -> Bool {
        if UserDefaults.standard.string(forKey:Global.kConfirmedAPIVersion) == nil {
            CoreUtils.chooseAPIVersion()
        }
        if UserDefaults.standard.string(forKey:Global.kConfirmedAPIVersion) == version {
            return true
        }
        else {
            return false
        }
    }
    
    static var vpnPassword : String {
        get {
            if Global.isVersion(version: .v1API) {
                return "trustwizardsjustplaying"
            }
            else {
                #if os(iOS)
                    return ""
                #else
                    return "rdar://12503102" //macOS requires a password here
                #endif
            }
        }
    }
    
    //MARK: - URLS
    static func endPoint(base : String) -> String {
        return base + sourceID + "." + Global.vpnDomain
    }
    
    static var remoteIdentifier : String {
        return "www" + sourceID + "." + "confirmedvpn.com"
    }
    
    static var vpnDomain : String {
        return "confirmedvpn.com"
    }
    
    static var masterURL : String {
        get {
            return "https://v3." + Global.vpnDomain
        }
    }
    
    static var createUserURL : String {
        get {
            UserDefaults.standard.set(APIVersionType.v3API, forKey: Global.kConfirmedAPIVersion) //all new users are v2
            UserDefaults.standard.synchronize()
            NotificationCenter.post(name: .switchingAPIVersions)
            return Global.masterURL + "/signup"
        }
    }
    
    static var getIPURL : String {
        return "https://ip.confirmedvpn.com/ip" //no support on v1/v2
    }
    static var getSpeedTestBucket : String {
        return "https://v3.confirmedvpn.com/download-speed-test"
    }
    
    static var signinURL : String {
        get {
            return Global.masterURL + "/signin"
        }
    }
    static var activeSubscriptionInformationURL : String {
        get {
            return Global.masterURL + "/active-subscriptions"
        }
    }
    static var subscriptionInformationURL : String {
        get {
            return Global.masterURL + "/subscriptions"
        }
    }
    static var subscriptionReceiptUploadURL : String {
        get {
            return Global.masterURL + "/subscription-event"
        }
    }
    static var getKeyURL : String {
        get {
            return Global.masterURL + "/get-key"
        }
    }
    static var forgotPasswordURL : String {
        get {
            return Global.masterURL + "/forgot-password"
        }
    }
    static var addEmailToUserURL : String {
        get {
            UserDefaults.standard.set(APIVersionType.v3API, forKey: Global.kConfirmedAPIVersion)
            UserDefaults.standard.synchronize() //all new users are v3
            NotificationCenter.post(name: .switchingAPIVersions)
            return Global.masterURL + "/convert-shadow-user"
        }
    }
    static var paymentURL : String {
        get {
            return Global.masterURL + "/new-subscription" + "?type=mac" + "&plan=all-monthly"
        }
    }
    
    
    /*
     * keychain key declaration
     * attach prefix based on version to prevent incorrect value for api server
     */
    //MARK: - KEYCHAIN KEYS
    static let vpnName = "Confirmed VPN"
    static let kICloudContainer = "iCloud.com.confirmed.tunnels"
    static let kOpenTunnelRecord = "OpenTunnelRemotely"
    static let kCloseTunnelRecord = "CloseTunnelRemotely"
    
    static func apiVersionPrefix() -> APIVersionType {
        if Global.isVersion(version: .v1API) {
            return APIVersionType.v1API
        }
        if Global.isVersion(version: .v2API) {
            return APIVersionType.v2API
        }
        return APIVersionType.v3API
    }
    
    static var vpnSavedRegionKey : String { get { return apiVersionPrefix() + "savedRegion-universal" }}
    static var kConfirmedP12Key : String { get { return apiVersionPrefix() + "TunnelsP12" }}
    static var kConfirmedPrivateKey : String { get { return apiVersionPrefix() + "TunnelsPrivateKey" }}
    static var kConfirmedCACertKey : String { get { return apiVersionPrefix() + "TunnelsCACert" }}
    static var kConfirmedCLCertKey : String { get { return apiVersionPrefix() + "TunneCLCert" }}
    static var kConfirmedID : String { get { return apiVersionPrefix() + "TunnelsID" }}
    static var kConfirmedEmail : String { get { return apiVersionPrefix() + "TunnelsEmail" }}
    static var kConfirmedPassword : String { get { return apiVersionPrefix() + "TunnelsPassword" }}
    static var kConfirmedReceiptKey : String { get { return apiVersionPrefix() + "TunnelsReceipt" }}
    static var kPartnerCode = "PartnerCode"
    static var kLastEnvironment = "lastEnvironment"
    static let kPlatformiOS = "ios"
    static let kPlatformMac = "mac"
    static let kPartnerCodePasteboardType = "com.confirmed.tunnels.PartnerCode"
    static let kConfirmedUniquePartnerCode = "266347633"

    static let kConfirmedAPIVersion = "API-Version"
    
    static let contentBlockerBundleID = "com.confirmed.tunnels.Confirmed-Blocker"
    
    //MARK: - URLS (macOS ONLY)
    static let kPaymentAcceptedURL = "tunnels://stripesuccess"
    static let kEmailConfirmedURL = "tunnels://emailconfirmed"
    
    
    //**********************************************************
    //NOTIFICATIONS
    //**********************************************************
    //MARK: - NOTIFICATIONS
    static let fetchingP12Notification = "ConfirmFetchingP12Notification"
    static let kInternetConnectionLost = -1005
    static let kInternetDownError = -1009
    static let kServerDownError = -1004
    static let kServerTimedOutError = -1001
    static let kStreamError = -2102
    
    static let kNoError = 0
    static let kEmailNotConfirmed = 1
    static let kIncorrectLogin = 2
    static let kRequestFieldValidationError = 3
    static let kMobileSubscriptionOnly = 38
    static let kEmailAlreadyUsed = 40
    static let kReceiptAlreadyUsed = 48
    static let kMissingPaymentErrorCode = 6
    static let kInvalidAuth = 401
    static let kTooManyRequests = 999
    static let kUnknownError = 99999
    
    static func errorMessageForError(eCode : Int) -> String {
        if let errorMessage = kAuthErrorCodes[eCode] {
            return errorMessage
        }
        
        return kAuthErrorCodes[Global.kUnknownError]!
    }
    
    private static var kAuthErrorCodes = [ kEmailNotConfirmed : "Please check your e-mail for a confirmation link.",
                                   kRequestFieldValidationError : "Invalid field.",
                                   kInvalidAuth : "Incorrect login.",
                                   kIncorrectLogin : "Incorrect login.",
                                   kMobileSubscriptionOnly : "Please upgrade from mobile only at https://confirmedvpn.com",
                                   kEmailAlreadyUsed : "This e-mail is already registered to a user.",
                                   kReceiptAlreadyUsed : "Your account is already associated with another email.",
                                   kUnknownError : "Unknown error."
    ]
    
    //MARK: - USER DEFAULTS
    static let kAdBlockingEnabled = "AdBlockingEnabled" //content blocker: should block ads
    static let kScriptBlockingEnabled = "PrivacyBlockingEnabled" //content blocker: should block tracking scripts
    static let kSocialBlockingEnabled = "SocialBlockingEnabled" //content blocker: should block social domains
    static let kUserWhitelistedDomains = "whitelisted_domains_user" //customized whitelisted domains from user
    static let kConfirmedWhitelistedDomains = "whitelisted_domains" //default whitelisted domains from Confirmed Team
    static let kConfirmedLockdownDomains = "lockdown_domains"
    static let kUserLockdownDomains = "lockdown_domains_user"
    
    static let kIsLastStateConnected = "Connected" //track last selected state from user
    static let kConnectOnLaunch = "ConnectOnLaunch" //should VPN connect on launch
    static let kForceVPNOnMac = "ForceVPNOn" //prevents any traffic from processing outside the VPN (except whitelisted sites)
    
    static let kIsOnFinalDeprecatedV1V2 = "IsOnFinalDeprecatedV1V2" //for old users, moving to v1/v2 on .co to keep launch environment clean
    
    
    static func sharedUserDefaults() -> UserDefaults {
        return UserDefaults(suiteName: CoreUtils.userDefaultsSuite)!
    }
    
    
    static let accountText = "Account".localized()
    static let helpText = "Help".localized()
    static let privacyText = "Privacy".localized()
    static let benefitsText = "Benefits".localized()
    static let speedTestText = "Speed Test".localized()
    static let installWidgetText = "Install Widget".localized()
    static let whitelistingText = "Whitelisting".localized()
    static let contentBlockerText = "Content Blocker".localized()
    
    static let disconnectingText = "Deactivating...".localized()
    static let connectingText = "Activating...".localized()
    static let disconnectedText = "Not Activated".localized()
    static let protectedText = "Activated".localized()
    
    static let ipAddressHidden = "IP Address Hidden".localized()
    static let ipAddressVisible = "IP Address Visible".localized()
    static let ipAddressInformation = "Your IP address is a uniquely identifiable number to track your activities. Confirmed masks this number to let you browse anonymously.".localized()
    
    static let encryptedTraffic = "Encrypted Traffic".localized()
    static let unencryptedTraffic = "Some Unencrypted Traffic".localized()
    static let encryptedInformation = "Confirmed uses 256-bit encryption to prevent snoopers and ISPs from viewing your data or browsing history.".localized()
    
    static let blockAds = "Block Ads".localized()
    static let allowAds = "Ads Allowed".localized()
    static let adInformation = "Confirmed provides a Content Blocker to speed up your Internet and prevent obtrusive ads from ruining your Internet experience.".localized()
    
    static let trackingScriptsBlocked = "Tracking Scripts Blocked".localized()
    static let trackingScriptsEnabled = "Tracking Scripts Enabled".localized()
    static let trackingScriptsInformation = "Many websites include tracking scripts from Facebook, Google, and other sites that allow companies to track you across the Internet. Confirmed's Content Blocker removes these scripts, allowing you to have a privacy-focused experience.".localized()
    
    static let vpnSetupDescription = "Your traffic is now encrypted with bank-level 256-bit encryption and your uniquely identifiable IP address is hidden to protect your privacy.".localized()
    
    static let blockTrackingScripts = "Block Tracking Scripts".localized()
    static let blockSocialTrackers = "Block Social Trackers".localized()
    
    static let monthly = "Monthly".localized()
    static let annual = "Annual".localized()
    
}

public typealias APIVersionType = String

extension APIVersionType {
    static let v1API = "v1"
    static let v2API = "v2"
    static let v3API = "v3"
}

#if os(iOS)
    extension UIImage {
        static let questionIcon = UIImage.init(named: "question_mark")?.withRenderingMode(.alwaysTemplate)
        static let privacyIcon = UIImage.init(named: "privacy_policy")?.withRenderingMode(.alwaysTemplate)
        static let informationIcon = UIImage.init(named: "information_icon")?.withRenderingMode(.alwaysTemplate)
        static let lightningIconThick = UIImage.init(named: "lightning_icon_thick")?.withRenderingMode(.alwaysTemplate)
        static let installIcon = UIImage.init(named: "install_icon")?.withRenderingMode(.alwaysTemplate)
        static let checkIcon = UIImage.init(named: "checkmark")?.withRenderingMode(.alwaysTemplate)
        static let blockIcon = UIImage.init(named: "block_icon")?.withRenderingMode(.alwaysTemplate)
        static let accountIcon = UIImage.init(named: "account_icon")?.withRenderingMode(.alwaysTemplate)
        static let powerIconPadded = UIImage(named: "power_button_padded")?.withRenderingMode(.alwaysTemplate)
    }
    
    extension UIColor {
        static let tunnelsBlueColor = UIColor.init(red: 0/255.0, green: 173/255.0, blue: 231/255.0, alpha: 1.0)
        static let tunnelsLightBlueColor = UIColor.init(red: 0/255.0, green: 173/255.0, blue: 231/255.0, alpha: 1.0)
        static let tunnelsErrorColor = UIColor.init(red: 200/255.0, green: 20.0/255.0, blue: 20/255.0, alpha: 1.0)
    }
    
#elseif os(OSX)
    extension NSImage {
        static let checkmarkIcon = NSImage.init(named: NSImage.Name(rawValue: "checkmark"))
        static let blockIcon = NSImage.init(named: NSImage.Name(rawValue: "block_icon"))
        static let statusBarIcon = NSImage(named: NSImage.Name(rawValue: "StatusBarImage"))
        static let statusBarIconDisabled = NSImage(named: NSImage.Name(rawValue: "status_bar_image_disabled"))
        static let settingsIcon = NSImage(named: NSImage.Name(rawValue: "settings_icon"))
        static let powerIcon = NSImage(named: NSImage.Name(rawValue: "power_button"))
        static let downArrow = NSImage.init(named: NSImage.Name(rawValue: "down_arrow"))
        static let downArrowWhite = NSImage.init(named: NSImage.Name(rawValue: "down_arrow_white"))
        static let upArrow = NSImage.init(named: NSImage.Name(rawValue: "up_arrow"))
        static let upArrowWhite = NSImage.init(named: NSImage.Name(rawValue: "up_arrow_white"))
    }
    
    extension NSColor {
        static let tunnelsBlueColor = NSColor.init(red: 0/255.0, green: 173/255.0, blue: 231/255.0, alpha: 1.0)
        static let tunnelsLightBlueColor = NSColor.init(red: 0/255.0, green: 173/255.0, blue: 231/255.0, alpha: 1.0)
        static let tunnelsErrorColor = NSColor.init(red: 200/255.0, green: 20.0/255.0, blue: 20/255.0, alpha: 1.0)
    }
#endif

//Server location structure
struct ServerMetadata {
    var countryName: String
    var flagImagePath: String
    var countryCode: String
}

//Response fields from server
struct ServerResponse:Codable {
    
    let code : Int?
    let message : String?
    let b64 : String?
    let id : String?
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
        case b64
        case id
    }
}

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}
