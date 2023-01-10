//
//  SignUpViewController.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/3/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import CocoaLumberjackSwift
import Foundation
import PopupDialog
import PromiseKit
import UIKit

final class SignUpViewController: BaseViewController, Loadable {
    
    @IBOutlet private var closeButtonSpacer: UIView!
    @IBOutlet private var closeButton: UIButton!
    
    @IBOutlet private var upperLabelsStackView: UIStackView!
    @IBOutlet private var welcomeLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    
    @IBOutlet private var emailTextField: FloatingTextInputTextField!
    @IBOutlet private var passwordTextField: FloatingTextInputTextField!
    @IBOutlet private var passwordValidationLabel: UILabel!
    
    @IBOutlet private var advantageLabelOne: UILabel!
    @IBOutlet private var advantageLabelTwo: UILabel!
    @IBOutlet private var advantageLabelThree: UILabel!
    
    @IBOutlet private var alternativeActionButton: UIButton!
    @IBOutlet private var mainButton: UIButton!
    
    @IBOutlet private var byContinuingLabel: UILabel!
    @IBOutlet private var termsOfServiceLabel: UIButton!
    @IBOutlet private var andLabel: UILabel!
    @IBOutlet private var privacyPolicyLabel: UIButton!
    
    private var signUpButtonGradientLayer: CAGradientLayer?
    
    private var mode: AuthenticationViewControllerMode {
        didSet {
            DispatchQueue.main.async {
                self.updateScreen()
            }
        }
    }
    
    private var textFieldBorderWidth: CGFloat { isDarkMode ? 2.5 : 2 }
    private var isPasswordValid = false
    private var didAutofillTextfield = false
    
    /// For cases when user is focused on a textfield and swipes back to the previous screen.
    private var isDisappearing = false
    
    init(mode: AuthenticationViewControllerMode) {
        self.mode = mode
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextFields()
        setupSkipButton()
        setupSignUpButton()
        
        setupTexts()
        
        setupGestureRecognizers()
        
        updateScreen()
        
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        navigationController?.navigationBar.tintColor = .label
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isDisappearing = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isDisappearing = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        mainButton.corners = .continuous(mainButton.bounds.midY)
        signUpButtonGradientLayer?.corners = mainButton.corners
        signUpButtonGradientLayer?.frame = mainButton.bounds
    }
    
    @IBAction private func didTapCloseButton(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction private func didTapAlternativeActionButton(_ sender: Any) {
        switch mode {
        case .login:
            // Forgot password
            guard let forgotPasswordViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "ForgotPasswordViewController")
                    as? ForgotPasswordViewController else { return }
            forgotPasswordViewController.modalPresentationStyle = .fullScreen
            present(forgotPasswordViewController, animated: true)
        case .signUp:
            // I already have an account, change to login
            mode = .login
        }
    }
    
    @IBAction private func didTapMainButton() {
        mainButton.showAnimatedPress { [weak self] in
            guard let self else { return }
            switch self.mode {
            case .signUp:
                self.createAccount()
            case .login:
                self.login()
            }
        }
    }
    
    @IBAction private func didTapTermsOfService(_ sender: Any) {
        showModalWebView(title: .localized("terms_of_service"), urlString: .lockdownUrlTerms)
    }
    
    @IBAction private func didTapPrivacyPolicy(_ sender: Any) {
        showModalWebView(title: .localized("Privacy Policy"), urlString: .lockdownUrlPrivacy)
    }
    
    private func setupTextFields() {
        [emailTextField, passwordTextField].forEach {
            $0?.titleFont = .regularLockdownFont(size: 13)
            $0?.placeholderFont = .regularLockdownFont(size: 17)
            $0?.titleColor = .gray
            $0?.textColor = .black
            $0?.corners = .continuous(8)
            $0?.delegate = self
            
            if traitCollection.layoutDirection == .rightToLeft {
                $0?.textAlignment = .right
                $0?.semanticContentAttribute = .forceRightToLeft
            }
        }
        emailTextField.addTarget(self, action: #selector(updateMainButtonState), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(validatePassword), for: .editingChanged)
    }
    
    private func setupSkipButton() {
        let skipButton = UIBarButtonItem(title: .localized("skip"), style: .plain, target: self, action: #selector(proceedToEnableNotifications))
        
        [.normal, .highlighted].forEach {
            skipButton.setTitleTextAttributes([
                .font: UIFont.regularLockdownFont(size: 17),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], for: $0)
        }
        navigationItem.rightBarButtonItem = skipButton
        
        closeButtonSpacer.isHidden = navigationController != nil
        closeButton.isHidden = navigationController != nil
    }
    
    @objc private func proceedToEnableNotifications() {
        let enableNotificationsViewController = EnableNotificationsViewController()
        navigationController?.pushViewController(enableNotificationsViewController, animated: true)
    }
    
    private func setupSignUpButton() {
        signUpButtonGradientLayer = mainButton.applyGradient(.lightBlue)
        updateMainButtonState()
    }
    
    private func setupTexts() {
        welcomeLabel.text = .localized("welcome")
        descriptionLabel.text = .localized("already_have_account_login")
        emailTextField.title = .localized("email")
        passwordTextField.title = .localized("password")
        
        advantageLabelOne.text = .localized("access_our_curated_block_lists_and_build_your_own")
        advantageLabelTwo.text = .localized("access_lockdown_across_all_your_devices")
        advantageLabelThree.text = .localized("firewall_and_vpn_support")
        
        mainButton.setTitle(.localized("onboarding_sign_up"), for: .normal)
        
        byContinuingLabel.text = .localized("by_continuing_you_agree_with_our")
        privacyPolicyLabel.setTitle(.localized("Privacy Policy"), for: .normal)
        andLabel.text = .localized("and")
        termsOfServiceLabel.setTitle(.localized("terms_of_service"), for: .normal)
    }
    
    private func setupGestureRecognizers() {
        let tapOutsideTextfields = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapOutsideTextfields)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension SignUpViewController {
    
    private func updateScreen() {
        switch mode {
        case .signUp:
            updateForSignUp()
        case .login:
            updateForLogin()
        }
    }
    
    private func updateForSignUp() {
        // So that the textfields won't trigger autofill suggestions
        // https://developer.apple.com/forums/thread/108085
        emailTextField.textContentType = .oneTimeCode
        passwordTextField.textContentType = .oneTimeCode
        
        transition(with: upperLabelsStackView) { [weak self] in
            self?.descriptionLabel.text = .localized("sign_up_to_access_new_block_lists_from_trackers")
        }
        alternativeActionButton.setTitle(.localized("already_have_account_login"), for: .normal)
    }
    
    private func updateForLogin() {
        emailTextField.textContentType = .username
        passwordTextField.textContentType = .password
        
        validatePassword()
        
        transition(with: upperLabelsStackView) { [weak self] in
            self?.descriptionLabel.text = .localized("already_have_account_login_below")
        }
        transition(with: alternativeActionButton) { [weak self] in
            self?.alternativeActionButton.setTitle(.localized("forgot_password"), for: .normal)
        }
        transition(with: mainButton) { [weak self] in
            self?.mainButton.setTitle(.localized("onboarding_login"), for: .normal)
        }
    }
}

extension SignUpViewController: UITextFieldDelegate, EmailValidatable {
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        // If the range is {0,0} and the string count > 1, then user copy paste text or used password autofill.
        didAutofillTextfield = range == NSRange(location: 0, length: 0) && string.count > 1 && mode == .login
        
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // If autofilled, don't show keyboard
        if mode == .login && didAutofillTextfield {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.didAutofillTextfield = false
            }
            
            DispatchQueue.main.async {
                self.view.endEditing(true)
                
                // Color somehow falls back to default, fixing it
                textField.textColor = .black
            }
            
            return false
        }
        
        textField.animateBorderWidth(toValue: textFieldBorderWidth)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            emailTextField.animateBorderWidth(toValue: 0)
            passwordTextField.becomeFirstResponder()
        } else {
            passwordTextField.animateBorderWidth(toValue: textFieldBorderWidth)
            dismissKeyboard()
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        guard !isDisappearing else { return }
        
        if textField == passwordTextField, textField.text?.count ?? 0 > 0, !isPasswordValid {
            textField.animateBorderWidth(toValue: textFieldBorderWidth, color: .tunnelsWarning)
        } else if textField == emailTextField, let emailError = errorValidatingEmail(emailTextField.text) {
            showPopupDialog(title: .localized("invalid_email_address"),
                            message: emailError.localizedDescription,
                            transitionStyle: .fadeIn,
                            acceptButton: .localizedOkay)
            textField.animateBorderWidth(toValue: textFieldBorderWidth, color: .tunnelsWarning)
        } else {
            textField.animateBorderWidth(toValue: 0)
        }
    }
    
    @objc private func validatePassword() {
        updateMainButtonState()
        
        guard mode == .signUp else {
            passwordTextField.animateBorderWidth(toValue: 0)
            passwordValidationLabel.isHidden = true
            isPasswordValid = true
            return
        }
        
        let passwordRequirements = """
Password must be at least 8 characters, contain at least one uppercase letter, \
one lowercase letter, one number, and one symbol.
"""
        let attrStr = NSMutableAttributedString(
            string: .localized(passwordRequirements),
            attributes: [
                .font: UIFont.mediumLockdownFont(size: 13),
                .foregroundColor: UIColor.lightGray
            ])
        
        if let txt = passwordTextField.text {
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
        
        passwordValidationLabel.attributedText = attrStr
        passwordValidationLabel.isHidden = isPasswordValid
        
        updateMainButtonState()
    }
    
    private func setupAttributeColor(if isValid: Bool) -> [NSAttributedString.Key: Any] {
        if isValid {
            return [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        } else {
            isPasswordValid = false
            return [NSAttributedString.Key.foregroundColor: UIColor.red]
        }
    }
    
    private func findRange(in baseString: String, for substring: String) -> NSRange {
        if let range = baseString.localizedStandardRange(of: substring) {
            let startIndex = baseString.distance(from: baseString.startIndex, to: range.lowerBound)
            let length = substring.count
            return NSRange(location: startIndex, length: length)
        } else {
            print("Range does not exist in the base string.")
            return NSRange(location: 0, length: 0)
        }
    }
    
    @objc private func updateMainButtonState() {
        if mode == .signUp {
            mainButton.isUserInteractionEnabled = emailTextField.text?.count ?? 0 > 0 && isPasswordValid
        } else {
            mainButton.isUserInteractionEnabled = emailTextField.text?.count ?? 0 > 0 && passwordTextField.text?.count ?? 0 > 0
        }
        mainButton.isEnabled = mainButton.isUserInteractionEnabled
        signUpButtonGradientLayer?.isHidden = !mainButton.isUserInteractionEnabled
    }
}

// MARK: - Backend
extension SignUpViewController {
    
    private func createAccount() {
        // Do /signup (do subscription-event later, user needs to confirm email first though)
        showLoadingView()
        
        // TODO: client side preliminary password fields, email validation - server does additional checking later
        
        firstly {
            try Client.signup(email: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "")
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
                        try setAPICredentials(email: self.emailTextField.text!, password: self.passwordTextField.text!)
                        setAPICredentialsConfirmed(confirmed: false)
                        let message = """
To finish signup, click the confirmation link in the email we just sent. \
If you don't see it, check if it's stuck in your spam folder.
"""
                        let popup = PopupDialog(title: .localized("confirm_your_email"),
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
                                self.proceedToEnableNotifications()
                           }
                        ])
                        self.present(popup, animated: true, completion: nil)
                        NotificationCenter.default.post(name: AccountUI.accountStateDidChange, object: self)
                    } catch {
                        self.showPopupDialog(
                            title: "Error Saving Credentials",
                            message: "Couldn't save credentials to local keychain. Please report this error to team@lockdownprivacy.com.",
                            acceptButton: .localizedOkay)
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
    
    private func login() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            showPopupDialog(title: .localized("check_fields"), message: .localized("email_and_password_must_not_be_empty"), acceptButton: .localizedOkay)
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
            self.showPopupDialog(title: .localized("Success! 🎉"),
                                 message: .localized("you_have_successfully_sign_in"),
                                 acceptButton: .localizedOkay,
                                 tapGestureDismissal: false,
                                 panGestureDismissal: false) {
                if let navigationController = self.navigationController {
                    let enableNotificationsViewController = EnableNotificationsViewController()
                    navigationController.isNavigationBarHidden = true
                    navigationController.setViewControllers([enableNotificationsViewController], animated: true)
                    self.processSuccessfulLogin()
                } else {
                    self.presentingViewController?.dismiss(animated: true) {
                        self.processSuccessfulLogin()
                    }
                }
            }
        }
        .catch { error in
            self.hideLoadingView()
            var errorMessage = error.localizedDescription
            if let apiError = error as? ApiError {
                errorMessage = apiError.message
            }
            self.showPopupDialog(
                title: .localized("error_signing_in"),
                message: errorMessage,
                transitionStyle: .zoomIn,
                acceptButton: .localizedOkay) {}
        }
    }
    
    private func processSuccessfulLogin() {
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
    }
}

enum AuthenticationViewControllerMode {
    case login, signUp
}
