//
//  VPNSubscription.swift
//  Lockdown
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import SwiftyStoreKit
import PromiseKit
import CocoaLumberjackSwift

enum SubscriptionState: Int {
    case Uninitialized = 1, Subscribed, NotSubscribed
}

class VPNSubscription: NSObject {
    
    static let productIdMonthly = "LockdowniOSVpnMonthly"
    static let productIdAnnual = "LockdowniOSVpnAnnual"
    static let productIds: Set = [productIdMonthly, productIdAnnual]
    static var selectedProductId = productIdMonthly
    
    static var defaultPriceMonthly = "$4.99"
    static var defaultPriceAnnual = "$4.17"
    
    static func purchase(succeeded: @escaping () -> Void, errored: @escaping (Error) -> Void) {
        DDLogInfo("purchase")
        SwiftyStoreKit.purchaseProduct(selectedProductId, atomically: true) { result in
            switch result {
                case .success:
                    firstly {
                        try Client.signIn()
                    }
                    .then { (signin: SignIn) -> Promise<GetKey> in
                        try Client.getKey()
                    }
                    .done { (getKey: GetKey) in
                        try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                        succeeded()
                    }
                    .catch { error in
                        errored(error)
                    }
                case .error(let error):
                    DDLogError("purchase error: \(error)")
                    errored(error)
            }
        }
    }
    
    static func setProductIdPrice(productId: String, price: String) {
        DDLogInfo("Setting product id price \(price) for \(productId)")
        UserDefaults.standard.set(price, forKey: productId + "Price")
    }
    
    static func getProductIdPrice(productId: String) -> String {
        DDLogInfo("Getting product id price for \(productId)")
        if let price = UserDefaults.standard.string(forKey: productId + "Price") {
            DDLogInfo("Got product id price for \(productId): \(price)")
            return price
        }
        else {
            DDLogError("Found no cached price for productId \(productId), returning default")
            if productId == productIdMonthly {
                return defaultPriceMonthly
            }
            else if productId == productIdAnnual {
                return defaultPriceAnnual
            }
            else {
                DDLogError("Invalid product Id: \(productId)")
                return "Invalid Price"
            }
        }
    }
    
    static func cacheLocalizedPrices() -> Void {
        DDLogInfo("cache localized price for productIds: \(productIds)")
        SwiftyStoreKit.retrieveProductsInfo(productIds) { result in
            DDLogInfo("retrieve products results: \(result)")
            for product in result.retrievedProducts {
                DDLogInfo("product locale: \(product.priceLocale)")
                DDLogInfo("productprice: \(product.localizedPrice)")
                if product.productIdentifier == productIdMonthly {
                    if product.localizedPrice != nil {
                        DDLogInfo("setting monthly display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: product.productIdentifier, price: product.localizedPrice!)
                    }
                    else {
                        DDLogError("monthly nil localizedPrice, setting default")
                        setProductIdPrice(productId: product.productIdentifier, price: defaultPriceMonthly)
                    }
                }
                else if product.productIdentifier == productIdAnnual {
                    let currencyFormatter = NumberFormatter()
                    currencyFormatter.usesGroupingSeparator = true
                    currencyFormatter.numberStyle = .currency
                    currencyFormatter.locale = product.priceLocale
                    let price = product.price.dividing(by: 12)
                    DDLogInfo("annual price = \(product.price)")
                    if let priceString = currencyFormatter.string(from: price) {
                        DDLogInfo("setting annual display price = annual product price / 12 = " + priceString)
                        setProductIdPrice(productId: product.productIdentifier, price: priceString)
                    }
                    else {
                        DDLogError("unable to format price with currencyformatter: " + price.stringValue)
                        setProductIdPrice(productId: product.productIdentifier, price: defaultPriceAnnual)
                    }
                }
            }
            for invalidProductId in result.invalidProductIDs {
                DDLogError("invalid product id: \(invalidProductId)");
            }
        }
    }
    
}
