//
//  Environment.swift
//  Lockdown
//
//  Created by Johnny Lin on 8/9/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift

// getEnvironmentVariable(key: "vpnSourceID", default: "-111818")
let vpnSourceID: String = {
    #if DEBUG
        return "-111618"
    #else
        return "-111818"
    #endif
}()

// getEnvironmentVariable(key: "vpnDomain", default: "confirmedvpn.com")
let vpnDomain: String = {
    #if DEBUG
        return "trusty-ap.science"
    #else
        return "confirmedvpn.com"
    #endif
}()

let vpnRemoteIdentifier = "www" + vpnSourceID + "." + vpnDomain

// getEnvironmentVariable(key: "mainDomain", default: "confirmedvpn.com")
let mainDomain: String = {
    #if DEBUG
        return "trusty-ap.science"
    #else
        return "confirmedvpn.com"
    #endif
}()

let mainURL = "https://www." + mainDomain

let testFirewallDomain = "example.com"

let lastVersionToAskForRating = "024"

func getEnvironmentVariable(key: String, default: String) -> String {
    if let value = ProcessInfo.processInfo.environment[key] {
        return value
    }
    else {
        DDLogError("ERROR: Could not find environment variable key \(key)")
        return ""
    }
}
