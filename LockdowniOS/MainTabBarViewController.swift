//
//  MainTabBarViewController.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 02.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import UIKit

final class MainTabBarController: UITabBarController {
    
    var fireWallViewController: LDFirewallViewController? { viewControllers![0] as? LDFirewallViewController }
    
    var vpnViewController: LDVpnViewController? { viewControllers![1] as? LDVpnViewController }
    
    var configurationViewController: LDConfigurationViewController? { viewControllers![2] as? LDConfigurationViewController }

    var accountViewController: AccountViewController? {
        for viewController in viewControllers ?? [] {
            if let navigationController = viewController as? UINavigationController,
               let accountViewController = navigationController.viewControllers.first as? AccountViewController {
                return accountViewController
            }
        }
        return nil
    }

    var homeViewController: HomeViewController? {
        if let homeVC = viewControllers?.first(where: { $0 is HomeViewController }) {
            return homeVC as? HomeViewController
        }
        return nil
    }

    override func viewDidLoad() {
         super.viewDidLoad()

        guard let homeViewController else { return }
        homeViewController.feedbackFlow = FeedbackFlow(presentingViewController: homeViewController, purchaseHandler: homeViewController)

        guard let accountViewController else { return }
        accountViewController.feedbackFlow = FeedbackFlow(presentingViewController: accountViewController, purchaseHandler: homeViewController)
    }

    var accountTabBarButton: UIView? {
        // this assumes that "Account" is the last tab. Change the code if this is no longer true
        return tabBar.subviews.last(where: { String(describing: type(of: $0)) == "UITabBarButton" })
    }
}
