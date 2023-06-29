//
//  SelectRegionViewModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 28.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import Foundation

class SelectRegionViewModel: BaseSelectCountryViewModel, SelectCountryViewModelProtocol {
    var title: String {
        NSLocalizedString("Select Region", comment: "")
    }
    
    override func generateCountryList() -> [Country] {
        vpnRegions.map {
            Country(
                title: $0.regionDisplayName,
                emojiSymbol: $0.regionFlagEmoji
            )
        }
    }
}
