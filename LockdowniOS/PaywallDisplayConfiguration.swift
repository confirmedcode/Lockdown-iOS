//
//  PaywallDisplayConfiguration.swift
//  LockdowniOS
//
//  Created by Alexander Parshakov on 12/13/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation

struct PaywallDisplayConfiguration {
    
    /// For how long it's necessary to wait to show the paywall again.
    let lapseDuration: Int
    
    /// In what units the time is calculated.
    let lapseUnit: Calendar.Component
    
    static let `default`: Self = {
        #if DEBUG
            return .init(lapseDuration: 20, lapseUnit: .second)
        #else
            return .init(lapseDuration: 72, lapseUnit: .hour)
        #endif
    }()
}

extension Calendar {
    static func hasExceededLapse(between firstDate: Date, and secondDate: Date, for configuration: PaywallDisplayConfiguration = .default) -> Bool {
        let components = Calendar.current.dateComponents([configuration.lapseUnit],
                                                              from: firstDate,
                                                              to: secondDate)
        
        guard let lapse = components.value(for: configuration.lapseUnit) else { return false }
        
        return abs(lapse) > configuration.lapseDuration
    }
}
