//
//  Keychainable.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/18/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import KeychainAccess

protocol Keychainable: AnyObject {
    func saveKeychainBool(_ item: KeychainBoolItem, _ bool: Bool, keychain: Keychain)
    func readKeychainBool(_ item: KeychainBoolItem, keychain: Keychain) -> Bool
}
    
extension Keychainable {
     private static var defaultKeychain: Keychain { Keychain(service: "com.confirmed.tunnels").synchronizable(true) }

     func saveKeychainBool(_ item: KeychainBoolItem, _ bool: Bool, keychain: Keychain = Self.defaultKeychain) {
         do {
             try keychain.set(String(bool), key: item.rawValue)
         } catch let error {
             print(error)
         }
     }

     func readKeychainBool(_ item: KeychainBoolItem, keychain: Keychain = Self.defaultKeychain) -> Bool {
         do {
             let value: String = try keychain.get(item.rawValue) ?? ""
             return Bool(value) ?? false
         } catch let error {
             print(error)
             return false
         }
     }
 }

 enum KeychainBoolItem: String {
     case hasSeenXmasLTO
 }
