//
//  ArrayRestrictable.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/28/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation

@propertyWrapper
struct PositiveAndArrayRestricted {
    
    var arrayCount: Int = 0
    
    private var value: Int
    
    var wrappedValue: Int {
        get { return max(0, value) }
        set { value = min(newValue, arrayCount - 1) }
    }
    
    init(defaultValue: Int) {
        value = defaultValue
    }
}
