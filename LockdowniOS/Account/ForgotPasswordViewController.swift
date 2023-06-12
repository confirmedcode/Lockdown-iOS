//
//  ForgotPasswordViewController.swift
//  Lockdown
//
//  Created by Johnny Lin on 1/31/20.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation
import UIKit
import PopupDialog
import PromiseKit

class ForgotPasswordViewController: BaseViewController, Loadable {
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var emailField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        setupToHideKeyboardOnTapOnView()
        updateSubmitButton(isEnabled: false)
    }
    
    func setupToHideKeyboardOnTapOnView()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
    
    private func updateSubmitButton(isEnabled: Bool) {
        submitButton.isEnabled = isEnabled
        submitButton.backgroundColor = isEnabled ? .tunnelsBlue : .borderGray
    }
    
    @IBAction func submit() {
        guard let email = emailField.text else {
            showPopupDialog(title: "Check Fields", message: "Email must not be empty", acceptButton: "Okay")
            return
        }
        showLoadingView()
        firstly {
            try Client.forgotPassword(email: email)
        }
        .done { (success: Bool) in
            self.hideLoadingView()
            self.showPopupDialog(title: "Check Email", message: "We've sent a reset password email to you. Be sure to check any spam/junk folders, in case it got stuck there.", acceptButton: "Okay") {
                self.dismiss(animated: true, completion: nil)
            }
        }
        .catch { error in
            self.hideLoadingView()
            var errorMessage = error.localizedDescription
            if let apiError = error as? ApiError {
                errorMessage = apiError.message
            }
            self.showPopupDialog(title: "Error Sending Reset Password Email", message: errorMessage, acceptButton: "Okay") {
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text as? NSString)?.replacingCharacters(in: range, with: string) ?? ""
        updateSubmitButton(isEnabled: !text.isEmpty)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == emailField) {
            textField.resignFirstResponder()
            submit()
        }
        return false
    }
}
