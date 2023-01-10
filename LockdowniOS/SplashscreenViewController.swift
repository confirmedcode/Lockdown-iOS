//
//  SplashscreenViewController.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/7/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
//

import AppTrackingTransparency
import UIKit

final class SplashscreenViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BaseUserService.shared.updateUserSubscription { [weak self] _ in
            DispatchQueue.main.async {
                self?.dismiss()
            }
        }
    }
    
    private func dismiss() {
        dismiss(animated: false) {
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            
            // Do not show onboarding if user has seen the previous onboarding or has already seen this new one
            if OneTimeActions.hasSeen(.welcomeScreen) == false,
               OneTimeActions.hasSeen(.newFancyOnboarding) == false {
                let onboardingViewController = OnboardingViewController()
                let navigation = UINavigationController(rootViewController: onboardingViewController)
                keyWindow?.rootViewController = navigation
            } else {
                keyWindow?.rootViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "MainTabBarController")
            }
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
