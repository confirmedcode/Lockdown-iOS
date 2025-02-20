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
                        self?.handlePurchaseSuccessful()
                    } errored: { err in
                        paywallModel.showProgress = false
                        self?.handlePurchaseFailed(error: err)
                    }
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
}
