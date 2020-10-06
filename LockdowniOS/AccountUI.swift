//
//  AccountUI.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 06.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import UIKit

enum AccountUI {
    
    static func presentCreateAccount(on vc: UIViewController, completion: @escaping () -> () = { }) {
        let storyboard = UIStoryboard.main
        let viewController = storyboard.instantiateViewController(withIdentifier: "emailSignUpViewController") as! EmailSignUpViewController
        viewController.delegate.showSignIn = { [weak vc] in
            if let strongVC = vc {
                AccountUI.presentSignInToAccount(on: strongVC, completion: completion)
            }
        }
        viewController.delegate.accountStateDidChange = completion
        
        vc.present(viewController, animated: true, completion: nil)
    }
    
    static func presentSignInToAccount(on vc: UIViewController, completion: @escaping () -> () = { }) {
        let storyboard = UIStoryboard.main
        let viewController = storyboard.instantiateViewController(withIdentifier: "emailSignInViewController") as! EmailSignInViewController
        viewController.delegate.accountStateDidChange = completion
        
        vc.present(viewController, animated: true, completion: nil)
    }
}
