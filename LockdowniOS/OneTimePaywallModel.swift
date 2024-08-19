//
//  OneTimePaywallModel.swift
//  Lockdown
//
//  Created by Radu Lazar on 05.08.2024.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import Foundation
import SwiftyStoreKit

class OneTimePaywallModel : ObservableObject {
    
    enum ActivePlan {
        case weekly
        case yearly
    }
    
    let products: OnetTimeProducts
    
    var closeAction: (()->Void)? = nil
    var continueAction: ((String)->Void)? = nil
    
    @Published var trialEnabled = true
    @Published var activePlan: ActivePlan = .weekly
    
    @Published var yearlyPrice: String
    @Published var weeklyPrice: String
    @Published var trialWeeklyPrice: String
    @Published var saving: Int
    @Published var showProgress = false

    init(products: OnetTimeProducts, infos: [InternalSubscription]) {
        self.products = products
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = infos.first?.priceLocale
        
        let yp = infos.first(where: { $0.productId  == products.yearly}).flatMap { $0.price } ?? 11.11
        let wp = yp.dividing(by: 52)
        let twp = infos.first(where: { $0.productId  == products.weeklyTrial}).flatMap { $0.price } ?? 0.11
        
        yearlyPrice = currencyFormatter.string(from: yp) ?? "__"
        weeklyPrice = currencyFormatter.string(from: wp) ?? "__"
        trialWeeklyPrice = currencyFormatter.string(from: twp) ?? "__"

        trialWeeklyPrice = infos.first(where: { $0.productId  == products.weeklyTrial}).flatMap {
            currencyFormatter.locale = $0.priceLocale
            return currencyFormatter.string(from: $0.price)
        } ?? "__"
        
        
        saving = 100 - Int(Double(truncating: wp) / Double(truncating: twp)*100)
    }
    
    
    func purchase() {
        showProgress = true
        switch activePlan {
        case .weekly:
            continueAction?(trialEnabled ? products.weeklyTrial : products.weekly)
        case .yearly:
            continueAction?(trialEnabled ? products.yearlyTrial : products.yearly)
        }
    }
    
}
