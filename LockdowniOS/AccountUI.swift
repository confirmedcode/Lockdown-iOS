//
//  AccountUI.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 06.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import UIKit

enum AccountUI {
    
    static let accountStateDidChange = Notification.Name("AccountUIAccountStateDidChangeNotification")
    
    static func presentCreateAccount(on vc: UIViewController) {
        let storyboard = UIStoryboard.main
        let viewController = storyboard.instantiateViewController(withIdentifier: "emailSignUpViewController") as! EmailSignUpViewController
        viewController.delegate.showSignIn = { [weak vc] in
            if let strongVC = vc {
                AccountUI.presentSignInToAccount(on: strongVC)
            }
        }
        
        vc.present(viewController, animated: true, completion: nil)
    }
    
    static func presentSignInToAccount(on vc: UIViewController) {
        let storyboard = UIStoryboard.main
        let viewController = storyboard.instantiateViewController(withIdentifier: "emailSignInViewController") as! EmailSignInViewController
        
        vc.present(viewController, animated: true, completion: nil)
    }
}
