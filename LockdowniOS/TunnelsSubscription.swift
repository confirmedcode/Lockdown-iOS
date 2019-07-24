//
//  TunnelsSubscription.swift
//  TunnelsiOS
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import SwiftyStoreKit
import CocoaLumberjackSwift

enum SubscriptionState: Int {
    case Loading = 1, Subscribed, NotSubscribed
}

class TunnelsSubscription: NSObject {
    static let TunnelsNotSubscribed = "TunnelsNotSubscribed"
    static let TunnelsIsSubscribed = "TunnelsIsSubscribed"
    static let productId = "TunnelsiOSUnlimitedMonthly"
    static let allProductId = "UnlimitedTunnels"
    static let productIdAnnual = "TunnelsiOSUnlimited"
    static let productIdAllDevices = "UnlimitedTunnels"
    static let productIdAllDevicesAnnual = "AnnualUnlimitedTunnels"
    static var productType = 0 //0 is iOS, 1 is all devices, 2 is for iOS-annual this is for purchase selection
    static var isSubscribed : SubscriptionState = .Loading
    static var localizedPrice = "$4.99" //default pricing for iOS
    static var localizedPriceAllDevices = "$9.99" //default pricing for all devices
    static var localizedPriceAnnual = "$49.99" //default pricing for iOS
    static var localizedPriceAllDevicesAnnual = "$99.99" //default pricing for all devices
    static var subscriptionType = productId //set to product that user is subscribed to
    static var userReceipt : String = "" //b64 encoded receipt
    
    static func subscriptionSupportsAllDevices() -> Bool {
        if TunnelsSubscription.subscriptionType == TunnelsSubscription.productIdAllDevices {
            return true
        }
    
        return false
    }
    
    static func getProductID() -> String {
        if let cachedReceipt = Global.keychain[Global.kConfirmedReceiptKey] {
            userReceipt = cachedReceipt
        }
         
        if productType == 0 {
            return TunnelsSubscription.productId
        }
        else if productType == 2 {
            return productIdAnnual
        }
        else if productType == 3 {
            return productIdAllDevicesAnnual
        }
        else {
            return productIdAllDevices
        }
    }
    
    static func cacheLocalizedPrice() -> Void {
        
        let iOSCachedKey = "TunnelsiOSUnlimitedMonthlyPrice"
        let allCachedKey = "TunnelsUnlimitedMonthlyPrice"
        let iOSAnnualCachedKey = "TunnelsiOSUnlimitedAnnualPrice"
        let allDevicesAnnualCachedKey = "TunnelsUnlimitedAnnualPrice"
        
        SwiftyStoreKit.retrieveProductsInfo([productId]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                localizedPrice = priceString
                UserDefaults.standard.set(priceString, forKey: iOSCachedKey)
                UserDefaults.standard.synchronize()
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                if let cachedPrice = UserDefaults.standard.string(forKey: iOSCachedKey) {
                    localizedPrice = cachedPrice
                }
            }
            else {
                DDLogError("Error: \(result.error)")
                
                if let cachedPrice = UserDefaults.standard.string(forKey: iOSCachedKey) {
                    localizedPrice = cachedPrice
                }
            }
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Subscription Price Updated"), object: nil)
        }
        
        //now get all devices price
        
        SwiftyStoreKit.retrieveProductsInfo([allProductId]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                localizedPriceAllDevices = priceString
                UserDefaults.standard.set(priceString, forKey: allCachedKey)
                UserDefaults.standard.synchronize()
            }
            else if result.invalidProductIDs.first != nil{
                if let cachedPrice = UserDefaults.standard.string(forKey: allCachedKey) {
                    localizedPriceAllDevices = cachedPrice
                }
            }
            else {
                if let err = result.error {DDLogError("Error: \(err)") }
                
                if let cachedPrice = UserDefaults.standard.string(forKey: allCachedKey) {
                    localizedPriceAllDevices = cachedPrice
                }
            }
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Subscription Price Updated"), object: nil)
        }
        
        
        SwiftyStoreKit.retrieveProductsInfo([productIdAnnual]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                localizedPriceAnnual = priceString
                UserDefaults.standard.set(priceString, forKey: iOSAnnualCachedKey)
                UserDefaults.standard.synchronize()
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                if let cachedPrice = UserDefaults.standard.string(forKey: iOSAnnualCachedKey) {
                    localizedPriceAnnual = cachedPrice
                }
            }
            else {
                DDLogError("Error: \(result.error)")
                
                if let cachedPrice = UserDefaults.standard.string(forKey: iOSAnnualCachedKey) {
                    localizedPriceAnnual = cachedPrice
                }
            }
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Subscription Price Updated"), object: nil)
        }
        
        SwiftyStoreKit.retrieveProductsInfo([productIdAllDevicesAnnual]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                localizedPriceAllDevicesAnnual = priceString
                UserDefaults.standard.set(priceString, forKey: allDevicesAnnualCachedKey)
                UserDefaults.standard.synchronize()
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                if let cachedPrice = UserDefaults.standard.string(forKey: allDevicesAnnualCachedKey) {
                    localizedPriceAllDevicesAnnual = cachedPrice
                }
            }
            else {
                DDLogError("Error: \(result.error)")
                
                if let cachedPrice = UserDefaults.standard.string(forKey: allDevicesAnnualCachedKey) {
                    localizedPriceAllDevicesAnnual = cachedPrice
                }
            }
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Subscription Price Updated"), object: nil)
        }
    }
    
    static func refreshAndUploadReceipt() {
        SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
            switch result {
            case .success(let receiptData):
                let encryptedReceipt = receiptData.base64EncodedString(options: [])
                if encryptedReceipt != nil {
                    userReceipt = encryptedReceipt
                    Global.keychain[Global.kConfirmedReceiptKey] = userReceipt
                    
                    if let email = Global.keychain[Global.kConfirmedEmail], let password =  Global.keychain[Global.kConfirmedPassword] {
                        Auth.uploadNewReceipt(uploadReceiptCallback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
                            //TODO: Error handling here?
                        })
                    }
                    
                    Auth.getKey(callback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
                        if status {
                        }
                        else {
                            //some error
                        }
                    })
                }
            case .error(let error):
                print("Error here upload \(error)")
            }
        }
    }
    
    private static func isSubscribedThroughiTunes(refreshITunesIfNeeded : Bool, isSubscribed: @escaping () -> Void, isNotSubscribed: @escaping () -> Void) -> Void {
        
        //just use Auth and check against our server
        SwiftyStoreKit.fetchReceipt(forceRefresh: refreshITunesIfNeeded) { result in
            switch result {
            case .success(let receiptData):
                let encryptedReceipt = receiptData.base64EncodedString(options: [])
                if encryptedReceipt != nil {
                    userReceipt = encryptedReceipt
                    Global.keychain[Global.kConfirmedReceiptKey] = userReceipt
                    //print("Tunnels sub here \(Global.keychain[Global.kConfirmedReceiptKey])")
                    if let email = Global.keychain[Global.kConfirmedEmail], let password =  Global.keychain[Global.kConfirmedPassword] {
                        Auth.uploadNewReceipt(uploadReceiptCallback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
                            //TODO: Error handling here?
                        })
                    }
                    
                    Auth.clearCookies()
                    Auth.getKey(callback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
                        if status {
                            TunnelsSubscription.isSubscribed = .Subscribed
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: TunnelsIsSubscribed), object: nil)
                            isSubscribed()
                        }
                        else {
                            //some error
                            if errorCode == Global.kInternetDownError || errorCode == Global.kTooManyRequests {
                                //just need to notify user
                                NotificationCenter.post(name: .internetDownNotification)
                            }
                            else {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: TunnelsNotSubscribed), object: nil)
                                TunnelsSubscription.isSubscribed = .NotSubscribed
                                isNotSubscribed()
                            }
                        }
                    })
                }
                else {
                    DDLogError("Decrypt failed (shouldn't happen)")
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: TunnelsNotSubscribed), object: nil)
                    TunnelsSubscription.isSubscribed = .NotSubscribed
                    isNotSubscribed()
                }
            case .error(let error):
                DDLogError("Fetch receipt failed: \(error)")
                
                //don't unsubscribe those with a flakey internet connection
                
                switch error {
                case ReceiptError.networkError(let networkError):
                    print("Network error")
                    
                default:
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: TunnelsNotSubscribed), object: nil)
                    TunnelsSubscription.isSubscribed = .NotSubscribed
                    isNotSubscribed()
                }
               
            
            }
        }
    }
    
    static func isSubscribed(refreshITunesIfNeeded : Bool, isSubscribed: @escaping () -> Void, isNotSubscribed: @escaping () -> Void) -> Void {
        
        //try to sign in first, much faster response time/reliability
        Auth.getKey(callback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
            if status {
                TunnelsSubscription.isSubscribed = .Subscribed
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: TunnelsIsSubscribed), object: nil)
                isSubscribed()
            }
            else {
                //now try iTunes, simply forward calls
                //email is not confirmed, let them know
                isSubscribedThroughiTunes(refreshITunesIfNeeded: refreshITunesIfNeeded, isSubscribed: { isSubscribed() }, isNotSubscribed: { isNotSubscribed() })
            }
        })
    }
    
    static func purchaseTunnels(succeeded: @escaping () -> Void, errored: @escaping () -> Void) {
        
        SwiftyStoreKit.purchaseProduct(getProductID(), atomically: true) { result in
            switch result {
            case .success(let purchase):
                // Deliver content from server, then:
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                
                Auth.clearCookies()
                SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
                    switch result {
                    case .success(let receiptData):
                        let encryptedReceipt = receiptData.base64EncodedString(options: [])
                        if encryptedReceipt != nil {
                            userReceipt = encryptedReceipt
                            Global.keychain[Global.kConfirmedReceiptKey] = userReceipt
                            //print("Tunnels sub \(Global.keychain[Global.kConfirmedReceiptKey])")
                            
                            //if e-mail/password is there, add receipt to account
                            if let email = Global.keychain[Global.kConfirmedEmail], let password =  Global.keychain[Global.kConfirmedPassword] {
                                Auth.uploadNewReceipt(uploadReceiptCallback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
                                    //TODO: Error handling here?
                                })
                                TunnelsSubscription.isSubscribed = .Subscribed
                                succeeded()
                            }
                            else {
                                Auth.getKey(callback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
                                    if status {
                                        TunnelsSubscription.isSubscribed = .Subscribed
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: TunnelsIsSubscribed), object: nil)
                                        succeeded()
                                    }
                                    else {
                                        //some error
                                        if errorCode == Global.kInternetDownError || errorCode == Global.kTooManyRequests {
                                            NotificationCenter.post(name: .internetDownNotification)
                                        }
                                        else {
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: TunnelsNotSubscribed), object: nil)
                                            TunnelsSubscription.isSubscribed = .NotSubscribed
                                        }
                                        
                                        errored()
                                    }
                                })
                            }
                        }
                    case .error(let error):
                        DDLogError("Error here \(error)")
                        errored()
                    }
                }
            case .error(let error):
                DDLogError("Purchse error here \(error)")
                errored()
            }
            
        }
    }
    
    
}
