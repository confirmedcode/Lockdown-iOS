//
//  EmailSignInViewController.swift
//  Lockdown
//
//  Created by Johnny Lin on 12/12/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//
// https://medium.com/jen-hamilton/swift-4-password-validation-helper-methods-f98a7ea5dcbb

import Foundation
import UIKit
import PopupDialog
import PromiseKit
import CocoaLumberjackSwift

class EmailSignInViewController: BaseViewController, UITextFieldDelegate, Loadable {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        passwordField.delegate = self
        setupToHideKeyboardOnTapOnView()
    }
    
    func setupToHideKeyboardOnTapOnView() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            textField.resignFirstResponder()
            signIn()
        }
        return false
    }
    
    @IBAction func signIn() {
        guard let email = emailField.text, let password = passwordField.text else {
            showPopupDialog(title: .localized("check_fields"), message: .localized("email_and_password_must_not_be_empty"), acceptButton: "Okay")
            return
        }
        
        showLoadingView()
        firstly {
            try Client.signInWithEmail(email: email, password: password)
        }
        .done { (_: SignIn) in
            try setAPICredentials(email: email, password: password)
            setAPICredentialsConfirmed(confirmed: true)
            self.hideLoadingView()
            NotificationCenter.default.post(name: AccountUI.accountStateDidChange, object: self)
            self.showPopupDialog(title: .localized("Success! 🎉"), message: "You've successfully signed in.", acceptButton: "Okay") {
                self.presentingViewController?.dismiss(animated: true, completion: {
                    // logged in and confirmed - update this email with the receipt and refresh VPN credentials
                    firstly { () -> Promise<SubscriptionEvent> in
                        try Client.subscriptionEvent()
                    }
                    .then { (_: SubscriptionEvent) -> Promise<GetKey> in
                        try Client.getKey()
                    }
                    .done { (getKey: GetKey) in
                        try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                        if getUserWantsVPNEnabled() {
                            VPNController.shared.restart()
                        }
                    }
                    .catch { error in
                        // it's okay for this to error out with "no subscription in receipt"
                        DDLogError("HomeViewController ConfirmEmail subscriptionevent error (ok for it to be \"no subscription in receipt\"): \(error)")
                    }
                    
                })
            }
        }
        .catch { error in
            self.hideLoadingView()
            var errorMessage = error.localizedDescription
            if let apiError = error as? ApiError {
                errorMessage = apiError.message
            }
            self.showPopupDialog(title: .localized("error_signing_in"), message: errorMessage, acceptButton: .localizedOkay) {
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
