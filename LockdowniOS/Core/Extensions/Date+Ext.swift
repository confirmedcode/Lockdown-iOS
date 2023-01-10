//
//  Date+Ext.swift
//  LockdowniOS
//
//  Created by Alexander Parshakov on 12/17/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation

extension Date {
    
    static let xmasStart: Date = .from(year: 2022, month: 12, day: 10)
    static let xmasEnd: Date = .from(year: 2023, month: 1, day: 6)
    
    static let halloweenStart: Date = .from(year: 2023, month: 10, day: 20)
    static let halloweenEnd: Date = .from(year: 2023, month: 10, day: 31)
    
    static let thanksgivingStart: Date = .from(year: 2023, month: 11, day: 23)
    static let thanksgivingEnd: Date = .from(year: 2023, month: 11, day: 30)
    
    static func from(year: Int, month: Int, day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.timeZone = TimeZone(abbreviation: "GMT")

        let userCalendar = Calendar(identifier: .gregorian) // since the components above (like year 1980) are for Gregorian
        return userCalendar.date(from: dateComponents) ?? Date()
    }
}
