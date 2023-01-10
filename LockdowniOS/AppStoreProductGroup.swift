//
//  AppStoreProductGroup.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/10/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
//

import Foundation
import UIKit

enum AppStoreProductGroup: Int, CaseIterable {
    case firewallAndVpn
    case pro
    
    func hasFeature(_ feature: PaywallTableFeature) -> Bool {
        switch self {
        case .firewallAndVpn:
            return [
                .stopsAdsAndTrackers,
                .blocksBadware,
                .accessCuratedBlockLists,
                .buildCustomBlockLists,
                .stopsBrowsingHistoryTracking,
                .anonymizingBrowsing,
                .hidesLocation,
                .letsYouChangeIP,
                .appForPhoneAndIpad
            ].contains(feature)
        case .pro:
            return [PaywallTableFeature].allDefaultFeatures.contains(feature)
        }
    }
}
