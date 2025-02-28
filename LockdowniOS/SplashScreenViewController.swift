//
//  SplashScreenViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 12.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import AppTrackingTransparency
import UIKit
import SwiftUI
import PromiseKit
import CocoaLumberjackSwift

final class SplashScreenViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let cached = BaseUserService.shared.user.cachedSubscription() {
            BaseUserService.shared.user.updateSubscription(to: cached)
            finishFlow(with: cached)
            
            BaseUserService.shared.updateUserSubscription { subscription in
                guard let subscription,
                      !cached.isSameType(subscription) else {
                    return
                }
                NotificationCenter.default.post(name: AccountUI.subscritionTypeChanged, object: nil)
            }
        } else {
            BaseUserService.shared.updateUserSubscription { [weak self] subscription in
                self?.finishFlow(with: subscription)
                writeCommonInfoToLog()
            }
        }
    }
    
    private func finishFlow(with subscription: Subscription?) {
        updateUserDafauls(with: subscription)

        DispatchQueue.main.async {
            self.dismiss()
        }
    }
    
    private func updateUserDafauls(with subscription: Subscription?) {
        UserDefaults.hasSeenAdvancedPaywall = subscription?.planType.isAdvanced ?? false
        UserDefaults.hasSeenUniversalPaywall = subscription?.planType.isUniversal ?? false
        UserDefaults.hasSeenAnonymousPaywall = subscription?.planType.isAnonymous ?? false
    }
    
    private func dismiss() {
        dismiss(animated: false) { [weak self] in
            if UserDefaults.onboardingCompleted {
                self?.showMainTabView()
            } else {
                let isPremiumUser = BaseUserService.shared.user.currentSubscription != nil
                if isPremiumUser {
                    self?.showMainTabView()
                } else {
                    self?.showOnboardingFlow()
                }
            }
        }
    }
    
    private func showOnboardingFlow() {
        Task { @MainActor in
            if let productInfos = await VPNSubscription.shared.loadSubscriptions(type: .onboarding) {
                let paywallModel = OneTimePaywallModel(products: VPNSubscription.onboardingProducts, infos: productInfos)
                paywallModel.closeAction = { [weak self] in
                    UserDefaults.onboardingCompleted = true
                    self?.showMainTabView()
                }
                paywallModel.continueAction = { [weak self] pid in
                    VPNSubscription.selectedProductId = pid
                    VPNSubscription.purchase {
                        UserDefaults.onboardingCompleted = true
                        self?.handlePurchaseSuccessful(placement: .onboarding)
                    } errored: { err in
                        paywallModel.showProgress = false
                        self?.handlePurchaseFailed(error: err)
                    }
                }
                paywallModel.restoreAction = { [weak self] in
                    self?.restorePurchase(completion: {
                        UserDefaults.onboardingCompleted = true
                        paywallModel.showProgress = false
                        self?.handlePurchaseSuccessful()
                    })
                }
                let onboardingController = UIHostingController(rootView: OnboardingView(paywallModel: paywallModel))
                onboardingController.modalPresentationStyle = .fullScreen
                onboardingController.modalTransitionStyle = .crossDissolve
                present(onboardingController, animated: true)
            } else {
                showMainTabView()
            }
        }
    }
    
    private func showMainTabView() {
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        keyWindow?.rootViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "MainTabBarController")
        keyWindow?.makeKeyAndVisible()
    }
    
    private func askForPermissionToTrack(completion: @escaping () -> Void) {
        guard #available(iOS 14, *) else {
            completion()
            return
        }
        
        ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in
            completion()
        })
    }
    
    private func restorePurchase(completion: @escaping () -> Void) {
        //toggleRestorePurchasesButton(false)
        firstly {
            try Client.signIn(forceRefresh: true)
        }
        .then { (signin: SignIn) -> Promise<GetKey> in
            try Client.getKey()
        }
        .done { (getKey: GetKey) in
            // we were able to get key, so subscription is valid -- follow pathway from HomeViewController to associate this with the email account if there is one
            completion()
            
//            let presentingViewController = self.presentingViewController as? HomeViewController
//            self.dismiss(animated: true, completion: {
//                if presentingViewController != nil {
//                    presentingViewController?.toggleVPN("me")
//                }
//                else {
//                    VPNController.shared.setEnabled(true)
//                }
//            })
        }
        .catch { error in
//            self.toggleRestorePurchasesButton(true)
            DDLogError("Restore Failed: \(error)")
            if let apiError = error as? ApiError {
                switch apiError.code {
                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                    // now try email if it exists
                    if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
                        DDLogInfo("restore: have confirmed API credentials, using them")
//                        self.toggleRestorePurchasesButton(false)
                        firstly {
                            try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                        }
                        .then { (signin: SignIn) -> Promise<GetKey> in
                            DDLogInfo("restore: signin result: \(signin)")
                            return try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
//                            self.toggleRestorePurchasesButton(true)
                            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                            completion()
//                            DDLogInfo("restore: setting VPN creds with ID and Dismissing: \(getKey.id)")
//                            let presentingViewController = self.presentingViewController as? LDFirewallViewController
//                            self.dismiss(animated: true, completion: {
//                                if presentingViewController != nil {
//                                    presentingViewController?.toggleFirewall()
//                                }
//                                else {
//                                    VPNController.shared.setEnabled(true)
//                                }
//                            })
                        }
                        .catch { error in
//                            self.toggleRestorePurchasesButton(true)
                            DDLogError("restore: Error doing restore with email-login: \(error)")
                            if (self.popupErrorAsNSURLError(error)) {
                                return
                            }
                            else if let apiError = error as? ApiError {
                                switch apiError.code {
                                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                                    self.showPopupDialog(title: NSLocalizedString("No Active Subscription", comment: ""),
                                                    message: NSLocalizedString("Please ensure that you have an active subscription. If you're attempting to share a subscription from the same account, you'll need to sign in with the same email address. Otherwise, start your free trial or e-mail team@lockdownprivacy.com", comment: ""),
                                                    acceptButton: NSLocalizedString("OK", comment: ""))
                                default:
                                    _ = self.popupErrorAsApiError(error)
                                }
                            }
                        }
                    }
                    else {
                        self.showPopupDialog(title: NSLocalizedString("No Active Subscription", comment: ""),
                                        message: NSLocalizedString("Please ensure that you have an active subscription. If you're attempting to share a subscription from the same account, you'll need to sign in with the same email address. Otherwise, start your free trial or e-mail team@lockdownprivacy.com", comment: ""),
                                        acceptButton: NSLocalizedString("OK", comment: ""))
                    }
                default:
                    self.showPopupDialog(title: NSLocalizedString("Error Restoring Subscription", comment: ""),
                                         message: NSLocalizedString("Please email team@lockdownprivacy.com with the following Error Code ", comment: "") + "\(apiError.code) : \(apiError.message)",
                                         acceptButton: NSLocalizedString("OK", comment: ""))
                }
            }
            else {
                self.showPopupDialog(title: NSLocalizedString("Error Restoring Subscription", comment: ""),
                                     message: NSLocalizedString("Please make sure your Internet connection is active. If this error persists, email team@lockdownprivacy.com with the following error message: ", comment: "") + "\(error)",
                    acceptButton: NSLocalizedString("OK", comment: ""))
            }
        }
    }
}
