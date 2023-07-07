//
//  CodableUserDefaults.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 6.07.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import CocoaLumberjackSwift
import Foundation

@propertyWrapper
struct CodableUserDefaults<T: Codable> {
    private let key: String
    private let defaultValue: T?
    private let isLogged: Bool
    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(
        key: String,
        defaultValue: T? = nil,
        isLogged: Bool = false,
        userDefaults: UserDefaults = UserDefaults(
            suiteName: LockdownStorageIdentifier.userDefaultsId
        )!,
        decoder: JSONDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.isLogged = isLogged
        self.userDefaults = userDefaults
        self.decoder = decoder
        self.encoder = encoder
    }
    
    var wrappedValue: T? {
        get {
            guard let data = userDefaults.object(forKey: key) as? Data,
                  let value = try? decoder.decode(T.self, from: data) else {
                return defaultValue
            }
            if isLogged {
                DDLogInfo("Reading UserDefaults.\(key) of value \(value).")
            }
            return value
        }
        set {
            guard let newValue,
                  let data = try? encoder.encode(newValue) else {
                userDefaults.removeObject(forKey: key)
                return
            }
            
            if isLogged {
                DDLogInfo("Setting UserDefaults.\(key) value as \(newValue).")
            }
            userDefaults.set(data, forKey: key)
        }
    }
}
