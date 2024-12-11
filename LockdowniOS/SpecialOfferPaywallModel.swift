//
//  SpecialOfferPaywallModel.swift
//  LockdowniOS
//
//  Created by George Apostu on 26/11/24.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import Foundation
import SwiftyStoreKit

class SpecialOfferPaywallModel: ObservableObject {
    
    let products: SpecialOfferProducts
    
    var closeAction: (()->Void)? = nil
    var continueAction: ((String)->Void)? = nil
    
    @Published var yearlyPrice: String
    @Published var offerPrice: String
    @Published var showProgress = false
    @Published var isSmallScreen: Bool = UIScreen.main.bounds.width <= 375 || UIScreen.main.bounds.height <= 667

    init(products: SpecialOfferProducts, infos: [InternalSubscription]) {
        self.products = products
                
        let offerPrice = infos.first(where: { $0.productId == products.yearly}).flatMap { $0.offer } ?? 29.99
        let yearlyPrice = offerPrice.dividing(by: 0.2999).subtracting(0.01)
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = infos.first?.priceLocale

        self.yearlyPrice = currencyFormatter.string(from: yearlyPrice) ?? "__"
        self.offerPrice = currencyFormatter.string(from: offerPrice) ?? "__"
    }
    
    func purchase() {
        showProgress = true
        continueAction?(products.yearly)
    }
}
