//
//  MainTabBarViewController.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 02.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import UIKit

final class MainTabBarController: UITabBarController {
    
    var homeViewController: HomeViewController {
        return viewControllers![0] as! HomeViewController
    }
    
    var accountViewController: AccountViewController {
        let navigation = viewControllers![2] as! UINavigationController
        return navigation.viewControllers[0] as! AccountViewController
    }
}
