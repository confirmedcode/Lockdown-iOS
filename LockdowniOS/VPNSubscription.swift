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
    static let productIdAnnualProLTO = "LockdownProAnnualLTO"
    
    static let productIds: Set = [productIdMonthly, productIdAnnual, productIdMonthlyPro, productIdAnnualPro, productIdAnnualProLTO]
    static var selectedProductId = productIdMonthly
    
    static var defaultPriceStringMonthly = "$7.99 per month after"
    static var defaultPriceStringMonthlyPro = "$11.99 per month after"
    static var defaultPriceStringAnnual = "$49.99/year after (~$4.17/month)"
    static var defaultPriceStringAnnualPro = "$99.99/year after (~$8.33/month)"
    static var defaultPriceStringAnnualProLTO = "$59.99/year after (~$8.33/month)"
    
    static var defaultUpgradePriceStringMonthly = "$7.99 per month"
    static var defaultUpgradePriceStringMonthlyPro = "$11.99 per month"
    static var defaultUpgradePriceStringAnnual = "$49.99/year (~$4.17/month)"
    static var defaultUpgradePriceStringAnnualPro = "$99.99/year (~$8.33/month)"
    static var defaultUpgradePriceStringAnnualProLTO = "$59.99/year (~$4.99/month)"
    
    static func purchase(succeeded: @escaping () -> Void, errored: @escaping (Error) -> Void) {
        DDLogInfo("purchase")
        SwiftyStoreKit.purchaseProduct(selectedProductId, atomically: true) { result in
            switch result {
            case .success:
                firstly {
                    try Client.signIn()
                }
                .then { _ in
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
    
    static func setProductIdUpgradePrice(productId: String, upgradePrice: String) {
        DDLogInfo("Setting product id upgrade price \(upgradePrice) for \(productId)")
        UserDefaults.standard.set(upgradePrice, forKey: productId + "UpgradePrice")
    }
    
    enum SubscriptionContext {
        case new
        case upgrade
    }
    
    static func getProductIdPrice(productId: String, for context: SubscriptionContext) -> String {
        switch context {
        case .new:
            return getProductIdPrice(productId: productId)
        case .upgrade:
            return getProductIdUpgradePrice(productId: productId)
        }
    }
    
    static func getProductIdPrice(productId: String) -> String {
        DDLogInfo("Getting product id price for \(productId)")
        if let price = UserDefaults.standard.string(forKey: productId + "Price") {
            DDLogInfo("Got product id price for \(productId): \(price)")
            return price
        } else {
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
            case productIdAnnualProLTO:
                return defaultPriceStringAnnualProLTO
            default:
                DDLogError("Invalid product Id: \(productId)")
                return "Invalid Price"
            }
        }
    }
    
    static func getProductIdUpgradePrice(productId: String) -> String {
        DDLogInfo("Getting product id upgrade price for \(productId)")
        if let upgradePrice = UserDefaults.standard.string(forKey: productId + "UpgradePrice") {
            DDLogInfo("Got product id upgrade price for \(productId): \(upgradePrice)")
            return upgradePrice
        } else {
            DDLogError("Found no cached upgrade price for productId \(productId), returning default")
            switch productId {
            case productIdMonthly:
                return defaultUpgradePriceStringMonthly
            case productIdMonthlyPro:
                return defaultUpgradePriceStringMonthlyPro
            case productIdAnnual:
                return defaultUpgradePriceStringAnnual
            case productIdAnnualPro:
                return defaultUpgradePriceStringAnnualPro
            case productIdAnnualProLTO:
                return defaultUpgradePriceStringAnnualProLTO
            default:
                DDLogError("Invalid product Id: \(productId)")
                return "Invalid Upgrade Price"
            }
        }
    }
    
    static func cacheLocalizedPrices() {

        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        
        DDLogInfo("cache localized price for productIds: \(productIds)")
        SwiftyStoreKit.retrieveProductsInfo(productIds) { result in
            DDLogInfo("retrieve products results: \(result)")
            for product in result.retrievedProducts {
                DDLogInfo("product locale: \(product.priceLocale)")
                DDLogInfo("productprice: \(product.localizedPrice ?? "n/a")")
                if product.productIdentifier == productIdMonthly {
                    if product.localizedPrice != nil {
                        DDLogInfo("setting monthly display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdMonthly, price: "\(product.localizedPrice!)/" + .localized("month_after_slash"))
                        setProductIdUpgradePrice(productId: productIdMonthly,
                                                 upgradePrice: "\(product.localizedPrice!)/" + .localized("month_after_slash"))
                    } else {
                        DDLogError("monthly nil localizedPrice, setting default")
                        setProductIdPrice(productId: productIdMonthly, price: defaultPriceStringMonthly)
                        setProductIdUpgradePrice(productId: productIdMonthly, upgradePrice: defaultUpgradePriceStringMonthly)
                    }
                } else if product.productIdentifier == productIdMonthlyPro {
                    if product.localizedPrice != nil {
                        DDLogInfo("setting monthlyPro display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdMonthlyPro, price: "\(product.localizedPrice!)/" + .localized("month_after_slash"))
                        setProductIdUpgradePrice(productId: productIdMonthlyPro,
                                                 upgradePrice: "\(product.localizedPrice!)/" + .localized("month_after_slash"))
                    } else {
                        DDLogError("monthlyPro nil localizedPrice, setting default")
                        setProductIdPrice(productId: productIdMonthlyPro, price: defaultPriceStringMonthlyPro)
                        setProductIdUpgradePrice(productId: productIdMonthlyPro, upgradePrice: defaultUpgradePriceStringMonthlyPro)
                    }
                } else if product.productIdentifier == productIdAnnual {
                    currencyFormatter.locale = product.priceLocale
                    DDLogInfo("annual price = \(product.price)")
                    if let priceString = currencyFormatter.string(from: product.price) {
                        DDLogInfo("setting annual display price = annual product price / 12 = " + priceString)
                        setProductIdPrice(productId: productIdAnnual, price: "\(priceString)/" + .localized("year_after_slash"))
                        setProductIdUpgradePrice(productId: productIdAnnual, upgradePrice: "\(priceString)/" + .localized("year_after_slash"))
                    } else {
                        DDLogError("unable to format price with currencyformatter: " + product.price.stringValue)
                        setProductIdPrice(productId: productIdAnnual, price: defaultPriceStringAnnual)
                        setProductIdUpgradePrice(productId: productIdAnnual, upgradePrice: defaultUpgradePriceStringAnnual)
                    }
                } else if product.productIdentifier == productIdAnnualPro {
                    currencyFormatter.locale = product.priceLocale
                    DDLogInfo("annualPro price = \(product.price)")
                    if let priceString = currencyFormatter.string(from: product.price) {
                        DDLogInfo("setting annualPro display price = annualPro product price / 12 = " + priceString)
                        setProductIdPrice(productId: productIdAnnualPro, price: "\(priceString)/" + .localized("year_after_slash"))
                        setProductIdUpgradePrice(productId: productIdAnnualPro, upgradePrice: "\(priceString)/" + .localized("year_after_slash"))
                    } else {
                        DDLogError("unable to format price with currencyformatter: " + product.price.stringValue)
                        setProductIdPrice(productId: productIdAnnualPro, price: defaultPriceStringAnnualPro)
                        setProductIdUpgradePrice(productId: productIdAnnualPro, upgradePrice: defaultUpgradePriceStringAnnualPro)
                    }
                } else if product.productIdentifier == productIdAnnualProLTO {
                    currencyFormatter.locale = product.priceLocale
                    DDLogInfo("annualPro price = \(product.price)")
                    if let priceString = currencyFormatter.string(from: product.price) {
                        DDLogInfo("setting annualPro LTO display price = annualPro product price / 12 = " + priceString)
                        setProductIdPrice(productId: productIdAnnualProLTO, price: "\(priceString)/" + .localized("year_after_slash"))
                        setProductIdUpgradePrice(productId: productIdAnnualProLTO, upgradePrice: "\(priceString)/" + .localized("year_after_slash"))
                    } else {
                        DDLogError("unable to format price with currencyformatter: " + product.price.stringValue)
                        setProductIdPrice(productId: productIdAnnualProLTO, price: defaultPriceStringAnnualProLTO)
                        setProductIdUpgradePrice(productId: productIdAnnualProLTO, upgradePrice: defaultUpgradePriceStringAnnualProLTO)
                    }
                }
            }
            for invalidProductId in result.invalidProductIDs {
                DDLogError("invalid product id: \(invalidProductId)")
            }
        }
    }
    
}

extension Subscription.PlanType {
    var productId: String? {
        switch self {
        case .monthly:
            return VPNSubscription.productIdMonthly
        case .annual:
            return VPNSubscription.productIdAnnual
        case .proMonthly:
            return VPNSubscription.productIdMonthlyPro
        case .proAnnual:
            return VPNSubscription.productIdAnnualPro
        case .proAnnualLTO:
            return VPNSubscription.productIdAnnualProLTO
        default:
            return nil
        }
    }
    
    static var supported: [Subscription.PlanType] {
        return [.monthly, .annual, .proMonthly, .proAnnual, .proAnnualLTO]
    }
    
    var availableUpgrades: [Subscription.PlanType]? {
        switch self {
        case .monthly:
            return [.annual, .proMonthly, .proAnnual]
        case .annual:
            return [.proAnnual]
        case .proMonthly:
            return [.proAnnual]
        case .proAnnual:
            return []
        default:
            return nil
        }
    }
    
    var unavailableToUpgrade: [Subscription.PlanType]? {
        guard let upgrades = availableUpgrades else {
            return nil
        }
        
        var candidates = Subscription.PlanType.supported
        candidates.removeAll(where: { upgrades.contains($0) })
        return candidates
    }
    
    func canUpgrade(to newPlan: Subscription.PlanType) -> Bool {
        return availableUpgrades?.contains(newPlan) == true
    }
}
