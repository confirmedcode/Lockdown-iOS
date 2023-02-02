//
//  MainTabBarViewController.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 02.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import UIKit

final class MainTabBarController: UITabBarController {
    
    var homeViewController: HomeViewController? { viewControllers![0] as? HomeViewController }
    
    var accountViewController: AccountViewController? {
        guard let navigation = viewControllers![1] as? UINavigationController else { return nil }
        return navigation.viewControllers[0] as? AccountViewController
    }
    
    var accountTabBarButton: UIView? {
        // this assumes that "Account" is the last tab. Change the code if this is no longer true
        return tabBar.subviews.last(where: { String(describing: type(of: $0)) == "UITabBarButton" })
    }
}
