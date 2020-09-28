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

func getDayMetricsString() -> String {
    return metricsToString(metric: getDayMetrics())
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

func metricsToString(metric : Int) -> String {
    if metric < 1000 {
        return "\(metric)"
    }
    else if metric < 1000000 {
        return "\(Int(metric / 1000))k"
    }
    else {
        return "\(Int(metric / 1000000))m"
    }
}

enum Metrics {
    
}
