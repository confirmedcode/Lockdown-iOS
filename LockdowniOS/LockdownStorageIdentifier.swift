//
//  LockdownStorageIdentifier.swift
//  LockdowniOS
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

public struct LockdownStorageIdentifier {
    
    private init() {}
    
    static let keychainId = "com.confirmed.tunnels"
    static let userDefaultsId = "group.com.confirmed"
    static let contentBlockerId = "com.confirmed.lockdown.Confirmed-Blocker"
}
