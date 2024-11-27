//
//  ProductPurchasable.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import CocoaLumberjackSwift
import Foundation
import PromiseKit
import StoreKit

protocol ProductPurchasable: Loadable {
    func purchaseProduct(withId productId: String, onSuccess: (() -> Void)?, onFailure: (() -> Void)?)
    func restorePurchases()
}

extension ProductPurchasable where Self: BaseViewController {
    func purchaseProduct(withId productId: String = VPNSubscription.selectedProductId,
                         onSuccess: (() -> Void)? = nil,
                         onFailure: (() -> Void)? = nil) {
        VPNSubscription.selectedProductId = productId
        showLoadingView()
        
        VPNSubscription.purchase(
            succeeded: {
                BaseUserService.shared.updateUserSubscription { [weak self] _ in
                    self?.hideLoadingView()
                    self?.handleSuccessfulPurchase()
                    onSuccess?()
                }
            },
            errored: { error in
                onFailure?()
                self.hideLoadingView()
                DDLogError("Start Trial Failed: \(error)")
                
                if let skError = error as? SKError {
                    var errorText = ""
                    switch skError.code {
                    case .unknown:
                        errorText = .localized("Unknown error. Please contact support at team@lockdownprivacy.com.")
                    case .clientInvalid:
                        errorText = .localized("Not allowed to make the payment")
                    case .paymentCancelled:
                        errorText = .localized("Payment was cancelled")
                    case .paymentInvalid:
                        errorText = .localized("The purchase identifier was invalid")
                    case .paymentNotAllowed:
                        errorText = .localized("""
Payment not allowed.\nEither this device is not allowed to make purchases, or In-App Purchases have been disabled. \
Please allow them in Settings App -> Screen Time -> Restrictions -> App Store -> In-app Purchases. Then try again.
""")
                    case .storeProductNotAvailable:
                        errorText = .localized("The product is not available in the current storefront")
                    case .cloudServicePermissionDenied:
                        errorText = .localized("Access to cloud service information is not allowed")
                    case .cloudServiceNetworkConnectionFailed:
                        errorText = .localized("Could not connect to the network")
                    case .cloudServiceRevoked:
                        errorText = .localized("User has revoked permission to use this cloud service")
                    default:
                        errorText = skError.localizedDescription
                    }
                    self.showPopupDialog(title: .localized("Error Making Purchase"), message: errorText, acceptButton: .localizedOkay)
                } else if self.popupErrorAsNSURLError(error) {
                    return
                } else if self.popupErrorAsApiError(error) {
                    return
                } else {
                    self.showPopupDialog(
                        title: .localized("Error Making Purchase"),
                        message: .localized("Please contact team@lockdownprivacy.com.\n\nError details:\n") + "\(error)",
                        acceptButton: .localizedOkay)
                }
            })
    }
    
    func restorePurchases() {
        showLoadingView()
        
        firstly {
            try Client.signIn(forceRefresh: true)
        }
        .done { _ in
            // we were able to get key, so subscription is valid -- follow pathway from HomeViewController to associate this with the email account if there is one
            self.dismiss(animated: true, completion: {
                self.hideLoadingView()
                let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
                let vc = SplashscreenViewController()
                let navigation = UINavigationController(rootViewController: vc)
                keyWindow?.rootViewController = navigation
            })
        }
        .catch { error in
            self.hideLoadingView()
            DDLogError("Restore Failed: \(error)")
            if let apiError = error as? ApiError {
                switch apiError.code {
                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                    // now try email if it exists
                    if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
                        DDLogInfo("restore: have confirmed API credentials, using them")
                        self.showLoadingView()
                        firstly {
                            try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                        }
                        .then { (signin: SignIn) -> Promise<GetKey> in
                            DDLogInfo("restore: signin result: \(signin)")
                            return try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
                            BaseUserService.shared.updateUserSubscription { [weak self] _ in
                                self?.hideLoadingView()
                                
                                do {
                                    try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                                } catch {
                                    DDLogInfo("restore: setting VPN creds with ID and Dismissing: \(getKey.id)")
                                    let presentingViewController = self?.presentingViewController as? HomeViewController
                                    self?.dismiss(animated: true, completion: {
                                        if presentingViewController != nil {
                                            presentingViewController?.toggleVPN("me")
                                        } else {
//                                            VPNController.shared.setEnabled(true)
                                        }
                                    })
                                }
                            }
                        }
                        .catch { error in
                            self.hideLoadingView()
                            DDLogError("restore: Error doing restore with email-login: \(error)")
                            if self.popupErrorAsNSURLError(error) {
                                return
                            } else if let apiError = error as? ApiError {
                                switch apiError.code {
                                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                                    self.showPopupDialog(title: .localized("No Active Subscription"),
                                                         message: .localized("""
Please ensure that you have an active subscription. If you're attempting to share a subscription from the same account, \
you'll need to sign in with the same email address. Otherwise, start your free trial or e-mail team@lockdownprivacy.com
"""),
                                                         acceptButton: .localizedOK)
                                default:
                                    _ = self.popupErrorAsApiError(error)
                                }
                            }
                        }
                    } else {
                        let message = """
Please ensure that you have an active subscription. If you're attempting to share a subscription from the same account, \
you'll need to sign in with the same email address. Otherwise, start your free trial or e-mail team@lockdownprivacy.com
"""
                        self.showPopupDialog(title: .localized("No Active Subscription"),
                                             message: .localized(message),
                                             acceptButton: .localizedOK)
                    }
                default:
                    let pleaseEmail: String = .localized("Please email team@lockdownprivacy.com with the following Error Code ")
                    self.showPopupDialog(
                        title: .localized("Error Restoring Subscription"),
                        message: pleaseEmail + "\(apiError.code) : \(apiError.message)",
                        acceptButton: .localizedOK)
                }
            } else {
                let message: String = .localized("""
Please make sure your Internet connection is active. If this error persists, email team@lockdownprivacy.com with
the following error message: \

""")
                self.showPopupDialog(title: .localized("Error Restoring Subscription"), message: message + "\(error)", acceptButton: .localizedOK)
            }
        }
    }
    
    // MARK: - Handling Purchase Results
    
    private func handleSuccessfulPurchase() {
        dismiss(animated: true, completion: {
            // force refresh receipt, and sync with email if it exists, activate VPNte
            if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
                DDLogInfo("purchase complete: syncing with confirmed email")
                firstly {
                    try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                }
                .then { (signin: SignIn) -> Promise<SubscriptionEvent> in
                    DDLogInfo("purchase complete: signin result: \(signin)")
                    return try Client.subscriptionEvent(forceRefresh: true)
                }
                .then { (result: SubscriptionEvent) -> Promise<GetKey> in
                    DDLogInfo("purchase complete: subscriptionevent result: \(result)")
                    return try Client.getKey()
                }
                .done { (getKey: GetKey) in
                    try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                    DDLogInfo("purchase complete: setting VPN creds with ID: \(getKey.id)")
                    VPNController.shared.setEnabled(true)
                }
                .catch { error in
                    DDLogError("purchase complete: Error: \(error)")
                    if self.popupErrorAsNSURLError("Error activating Secure Tunnel: \(error)") {
                        return
                    } else if let apiError = error as? ApiError {
                        switch apiError.code {
                        default:
                            _ = self.popupErrorAsApiError("API Error activating Secure Tunnel: \(error)")
                        }
                    }
                }
            } else {
                firstly {
                    try Client.signIn(forceRefresh: true) // this will fetch and set latest receipt, then submit to API to get cookie
                }
                .then { _ in
                    // TODO: don't always do this -- if we already have a key, then only do it once per day max
                    try Client.getKey()
                }
                .done { (getKey: GetKey) in
                    try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                    VPNController.shared.setEnabled(true)
                }
                .catch { error in
                    DDLogError("purchase complete - no email: Error: \(error)")
                    if self.popupErrorAsNSURLError("Error activating Secure Tunnel: \(error)") {
                        return
                    } else if let apiError = error as? ApiError {
                        switch apiError.code {
                        default:
                            _ = self.popupErrorAsApiError("API Error activating Secure Tunnel: \(error)")
                        }
                    }
                }
            }
        })
    }
}

