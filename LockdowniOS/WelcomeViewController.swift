//
//  WelcomeViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 18.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    let welcomeView = WelcomeView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(welcomeView)
        welcomeView.anchors.edges.pin()
        OneTimeActions.markAsSeen(.welcomeScreen)
        
        welcomeView.continueButton.addTarget(self, action: #selector(dismissed), for: .touchUpInside)
    }
    
    @objc func dismissed() {
        dismiss(animated: false) {
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            
            keyWindow?.rootViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "MainTabBarController")
            keyWindow?.makeKeyAndVisible()
        }
    }
}
