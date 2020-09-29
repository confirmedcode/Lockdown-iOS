//
//  VPNRegion.swift
//  LockdowniOS
//
//  Created by Oleg Dreyman on 28.09.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation

// MARK: - VPN Region

let kSavedVPNRegionServerPrefix = "vpn_region_server_prefix"

struct VPNRegion {
    var regionDisplayName: String = ""
    var regionDisplayNameShort: String = ""
    var regionFlagEmoji: String = ""
    var serverPrefix: String = ""
}

let vpnRegions:[VPNRegion] = [
    VPNRegion(regionDisplayName: NSLocalizedString("United States - West", comment: ""),
              regionDisplayNameShort: NSLocalizedString("USA West", comment: ""),
              regionFlagEmoji: "🇺🇸",
              serverPrefix: "us-west"),
    VPNRegion(regionDisplayName: NSLocalizedString("United States - East", comment: ""),
              regionDisplayNameShort: NSLocalizedString("USA East", comment: ""),
              regionFlagEmoji: "🇺🇸",
              serverPrefix: "us-east"),
    VPNRegion(regionDisplayName: NSLocalizedString("United Kingdom", comment: ""),
              regionDisplayNameShort: NSLocalizedString("United Kingdom", comment: ""),
              regionFlagEmoji: "🇬🇧",
              serverPrefix: "eu-london"),
    VPNRegion(regionDisplayName: NSLocalizedString("France", comment: ""),
              regionDisplayNameShort: NSLocalizedString("France", comment: ""),
              regionFlagEmoji: "🇫🇷",
              serverPrefix: "eu-paris"),
    VPNRegion(regionDisplayName: NSLocalizedString("Ireland", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Ireland", comment: ""),
              regionFlagEmoji: "🇮🇪",
              serverPrefix: "eu-ireland"),
    VPNRegion(regionDisplayName: NSLocalizedString("Germany", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Germany", comment: ""),
              regionFlagEmoji: "🇩🇪",
              serverPrefix: "eu-frankfurt"),
    VPNRegion(regionDisplayName: NSLocalizedString("Canada", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Canada", comment: ""),
              regionFlagEmoji: "🇨🇦",
              serverPrefix: "canada"),
    VPNRegion(regionDisplayName: NSLocalizedString("India", comment: ""),
              regionDisplayNameShort: NSLocalizedString("India", comment: ""),
              regionFlagEmoji: "🇮🇳",
              serverPrefix: "ap-mumbai"),
    VPNRegion(regionDisplayName: NSLocalizedString("Japan", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Japan", comment: ""),
              regionFlagEmoji: "🇯🇵",
              serverPrefix: "ap-tokyo"),
    VPNRegion(regionDisplayName: NSLocalizedString("Australia", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Australia", comment: ""),
              regionFlagEmoji: "🇦🇺",
              serverPrefix: "ap-sydney"),
    VPNRegion(regionDisplayName: NSLocalizedString("South Korea", comment: ""),
              regionDisplayNameShort: NSLocalizedString("South Korea", comment: ""),
              regionFlagEmoji: "🇰🇷",
              serverPrefix: "ap-seoul"),
    VPNRegion(regionDisplayName: NSLocalizedString("Singapore", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Singapore", comment: ""),
              regionFlagEmoji: "🇸🇬",
              serverPrefix: "ap-singapore"),
    VPNRegion(regionDisplayName: NSLocalizedString("Brazil", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Brazil", comment: ""),
              regionFlagEmoji: "🇧🇷",
              serverPrefix: "sa")
]

func getVPNRegionForServerPrefix(serverPrefix: String) -> VPNRegion {
    for vpnRegion in vpnRegions {
        if vpnRegion.serverPrefix == serverPrefix {
            return vpnRegion
        }
    }
    return vpnRegions[0]
}

func getSavedVPNRegion() -> VPNRegion {
    if let savedVPNRegionServerPrefix = defaults.string(forKey: kSavedVPNRegionServerPrefix) {
        return getVPNRegionForServerPrefix(serverPrefix: savedVPNRegionServerPrefix)
    }
    
    // get default savedRegion by locale
    let locale = NSLocale.autoupdatingCurrent
    if let regionCode = locale.regionCode {
        switch regionCode {
        case "US":
            if let timezone = TimeZone.autoupdatingCurrent.abbreviation() {
                if timezone == "EST" || timezone == "EDT" || timezone == "CST" {
                    return getVPNRegionForServerPrefix(serverPrefix: "us-east")
                }
            }
            else {
                return getVPNRegionForServerPrefix(serverPrefix: "us-west")
            }
        case "FR", "PT":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-paris")
        case "GB":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-london")
        case "IE":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-london")
        case "CA":
            return getVPNRegionForServerPrefix(serverPrefix: "canada")
        case "KO":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-seoul")
        case "ID", "SG", "MY", "PH", "TH", "TW", "VN":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-singapore")
        case "DE", "IT", "ES", "AT", "PL", "RU", "UA", "NG", "TR", "ZA":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-frankfurt")
        case "AU", "NZ":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-sydney")
        case "AE", "IN", "PK", "BD", "QA", "SA":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-mumbai")
        case "EG":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-frankfurt")
        case "JP":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-tokyo")
        case "BR", "CO", "VE", "AR":
            return getVPNRegionForServerPrefix(serverPrefix: "sa")
        default:
            return vpnRegions[0]
        }
    }
    return vpnRegions[0]
}

func setSavedVPNRegion(vpnRegion: VPNRegion) {
    defaults.set(vpnRegion.serverPrefix, forKey: kSavedVPNRegionServerPrefix)
}
