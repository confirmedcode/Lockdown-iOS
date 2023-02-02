//
//  UserDefault.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/6/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
//

import CocoaLumberjackSwift
import Foundation

@propertyWrapper
struct UserDefault<T> {
    private let key: String
    private let defaultValue: T
    private let userDefaults: UserDefaults

    init(_ key: String, defaultValue: T, userDefaults: UserDefaults = UserDefaults(suiteName: "group.com.confirmed")!) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    var wrappedValue: T {
        get {
            let value = userDefaults.object(forKey: key) as? T ?? defaultValue
            DDLogInfo("Reading UserDefaults.\(key) of value \(value).")
            return value
        }
        set {
            DDLogInfo("Setting UserDefaults.\(key) value as \(newValue).")
            userDefaults.set(newValue, forKey: key)
        }
    }
}

extension UserDefaults {
    
    @UserDefault("homeScreenLastPaywallDisplayDate", defaultValue: Date())
    static var lastPaywallDisplayDate
    
    @UserDefault("hasSeenPaywallOnHomeScreen", defaultValue: false)
    static var hasSeenPaywallOnHomeScreen
    
    @UserDefault("hasSeenLTO", defaultValue: false)
    static var hasSeenLTO
}
