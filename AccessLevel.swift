//
//  AccessLevel.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import Foundation

enum AccessLevel: Int, CaseIterable {
    case basic
    case advanced
    case anonymous
    case universal
    
    func hasFeature() -> Bool {
        return true
    }
}
