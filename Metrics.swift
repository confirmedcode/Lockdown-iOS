//
//  Metrics.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 28.09.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation

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

func getTotalEnabledMetrics() -> Int {
    return defaults.integer(forKey: kTotalEnabledMetrics)
}

func getTotalEnabledString() -> String {
    return metricsToString(metric: getTotalEnabledMetrics())
}

func getTotalDisabledMetrics() -> Int {
    return defaults.integer(forKey: kTotalDisabledMetrics)
}

func getTotalDisabledString() -> String {
    return metricsToString(metric: getTotalDisabledMetrics())
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
