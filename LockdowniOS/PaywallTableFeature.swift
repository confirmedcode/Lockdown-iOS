//
//  PaywallTableFeature.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/3/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation

/// Used for features in the table of TablePaywallViewController
struct PaywallTableFeature {
    
    let body: String
    
    let isAvailableForFree: Bool
    
    let isAvailableOnVPN: Bool
    
    /// All features are available on PRO, so the default value is true.
    let isAvailableOnPro: Bool
    
    init(body: String, isAvailableForFree: Bool, isAvailableOnVPN: Bool, isAvailableOnPro: Bool = true) {
        self.body = body
        self.isAvailableForFree = isAvailableForFree
        self.isAvailableOnVPN = isAvailableOnVPN
        self.isAvailableOnPro = isAvailableOnPro
    }
    
    // MARK: - Features
    
    static let stopsAdsAndTrackers: Self = {
        .init(body: .localized("stops_ads_and_hidden_trackers"), isAvailableForFree: true, isAvailableOnVPN: true)
    }()
    
    static let blocksBadware: Self = {
        .init(body: .localized("blocks_badware_in_all_your_apps"), isAvailableForFree: true, isAvailableOnVPN: true)
    }()
    
    static let accessCuratedBlockLists: Self = {
        .init(body: .localized("access_our_curated_block_lists"), isAvailableForFree: true, isAvailableOnVPN: true)
    }()
    
    static let buildCustomBlockLists: Self = {
        .init(body: .localized("build_your_custom_block_lists"), isAvailableForFree: true, isAvailableOnVPN: true)
    }()
    
    static let stopsBrowsingHistoryTracking: Self = {
        .init(body: .localized("stops_browsing_history_tracking"), isAvailableForFree: false, isAvailableOnVPN: true)
    }()
    
    static let anonymizingBrowsing: Self = {
        .init(body: .localized("anonymizing_your_browsing"), isAvailableForFree: false, isAvailableOnVPN: true)
    }()
    
    static let hidesLocation: Self = {
        .init(body: .localized("hides_your_location_and_ip"), isAvailableForFree: false, isAvailableOnVPN: true)
    }()
    
    static let letsYouChangeIP: Self = {
        .init(body: .localized("lets_you_change_your_ip_to_other_region"), isAvailableForFree: false, isAvailableOnVPN: true)
    }()
    
    static let appForPhoneAndIpad: Self = {
        .init(body: .localized("app_for_iphone_plus_ipad"), isAvailableForFree: false, isAvailableOnVPN: true)
    }()
    
    static let appForMac: Self = {
        .init(body: .localized("app_for_mac"), isAvailableForFree: false, isAvailableOnVPN: false)
    }()
}

extension PaywallTableFeature: Equatable {}

extension Array where Element == PaywallTableFeature {
    static let allDefaultFeatures: Self = {
        return [
            .stopsAdsAndTrackers,
            .blocksBadware,
            .accessCuratedBlockLists,
            .buildCustomBlockLists,
            .stopsBrowsingHistoryTracking,
            .anonymizingBrowsing,
            .hidesLocation,
            .letsYouChangeIP,
            .appForPhoneAndIpad,
            .appForMac
        ]
    }()
}
