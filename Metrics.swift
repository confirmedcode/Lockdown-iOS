//
//  Metrics.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 28.09.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation

let kDayMetrics = "LockdownDayMetrics"
let kWeekMetrics = "LockdownWeekMetrics"
let kTotalMetrics = "LockdownTotalMetrics"

let kActiveDay = "LockdownActiveDay"
let kActiveWeek = "LockdownActiveWeek"

func getDayMetrics() -> Int {
    return defaults.integer(forKey: kDayMetrics)
}

func getDayMetricsString(commas: Bool = false) -> String {
    return metricsToString(metric: getDayMetrics(), commas: commas)
}

func getWeekMetrics() -> Int {
    return defaults.integer(forKey: kWeekMetrics)
}

func getWeekMetricsString() -> String {
    return metricsToString(metric: getWeekMetrics())
}

func getTotalMetrics() -> Int {
    return defaults.integer(forKey: kTotalMetrics)
}

func getTotalMetricsString() -> String {
    return metricsToString(metric: getTotalMetrics())
}

func metricsToString(metric : Int, commas: Bool = false) -> String {
    if (commas) {
        let commasFormatter = NumberFormatter()
        commasFormatter.numberStyle = .decimal
        guard let formattedNumber = commasFormatter.string(from: NSNumber(value: metric)) else { return "\(metric)" }
        return formattedNumber
    }
    if metric < 1000 {
        return "\(metric)"
    }
    else if metric < 1000000 {
        return "\(Int(metric / 1000))k"
    }
    else {
        return "\(String(format: "%.2f", (Double(metric) / Double(1000000))))m"
    }
}

enum Metrics {
    
}
