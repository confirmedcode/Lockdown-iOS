//
//  SelectCountryViewModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 27.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import Foundation

class SelectCountryViewModel: BaseSelectCountryViewModel, SelectCountryViewModelProtocol {
    var title: String {
        NSLocalizedString("Select country", comment: "")
    }
    
    override func generateCountryList() -> [Country] {
        if #available(iOS 16, *) {
            return Locale.Region.isoRegions.filter { $0.subRegions.isEmpty } .map { region in
                Country(
                    title: Locale.current.localizedString(forRegionCode: region.identifier) ?? "",
                    emojiSymbol: emojiFlag(for: region.identifier)
                )
            }.sorted { $0.title < $1.title }
        } else {
            return Locale.isoRegionCodes.map { identifier in
                Country(
                    title: Locale.current.localizedString(forRegionCode: identifier) ?? "",
                    emojiSymbol: emojiFlag(for: identifier)
                )
            }.sorted { $0.title < $1.title }
        }
    }
    
    private func emojiFlag(for countryCode: String) -> String! {
        func isLowercaseASCIIScalar(_ scalar: Unicode.Scalar) -> Bool {
            return scalar.value >= 0x61 && scalar.value <= 0x7A
        }
        
        func regionalIndicatorSymbol(for scalar: Unicode.Scalar) -> Unicode.Scalar {
            precondition(isLowercaseASCIIScalar(scalar))
            
            // 0x1F1E6 marks the start of the Regional Indicator Symbol range and corresponds to 'A'
            // 0x61 marks the start of the lowercase ASCII alphabet: 'a'
            return Unicode.Scalar(scalar.value + (0x1F1E6 - 0x61))!
        }
        
        let lowercasedCode = countryCode.lowercased()
        guard lowercasedCode.count == 2 else { return nil }
        guard lowercasedCode.unicodeScalars.reduce(true, { accum, scalar in accum && isLowercaseASCIIScalar(scalar) }) else { return nil }
        
        let indicatorSymbols = lowercasedCode.unicodeScalars.map({ regionalIndicatorSymbol(for: $0) })
        return String(indicatorSymbols.map({ Character($0) }))
    }
}
