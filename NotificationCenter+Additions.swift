//
//  NotificationCenter+Additions.swift
//  
//
//

import Foundation


extension Notification.Name {
    static let setupVPN = Notification.Name("Setup VPN")
    static let showContentBlocker = Notification.Name("Show Content Blocker")
    static let internetDownNotification = Notification.Name("ConfirmGlobal.internetDownNotification")
    static let dismissOnboarding = Notification.Name("Dismiss Onboarding")
    static let userSignedIn = Notification.Name("User Signed In")
    static let changeCountry = Notification.Name("Change Country")
    static let showAccount = Notification.Name("Show Account")
    static let askForHelp = Notification.Name("Ask For Help")
    static let showPrivacyPolicy = Notification.Name("Show Privacy Policy")
    static let showTutorial = Notification.Name("Show Tutorial")
    static let runSpeedTest = Notification.Name("Run Speed Test")
    static let installWidget = Notification.Name("Install Widget")
    static let showWhitelistDomains = Notification.Name("Show White Listing Domain")
    static let eulaPolicyAgreed = Notification.Name("EULA Policy Agreed")
    static let eulaPolicyDisagreed = Notification.Name("EULA Policy Disagreed")
    static let removeEULA = Notification.Name("Remove EULA")
    static let switchingAPIVersions = Notification.Name("Switching API Versions")
    static let vpnStatusChanged = Notification.Name("ConfirmedVPNStatusChanged")
    static let appActive = Notification.Name("AppActive")
    
}


extension NotificationCenter {
    static func post(name : NSNotification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}
