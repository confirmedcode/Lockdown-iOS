//
//  BaseSelectCountryViewModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 28.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import Foundation

class BaseSelectCountryViewModel {
    var countries = [Country]()
    var selectedCountry: Country? {
        didSet {
            DispatchQueue.main.async {
                self.view?.updateView()
            }
        }
    }
    
    private var didSelectCountry: ((Country?) -> Void)?
    
    private var view: SelectCountryViewController?
    
    
    init(
        selectedCountry: Country?,
        didSelectCountry: ((Country?) -> Void)?
    ) {
        self.didSelectCountry = didSelectCountry
        countries = generateCountryList()
        self.selectedCountry = selectedCountry
    }
    
    func bind(_ view: SelectCountryViewController) {
        self.view = view
    }
    
    func donePressed() {
        didSelectCountry?(selectedCountry)
        view?.cancelClicked()
    }
    
    func generateCountryList() -> [Country] { [] }
}
