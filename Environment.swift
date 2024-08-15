//
//  Environment.swift
//  Lockdown
//
//  Created by Johnny Lin on 8/9/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift


//Prod Environment
//let vpnSourceID = "-111818" //getEnvironmentVariable(key: "vpnSourceID", default: "-111818")
//let vpnDomain = "confirmedvpn.com" //getEnvironmentVariable(key: "vpnDomain", default: "confirmedvpn.com")
//let vpnRemoteIdentifier = "www" + vpnSourceID + "." + vpnDomain
//let mainDomain = "confirmedvpn.com" //getEnvironmentVariable(key: "mainDomain", default: "confirmedvpn.com")
//let mainURL = "https://www." + mainDomain

// Dev Environment
// US-East US-West
let vpnSourceID = "-111618"
let vpnDomain = "trusty-ap.science"
let vpnRemoteIdentifier = "www" + vpnSourceID + "." + vpnDomain
let mainDomain = "trusty-ap.science"
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
