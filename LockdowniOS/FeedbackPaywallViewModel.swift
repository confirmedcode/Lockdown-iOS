//
//  FeedbackPaywallViewModel.swift
//  Lockdown
//
//  Created by Fabian Mistoiu on 10.10.2024.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import Foundation
import StoreKit

class FeedbackPaywallViewModel {

    struct PaywallPlan {
        let id: String
        let name: String
        let price: String
        let pricePeriod: String?
        let promo: String?
    }

    @Published var paywallPlans: [PaywallPlan] = []
    @Published var selectedPlanIndex: Int = 0

    private let products: FeedbackProducts
    private let subscriptionInfo: [InternalSubscription]

    var onCloseHandler: ((UIViewController) -> Void)? = nil
    var onPurchaseHandler: ((UIViewController, String) -> Void)? = nil

    init(products: FeedbackProducts, subscriptionInfo: [InternalSubscription]) {
        self.products = products
        self.subscriptionInfo = subscriptionInfo

        createPaywallPlans()
    }

    public func selectPlan(at index: Int) {
        selectedPlanIndex = index
    }

    private func createPaywallPlans() {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = subscriptionInfo.first?.priceLocale

        guard let yearlyPlan = subscriptionInfo.first(where: { $0.productId  == products.yearly}),
              let weeklyPlan = subscriptionInfo.first(where: { $0.productId  == products.weekly}),
              let yearlyPrice = currencyFormatter.string(from: yearlyPlan.price),
              let weeklyPrice = currencyFormatter.string(from: weeklyPlan.price) else {
            return
        }

        let yearlyPricePerWeek = yearlyPlan.price.dividing(by: 52)
        let saving = 100 - Int(Double(truncating: yearlyPricePerWeek) / Double(truncating: weeklyPlan.price)*100)

        paywallPlans = [
            PaywallPlan(id: products.yearly, name: "Yearly Plan", price: yearlyPrice, pricePeriod: nil, promo: "SAVE \(saving)%"),
            PaywallPlan(id: products.weekly, name: "Weekly Plan", price: weeklyPrice, pricePeriod: "per week", promo: nil)
        ]
        selectedPlanIndex = 0
    }
}
