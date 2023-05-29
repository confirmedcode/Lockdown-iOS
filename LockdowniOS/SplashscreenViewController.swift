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
        
        BaseUserService.shared.updateUserSubscription { [weak self] subscription in
            DispatchQueue.main.async {
                
                if subscription?.planType == .monthly || subscription?.planType == .annual {
                    UserDefaults.hasSeenAdvancedPaywall = false
                    UserDefaults.hasSeenUniversalPaywall = false
                    UserDefaults.hasSeenAnonymousPaywall = true
                }
                else if subscription?.planType == .proMonthly || subscription?.planType == .proAnnual {
                    UserDefaults.hasSeenAnonymousPaywall = false
                    UserDefaults.hasSeenAdvancedPaywall = false
                    UserDefaults.hasSeenUniversalPaywall = true
                }
                else if subscription?.planType == .advancedMonthly || subscription?.planType == .advancedYearly {
                    UserDefaults.hasSeenAnonymousPaywall = false
                    UserDefaults.hasSeenAdvancedPaywall = true
                    UserDefaults.hasSeenUniversalPaywall = false
                }
                else {
                    UserDefaults.hasSeenAnonymousPaywall = false
                    UserDefaults.hasSeenAdvancedPaywall = false
                    UserDefaults.hasSeenUniversalPaywall = false
                }
                
                self?.dismiss()
            }
        }
    }
    
    private func dismiss() {
        
        dismiss(animated: false) {
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            keyWindow?.rootViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "MainTabBarController")
            keyWindow?.makeKeyAndVisible()
            
            
            
//            if OneTimeActions.hasSeen(.welcomeScreen) == false {
//                let welcomeViewController = WelcomeViewController()
//                let navigation = UINavigationController(rootViewController: welcomeViewController)
//                keyWindow?.rootViewController = navigation
//            } else {
//                let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
//                keyWindow?.rootViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "MainTabBarController")
//                keyWindow?.makeKeyAndVisible()
//            }
//            keyWindow?.makeKeyAndVisible()
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
