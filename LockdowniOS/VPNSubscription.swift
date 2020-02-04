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
    static let productIdMonthlyPro = "LockdowniOSVpnMonthlyPro"
    static let productIdAnnualPro = "LockdowniOSVpnAnnualPro"
    static let productIds: Set = [productIdMonthly, productIdAnnual, productIdMonthlyPro, productIdAnnualPro]
    static var selectedProductId = productIdMonthly
    
    static var defaultPriceStringMonthly = "$7.99 per month after"
    static var defaultPriceStringMonthlyPro = "$9.99 per month after"
    static var defaultPriceStringAnnual = "$49.99/year after (~$4.17/month)"
    static var defaultPriceStringAnnualPro = "$99.99/year after (~$8.33/month)"
    
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
            switch productId {
                case productIdMonthly:
                    return defaultPriceStringMonthly
                case productIdMonthlyPro:
                    return defaultPriceStringMonthlyPro
                case productIdAnnual:
                    return defaultPriceStringAnnual
                case productIdAnnualPro:
                    return defaultPriceStringAnnualPro
                default:
                    DDLogError("Invalid product Id: \(productId)")
                    return "Invalid Price"
            }
        }
    }
    
    static func cacheLocalizedPrices() -> Void {

        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        
        DDLogInfo("cache localized price for productIds: \(productIds)")
        SwiftyStoreKit.retrieveProductsInfo(productIds) { result in
            DDLogInfo("retrieve products results: \(result)")
            for product in result.retrievedProducts {
                DDLogInfo("product locale: \(product.priceLocale)")
                DDLogInfo("productprice: \(product.localizedPrice)")
                if product.productIdentifier == productIdMonthly {
                    if product.localizedPrice != nil {
                        DDLogInfo("setting monthly display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdMonthly, price: "\(product.localizedPrice!) per month after")
                    }
                    else {
                        DDLogError("monthly nil localizedPrice, setting default")
                        setProductIdPrice(productId: productIdMonthly, price: defaultPriceStringMonthly)
                    }
                }
                else if product.productIdentifier == productIdMonthlyPro {
                    if product.localizedPrice != nil {
                        DDLogInfo("setting monthlyPro display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdMonthlyPro, price: "\(product.localizedPrice!) per month after")
                    }
                    else {
                        DDLogError("monthlyPro nil localizedPrice, setting default")
                        setProductIdPrice(productId: productIdMonthlyPro, price: defaultPriceStringMonthlyPro)
                    }
                }
                else if product.productIdentifier == productIdAnnual {
                    currencyFormatter.locale = product.priceLocale
                    let priceMonthly = product.price.dividing(by: 12)
                    DDLogInfo("annual price = \(product.price)")
                    if let priceString = currencyFormatter.string(from: product.price), let priceStringMonthly = currencyFormatter.string(from: priceMonthly) {
                        DDLogInfo("setting annual display price = annual product price / 12 = " + priceString)
                        setProductIdPrice(productId: productIdAnnual, price: "\(priceString)/year after (~\(priceStringMonthly)/month)")
                    }
                    else {
                        DDLogError("unable to format price with currencyformatter: " + product.price.stringValue)
                        setProductIdPrice(productId: productIdAnnual, price: defaultPriceStringAnnual)
                    }
                }
                else if product.productIdentifier == productIdAnnualPro {
                    currencyFormatter.locale = product.priceLocale
                    let priceMonthly = product.price.dividing(by: 12)
                    DDLogInfo("annualPro price = \(product.price)")
                    if let priceString = currencyFormatter.string(from: product.price), let priceStringMonthly = currencyFormatter.string(from: priceMonthly) {
                        DDLogInfo("setting annualPro display price = annualPro product price / 12 = " + priceString)
                        setProductIdPrice(productId: productIdAnnualPro, price: "\(priceString)/year after (~\(priceStringMonthly)/month)")
                    }
                    else {
                        DDLogError("unable to format price with currencyformatter: " + product.price.stringValue)
                        setProductIdPrice(productId: productIdAnnualPro, price: defaultPriceStringAnnualPro)
                    }
                }
            }
            for invalidProductId in result.invalidProductIDs {
                DDLogError("invalid product id: \(invalidProductId)");
            }
        }
    }
    
}
