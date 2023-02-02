//
//  FreemiumMigrationService.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/8/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation
import TPInAppReceipt

protocol FreemiumMigrationService: AnyObject {
    var freemiumMigrationAppVersion: Int { get set }
    
    var isMigratedUser: Bool { get }
    
    func register(freemiumMigrationAppVersion: Int)
}

extension FreemiumMigrationService {
    func register(freemiumMigrationAppVersion: Int) {
        self.freemiumMigrationAppVersion = freemiumMigrationAppVersion
    }
}

final class BaseFreemiumMigrationService: FreemiumMigrationService {
    
    static let shared = BaseFreemiumMigrationService()
    
    var freemiumMigrationAppVersion: Int = 1000
    
    var isMigratedUser: Bool {
            do {
                let receipt = try InAppReceipt()
                try receipt.validate()
                
                let originalBuildVersion = Int(receipt.originalAppVersion)
                
                if let originalBuildVersion = originalBuildVersion,
                   originalBuildVersion < freemiumMigrationAppVersion {
                    return true
                }
                
                return false
                
            } catch {
                return false
            }
        }
}
