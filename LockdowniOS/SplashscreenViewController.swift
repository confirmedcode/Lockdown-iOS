//
//  SplashscreenViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 12.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import AppTrackingTransparency
import UIKit

final class SplashscreenViewController: BaseViewController {
    
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
        dismiss(animated: false) {
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            keyWindow?.rootViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "MainTabBarController")
            keyWindow?.makeKeyAndVisible()
        }
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
