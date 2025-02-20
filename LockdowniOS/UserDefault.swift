//
//  UserDefault.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import CocoaLumberjackSwift
import Foundation

@propertyWrapper
struct UserDefault<T> {
    private let key: String
    private let defaultValue: T
    private let isLogged: Bool
    private let userDefaults: UserDefaults

    init(_ key: String, defaultValue: T,
         isLogged: Bool = false,
         userDefaults: UserDefaults = UserDefaults(suiteName: LockdownStorageIdentifier.userDefaultsId)!) {
        self.key = key
        self.defaultValue = defaultValue
        self.isLogged = isLogged
        self.userDefaults = userDefaults
    }

    var wrappedValue: T {
        get {
            let value = userDefaults.object(forKey: key) as? T ?? defaultValue
            if isLogged {
                DDLogInfo("Reading UserDefaults.\(key) of value \(value).")
            }
            return value
        }
        set {
            if isLogged {
                DDLogInfo("Setting UserDefaults.\(key) value as \(newValue).")
            }
            userDefaults.set(newValue, forKey: key)
        }
    }
}

extension UserDefaults {
    
    @UserDefault("homeScreenLastPaywallDisplayDate", defaultValue: Date(), isLogged: true)
    static var lastPaywallDisplayDate
    
    @UserDefault("hasSeenPaywallOnHomeScreen", defaultValue: false, isLogged: true)
    static var hasSeenPaywallOnHomeScreen
    
    @UserDefault("hasSeenLTO", defaultValue: false, isLogged: true)
    static var hasSeenLTO
    
    @UserDefault("hasSeenAdvancedPaywall", defaultValue: false, isLogged: true)
    static var hasSeenAdvancedPaywall
    
    @UserDefault("hasSeenAnonymousPaywall", defaultValue: false, isLogged: true)
    static var hasSeenAnonymousPaywall
    
    @UserDefault("hasSeenUniversalPaywall", defaultValue: false, isLogged: true)
    static var hasSeenUniversalPaywall
    
    @UserDefault("hasSeenStartupOneTimeOffer", defaultValue: false, isLogged: true)
    static var hasSeenStartupOneTimeOffer
    
    @UserDefault("onboardingCompleted", defaultValue: false, isLogged: true)
    static var onboardingCompleted
}

// MARK: - Content Blocker

extension UserDefaults {
    struct ContentBlocking {
        
        @UserDefault("hasSeenContentBlockerPageBefore", defaultValue: false)
        static var hasSeenContentBlockerPageBefore
        
        @UserDefault("AdBlockingEnabled", defaultValue: true)
        static var adBlockingEnabled
        
        @UserDefault("PrivacyBlockingEnabled", defaultValue: true)
        static var privacyBlockingEnabled
        
        @UserDefault("SocialBlockingEnabled", defaultValue: true)
        static var socialBlockingEnabled
    }
}

