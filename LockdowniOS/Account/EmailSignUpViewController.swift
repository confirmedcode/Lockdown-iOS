//
//  EmailSignUpViewController.swift
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

class EmailSignUpViewController: BaseViewController, UITextFieldDelegate, Loadable {
    
    struct Delegate {
        var showSignIn: () -> Void = { }
    }
    
    var delegate = Delegate()
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var lblPasswordValidation: UILabel!
    var isPasswordValid = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaults.set(true, forKey: kHasSeenEmailSignup)
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
    
    @IBAction func passwordFieldDidChange(_ textField: UITextField) {
        let passwordRequirements = """
Password must be at least 8 characters, contain at least one uppercase letter, \
one lowercase letter, one number, and one symbol.
"""
        let attrStr = NSMutableAttributedString(
            string: .localized(passwordRequirements),
            attributes: [
                .font: UIFont(name: "Montserrat-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.lightGray
            ])
        
        if let txt = passwordField.text {
                isPasswordValid = true
                attrStr.addAttributes(setupAttributeColor(if: (txt.count >= 8)),
                                      range: findRange(in: attrStr.string, for: .localized("at least 8 characters")))
                attrStr.addAttributes(setupAttributeColor(if: (txt.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil)),
                                      range: findRange(in: attrStr.string, for: .localized("one uppercase letter")))
                attrStr.addAttributes(setupAttributeColor(if: (txt.rangeOfCharacter(from: CharacterSet.lowercaseLetters) != nil)),
                                      range: findRange(in: attrStr.string, for: .localized("one lowercase letter")))
                attrStr.addAttributes(setupAttributeColor(if: (txt.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil)),
                                      range: findRange(in: attrStr.string, for: .localized("one number")))
            attrStr.addAttributes(setupAttributeColor(if: ((txt.rangeOfCharacter(from: CharacterSet.symbols) != nil)
                                                           || (txt.rangeOfCharacter(from: CharacterSet.punctuationCharacters) != nil))),
                                  range: findRange(in: attrStr.string, for: .localized("one symbol")))
            } else {
                isPasswordValid = false
            }
        
        lblPasswordValidation.attributedText = attrStr
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            textField.resignFirstResponder()
            createAccount()
        }
        return false
    }
    
    @IBAction func createAccount() {
        // Do /signup (do subscription-event later, user needs to confirm email first though)
        showLoadingView()
        
        // TODO: client side preliminary password fields, email validation - server does additional checking later
        
        firstly {
            try Client.signup(email: self.emailField.text ?? "", password: self.passwordField.text ?? "")
        }
        .catch { error in
            self.hideLoadingView()
            if self.popupErrorAsNSURLError(error) {
                return
            } else if let apiError = error as? ApiError {
                switch apiError.code {
                case kApiCodeEmailNotConfirmed:
                    // This is the "correct" case for /signup, we are expecting "1" = email confirmation sent
                    do {
                        try setAPICredentials(email: self.emailField.text!, password: self.passwordField.text!)
                        setAPICredentialsConfirmed(confirmed: false)
                        let message = """
To finish signup, click the confirmation link in the email we just sent. \
If you don't see it, check if it's stuck in your spam folder.
"""
                        let popup = PopupDialog(title: "Confirm Your Email",
                                                message: .localized(message),
                                                image: nil,
                                                buttonAlignment: .horizontal,
                                                transitionStyle: .bounceDown,
                                                preferredWidth: 270,
                                                tapGestureDismissal: true,
                                                panGestureDismissal: false,
                                                hideStatusBar: false,
                                                completion: nil)
                        popup.addButtons([
                            DefaultButton(title: .localizedOkay, dismissOnTap: true) {
                                self.hideLoadingView()
                                self.presentingViewController?.dismiss(animated: true, completion: nil)
                           }
                        ])
                        self.present(popup, animated: true, completion: nil)
                        NotificationCenter.default.post(name: AccountUI.accountStateDidChange, object: self)
                    } catch {
                        self.showPopupDialog(
                            title: "Error Saving Credentials",
                            message: "Couldn't save credentials to local keychain. Please report this error to team@lockdownprivacy.com.",
                            acceptButton: "Okay")
                    }
                default:
                    _ = self.popupErrorAsApiError(error)
                }
            } else {
                self.showPopupDialog(title: .localized("Error Creating Email Account"),
                                     message: "\(error)",
                                     acceptButton: .localizedOkay)
            }
        }
    }
    
    @IBAction func signInClicked(_ sender: Any) {
        dismiss(animated: true, completion: {
            self.delegate.showSignIn()
        })
    }
    
    func setupAttributeColor(if isValid: Bool) -> [NSAttributedString.Key: Any] {
        if isValid {
            return [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        } else {
            isPasswordValid = false
            return [NSAttributedString.Key.foregroundColor: UIColor.red]
        }
    }

    func findRange(in baseString: String, for substring: String) -> NSRange {
        if let range = baseString.localizedStandardRange(of: substring) {
            let startIndex = baseString.distance(from: baseString.startIndex, to: range.lowerBound)
            let length = substring.count
            return NSRange(location: startIndex, length: length)
        } else {
            print("Range does not exist in the base string.")
            return NSRange(location: 0, length: 0)
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
