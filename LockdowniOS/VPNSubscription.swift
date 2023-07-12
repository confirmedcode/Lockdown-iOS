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
import StoreKit

enum SubscriptionState: Int {
    case Uninitialized = 1, Subscribed, NotSubscribed
}

class VPNSubscription: NSObject {
    
    static let productIdAdvancedMonthly = "LockdowniOSFirewallMonthly"
    static let productIdAdvancedYearly = "LockdowniOSFirewallAnnual"
    static let productIdMonthly = "LockdowniOSVpnMonthly"
    static let productIdAnnual = "LockdowniOSVpnAnnual"
    static let productIdMonthlyPro = "LockdowniOSVpnMonthlyPro"
    static let productIdAnnualPro = "LockdowniOSVpnAnnualPro"
    static let productIds: Set = [productIdAdvancedMonthly, productIdAdvancedYearly, productIdMonthly, productIdAnnual, productIdMonthlyPro, productIdAnnualPro]
    static var selectedProductId = productIdAdvancedMonthly
    
    // Advanced Level
    static var defaultPriceStringAdvancedMonthly = "$4.99"
    static var defaultPriceStringAdvancedYearly = "$29.99"
    static var defaultPriceSubStringAdvancedYearly = "$2.49"
    static var defaultUpgradePriceStringAdvancedMonthly = "$4.99"
    static var defaultUpgradePriceStringAdvancedYearly = "$29.99"
    
    // Anonymous Level
    static var defaultPriceStringMonthly = "$8.99"
    static var defaultPriceStringAnnual = "$59.99"
    static var defaultPriceSubStringAnnual = "$4.99"
    static var defaultUpgradePriceStringAnnual = "$59.99"
    static var defaultUpgradePriceStringMonthly = "$8.99"
    
    
    // Universal Level
    static var defaultPriceStringMonthlyPro = "$11.99"
    static var defaultPriceStringAnnualPro = "$99.99"
    static var defaultPriceSubStringAnnualPro = "$8.33"
    static var defaultUpgradePriceStringAnnualPro = "$99.99"
    static var defaultUpgradePriceStringMonthlyPro = "$11.99"
    
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
                        BaseUserService.shared.user.resetCache()
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
    
    static func setProductIdPriceAnnualMonthly(productId: String, price: String) {
        DDLogInfo("Setting product id price yearly per month \(price) for \(productId)")
        UserDefaults.standard.set(price, forKey: productId + "MonthlyPrice")
    }
    
    static func setProductIdUpgradePriceAnnualMonthly(productId: String, price: String) {
        DDLogInfo("Setting product id upgrade price yearly per month\(price) for \(productId)")
        UserDefaults.standard.set(price, forKey: productId + "MonthlyUpgradePrice")
    }
    
    enum SubscriptionContext {
        case new
        case upgrade
        case monthlyNew
        case monthlyUpgrade
    }
    
    static func getProductIdPrice(productId: String, for context: SubscriptionContext) -> String {
        switch context {
        case .new:
            return getProductIdPrice(productId: productId)
        case .upgrade:
            return getProductIdUpgradePrice(productId: productId)
        case .monthlyNew:
            return getProductIdPrice(productId: productId)
        case .monthlyUpgrade:
            return getProductIdUpgradePrice(productId: productId)
        }
    }
    
    static func getProductIdPriceMonthly(productId: String) -> String {
        DDLogInfo("Getting product id price yearly per month \(productId)")
        if let price = UserDefaults.standard.string(forKey: productId + "MonthlyPrice") {
            DDLogInfo("Got product id price yearly per month for \(productId): \(price)")
            return price
        }
        else {
            DDLogError("Found no cached price yearly per month for productId \(productId), returning default")
            switch productId {
            case productIdAdvancedYearly:
                return defaultPriceSubStringAdvancedYearly
            case productIdAnnual:
                return defaultPriceSubStringAnnual
            case productIdAnnualPro:
                return defaultPriceSubStringAnnualPro
            default:
                DDLogError("Invalid product Id: \(productId)")
                return "Invalid Price"
            }
        }
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
            case productIdAdvancedMonthly:
                return defaultPriceStringAdvancedMonthly
            case productIdAdvancedYearly:
                return defaultPriceStringAdvancedYearly
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
    
    static func getProductIdUpgradePrice(productId: String) -> String {
        DDLogInfo("Getting product id upgrade price for \(productId)")
        if let upgradePrice = UserDefaults.standard.string(forKey: productId + "UpgradePrice") {
            DDLogInfo("Got product id upgrade price for \(productId): \(upgradePrice)")
            return upgradePrice
        }
        else {
            DDLogError("Found no cached upgrade price for productId \(productId), returning default")
            switch productId {
            case productIdAdvancedMonthly:
                return defaultUpgradePriceStringAdvancedMonthly
            case productIdAdvancedYearly:
                return defaultUpgradePriceStringAdvancedYearly
            case productIdMonthly:
                return defaultUpgradePriceStringMonthly
            case productIdMonthlyPro:
                return defaultUpgradePriceStringMonthlyPro
            case productIdAnnual:
                return defaultUpgradePriceStringAnnual
            case productIdAnnualPro:
                return defaultUpgradePriceStringAnnualPro
            default:
                DDLogError("Invalid product Id: \(productId)")
                return "Invalid Upgrade Price"
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
                DDLogInfo("productprice: \(product.localizedPrice ?? "n/a")")
                
                if product.productIdentifier == productIdAdvancedMonthly {
                    if product.localizedPrice != nil {
                        DDLogInfo("setting productIdAdvancedMonthly display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdAdvancedMonthly, price: "\(product.localizedPrice!)")
                        setProductIdUpgradePrice(productId: productIdAdvancedMonthly, upgradePrice: "\(product.localizedPrice!)")
                    }
                    else {
                        DDLogError("monthly nil localizedPrice, setting default")
                        setProductIdPrice(productId: productIdAdvancedMonthly, price: defaultPriceStringAdvancedMonthly)
                        setProductIdUpgradePrice(productId: productIdAdvancedMonthly, upgradePrice: defaultUpgradePriceStringAdvancedMonthly)
                    }
                }
                else if product.productIdentifier == productIdAdvancedYearly {
                    if product.localizedPrice != nil {
                        currencyFormatter.locale = product.priceLocale
                        let priceMonthly = product.price.dividing(by: 12)
                        if let priceString = currencyFormatter.string(from: priceMonthly) {
                            setProductIdPriceAnnualMonthly(productId: productIdAdvancedYearly, price: priceString)
                            DDLogInfo("setting productIdAdvancedAnnualMonthly display price = " + priceString)
                        }
                        DDLogInfo("setting productIdAdvancedYearly display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdAdvancedYearly, price: "\(product.localizedPrice!)")
                        setProductIdUpgradePrice(productId: productIdAdvancedYearly, upgradePrice: "\(product.localizedPrice!)")
                    }
                    else {
                        DDLogError("monthly nil localizedPrice, setting default")
                        setProductIdPrice(productId: productIdAdvancedYearly, price: defaultPriceStringAdvancedYearly)
                        setProductIdUpgradePrice(productId: productIdAdvancedYearly, upgradePrice: defaultUpgradePriceStringAdvancedYearly)
                        setProductIdPriceAnnualMonthly(productId: productIdAdvancedYearly, price: defaultPriceSubStringAdvancedYearly)
                    }
                }
                else if product.productIdentifier == productIdAnnual {
                    if product.localizedPrice != nil {
                        currencyFormatter.locale = product.priceLocale
                        let priceMonthly = product.price.dividing(by: 12)
                        if let priceString = currencyFormatter.string(from: priceMonthly) {
                            setProductIdPriceAnnualMonthly(productId: productIdAnnual, price: priceString)
                            DDLogInfo("setting productIdAnnualAnnualMonthly display price = " + priceString)
                        }
                        DDLogInfo("setting productIdAnnualAnnual display price = annual product price / 12 = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdAnnual, price: "\(product.localizedPrice!)")
                        setProductIdUpgradePrice(productId: productIdAnnual, upgradePrice: "\(product.localizedPrice!)")
                    }
                    
                    else {
                        DDLogError("unable to format price with currencyformatter: " + product.price.stringValue)
                        setProductIdPrice(productId: productIdAnnual, price: defaultPriceStringAnnual)
                        setProductIdUpgradePrice(productId: productIdAnnual, upgradePrice: defaultUpgradePriceStringAnnual)
                        setProductIdPriceAnnualMonthly(productId: productIdAnnual, price: defaultPriceSubStringAnnual)
                    }
                }
                else if product.productIdentifier == productIdMonthly {
                    if product.localizedPrice != nil {
                        DDLogInfo("setting productIdMonthly display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdMonthly, price: "\(product.localizedPrice!)")
                        setProductIdUpgradePrice(productId: productIdMonthly, upgradePrice: "\(product.localizedPrice!)")
                    }
                    else {
                        DDLogError("monthly nil localizedPrice, setting default")
                        setProductIdPrice(productId: productIdMonthly, price: defaultPriceStringMonthly)
                        setProductIdUpgradePrice(productId: productIdMonthly, upgradePrice: defaultUpgradePriceStringMonthly)
                    }
                }
                else if product.productIdentifier == productIdMonthlyPro {
                    if product.localizedPrice != nil {
                        DDLogInfo("setting productIdMonthlyPro display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdMonthlyPro, price: "\(product.localizedPrice!)")
                        setProductIdUpgradePrice(productId: productIdMonthlyPro, upgradePrice: "\(product.localizedPrice!)")
                    }
                    else {
                        DDLogError("monthlyPro nil localizedPrice, setting default")
                        setProductIdPrice(productId: productIdMonthlyPro, price: defaultPriceStringMonthlyPro)
                        setProductIdUpgradePrice(productId: productIdMonthlyPro, upgradePrice: defaultUpgradePriceStringMonthlyPro)
                    }
                }
                else if product.productIdentifier == productIdAnnualPro {
                    if product.localizedPrice != nil {
                        currencyFormatter.locale = product.priceLocale
                        let priceMonthly = product.price.dividing(by: 12)
                        if let priceString = currencyFormatter.string(from: priceMonthly) {
                            DDLogInfo("setting productIdAnnualPro display price = annualPro product price / 12 = " + priceString)
                            setProductIdPriceAnnualMonthly(productId: productIdAnnualPro, price: priceString)
                        }
                        DDLogInfo("setting productIdAnnualPro display price = " + product.localizedPrice!)
                        setProductIdPrice(productId: productIdAnnualPro, price: "\(product.localizedPrice!)")
                        setProductIdUpgradePrice(productId: productIdAnnualPro, upgradePrice: "\(product.localizedPrice!)")
                    }
                    else {
                        DDLogError("unable to format price with currencyformatter: " + product.price.stringValue)
                        setProductIdPrice(productId: productIdAnnualPro, price: defaultPriceStringAnnualPro)
                        setProductIdUpgradePrice(productId: productIdAnnualPro, upgradePrice: defaultUpgradePriceStringAnnualPro)
                        setProductIdPriceAnnualMonthly(productId: productIdAnnualPro, price: defaultPriceSubStringAnnualPro)
                    }
                }
            }
            for invalidProductId in result.invalidProductIDs {
                DDLogError("invalid product id: \(invalidProductId)");
            }
        }
    }
    
}

extension Subscription.PlanType {
    var productId: String? {
        switch self {
        case .advancedMonthly:
            return VPNSubscription.productIdAdvancedMonthly
        case .advancedAnnual:
            return VPNSubscription.productIdAdvancedYearly
        case .anonymousMonthly:
            return VPNSubscription.productIdMonthly
        case .anonymousAnnual:
            return VPNSubscription.productIdAnnual
        case .universalMonthly:
            return VPNSubscription.productIdMonthlyPro
        case .universalAnnual:
            return VPNSubscription.productIdAnnualPro
        default:
            return nil
        }
    }
    
    static var supported: [Subscription.PlanType] {
        return [.advancedMonthly, .advancedAnnual, .anonymousMonthly, .anonymousAnnual, .universalMonthly, .universalAnnual]
    }
    
    var availableUpgrades: [Subscription.PlanType]? {
        switch self {
        case .advancedMonthly:
            return [.advancedAnnual, .anonymousMonthly, .anonymousAnnual, .universalMonthly, .universalAnnual]
        case .advancedAnnual:
            return [.anonymousMonthly, .anonymousAnnual, .universalMonthly, .universalAnnual]
        case .anonymousMonthly:
            return [.anonymousAnnual, .universalMonthly, .universalAnnual]
        case .anonymousAnnual:
            return [.universalMonthly, .universalAnnual]
        case .universalMonthly:
            return [.universalAnnual]
        case .universalAnnual:
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
