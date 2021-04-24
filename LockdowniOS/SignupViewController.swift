//
//  SignupViewController.swift
//  Tunnels
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import SwiftyStoreKit
import NetworkExtension
import PromiseKit
import CocoaLumberjackSwift
import StoreKit

class SignupViewController: BaseViewController {

    //MARK: - VARIABLES
    
    var parentVC: UIViewController?
    
    enum Mode {
        case newSubscription
        case upgrade(active: [Subscription.PlanType])
    }
    
    var mode = Mode.newSubscription
    
    @IBOutlet var monthlyPlanContainer: UIView!
    @IBOutlet var monthlyPlanCheckbox: M13Checkbox!
    
    @IBOutlet var monthlyProPlanContainer: UIView!
    @IBOutlet var monthlyProPlanCheckbox: M13Checkbox!
    
    @IBOutlet var annualPlanContainer: UIView!
    @IBOutlet var annualPlanCheckbox: M13Checkbox!
    
    @IBOutlet var annualProPlanContainer: UIView!
    @IBOutlet var annualProPlanCheckbox: M13Checkbox!
    
    @IBOutlet var upgradeSubscriptionHintLabel: UILabel!
    
    @IBOutlet var startTrialButton: TKTransitionSubmitButton!
    @IBOutlet var pricingSubtitle: UILabel!

    @IBOutlet var restorePurchasesButton: TKTransitionSubmitButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VPNSubscription.cacheLocalizedPrices()
        switch mode {
        case .newSubscription:
            selectAnnual()
            upgradeSubscriptionHintLabel.isHidden = true
        case .upgrade(active: let activeSubscriptions):
            configureWithActiveSubscriptions(activeSubscriptions)
            restorePurchasesButton.isHidden = true
        }
    }
    
    var disabledCheckboxes: Set<M13Checkbox> = []
    
    @objc func selectMonthly() {
        animatedSetChecked(monthlyPlanCheckbox, .checked)
        animatedSetChecked(monthlyProPlanCheckbox, .unchecked)
        animatedSetChecked(annualPlanCheckbox, .unchecked)
        animatedSetChecked(annualProPlanCheckbox, .unchecked)
        VPNSubscription.selectedProductId = VPNSubscription.productIdMonthly
        updatePricingSubtitle()
    }
    
    @objc func selectMonthlyPro() {
        animatedSetChecked(monthlyPlanCheckbox, .unchecked)
        animatedSetChecked(monthlyProPlanCheckbox, .checked)
        animatedSetChecked(annualPlanCheckbox, .unchecked)
        animatedSetChecked(annualProPlanCheckbox, .unchecked)
        VPNSubscription.selectedProductId = VPNSubscription.productIdMonthlyPro
        updatePricingSubtitle()
    }
    
    @IBAction func monthlyTapped(_ sender: Any) {
        selectMonthly()
    }
    
    @IBAction func monthlyProTapped(_ sender: Any) {
        selectMonthlyPro()
    }
    
    @objc func selectAnnual() {
        animatedSetChecked(monthlyPlanCheckbox, .unchecked)
        animatedSetChecked(monthlyProPlanCheckbox, .unchecked)
        animatedSetChecked(annualPlanCheckbox, .checked)
        animatedSetChecked(annualProPlanCheckbox, .unchecked)
        VPNSubscription.selectedProductId = VPNSubscription.productIdAnnual
        updatePricingSubtitle()
    }
    
    @IBAction func annualTapped(_ sender: Any) {
        selectAnnual()
    }
    
    @objc func selectAnnualPro() {
        animatedSetChecked(monthlyPlanCheckbox, .unchecked)
        animatedSetChecked(monthlyProPlanCheckbox, .unchecked)
        animatedSetChecked(annualPlanCheckbox, .unchecked)
        animatedSetChecked(annualProPlanCheckbox, .checked)
        VPNSubscription.selectedProductId = VPNSubscription.productIdAnnualPro
        updatePricingSubtitle()
    }
    
    @IBAction func annualProTapped(_ sender: Any) {
        selectAnnualPro()
    }
    
    @objc func updatePricingSubtitle() {
        let context: VPNSubscription.SubscriptionContext = {
            switch mode {
            case .newSubscription:
                return .new
            case .upgrade:
                return .upgrade
            }
        }()
        
        if monthlyPlanCheckbox.checkState == .checked, monthlyPlanCheckbox.isEnabled {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthly, for: context)
        }
        else if annualPlanCheckbox.checkState == .checked, annualPlanCheckbox.isEnabled {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnual, for: context)
        }
        else if annualProPlanCheckbox.checkState == .checked, annualProPlanCheckbox.isEnabled {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnualPro, for: context)
        }
        else if monthlyProPlanCheckbox.checkState == .checked, monthlyProPlanCheckbox.isEnabled {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthlyPro, for: context)
        }
    }
    
    @IBAction func dismissSignUpScreen() {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: {})
    }
    
    func toggleStartTrialButton(_ enabled: Bool) {
        if (enabled) {
            UIView.transition(with: self.pricingSubtitle,
                              duration: 0.15,
                              options: .transitionCrossDissolve,
                              animations: {
                                self.pricingSubtitle.alpha = 1.0
            })
            startTrialButton.isUserInteractionEnabled = true
            startTrialButton.setOriginalState()
            startTrialButton.layer.cornerRadius = 4
            unblockUserInteraction()
        }
        else {
            UIView.transition(with: self.pricingSubtitle,
                              duration: 0.15,
                              options: .transitionCrossDissolve,
                              animations: {
                                self.pricingSubtitle.alpha = 0.0
            })
            startTrialButton.isUserInteractionEnabled = false
            startTrialButton.startLoadingAnimation()
            blockUserInteraction()
        }
    }
    
    @IBAction func startTrial (_ sender: UIButton) {
        toggleStartTrialButton(false)
        VPNSubscription.purchase (
            succeeded: {
                self.dismiss(animated: true, completion: {
                    if let presentingViewController = self.parentVC as? AccountViewController {
                        presentingViewController.reloadTable()
                    }
                    // force refresh receipt, and sync with email if it exists, activate VPNte
                    if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
                        DDLogInfo("purchase complete: syncing with confirmed email")
                        firstly {
                            try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                        }
                        .then { (signin: SignIn) -> Promise<SubscriptionEvent> in
                            DDLogInfo("purchase complete: signin result: \(signin)")
                            return try Client.subscriptionEvent(forceRefresh: true)
                        }
                        .then { (result: SubscriptionEvent) -> Promise<GetKey> in
                            DDLogInfo("purchase complete: subscriptionevent result: \(result)")
                            return try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
                            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                            DDLogInfo("purchase complete: setting VPN creds with ID: \(getKey.id)")
                            VPNController.shared.setEnabled(true)
                        }
                        .catch { error in
                            DDLogError("purchase complete: Error: \(error)")
                            if (self.popupErrorAsNSURLError("Error activating Secure Tunnel: \(error)")) {
                                return
                            }
                            else if let apiError = error as? ApiError {
                                switch apiError.code {
                                default:
                                    _ = self.popupErrorAsApiError("API Error activating Secure Tunnel: \(error)")
                                }
                            }
                        }
                    }
                    else {
                        firstly {
                            try Client.signIn(forceRefresh: true) // this will fetch and set latest receipt, then submit to API to get cookie
                        }
                        .then { (signin: SignIn) -> Promise<GetKey> in
                            // TODO: don't always do this -- if we already have a key, then only do it once per day max
                            try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
                            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                            VPNController.shared.setEnabled(true)
                        }
                        .catch { error in
                            DDLogError("purchase complete - no email: Error: \(error)")
                            if (self.popupErrorAsNSURLError("Error activating Secure Tunnel: \(error)")) {
                                return
                            }
                            else if let apiError = error as? ApiError {
                                switch apiError.code {
                                default:
                                    _ = self.popupErrorAsApiError("API Error activating Secure Tunnel: \(error)")
                                }
                            }
                        }
                    }
                })
            },
            errored: { error in
                self.toggleStartTrialButton(true)
                DDLogError("Start Trial Failed: \(error)")
                
                if let skError = error as? SKError {
                    var errorText = ""
                    switch skError.code {
                    case .unknown: errorText = NSLocalizedString("Unknown error. Please contact support at team@lockdownprivacy.com.", comment: "")
                    case .clientInvalid: errorText = NSLocalizedString("Not allowed to make the payment", comment: "")
                    case .paymentCancelled: errorText = NSLocalizedString("Payment was cancelled", comment: "")
                    case .paymentInvalid: errorText = NSLocalizedString("The purchase identifier was invalid", comment: "")
                    case .paymentNotAllowed: errorText = NSLocalizedString("Payment not allowed.\nEither this device is not allowed to make purchases, or In-App Purchases have been disabled. Please allow them in Settings App -> Screen Time -> Restrictions -> App Store -> In-app Purchases. Then try again.", comment: "")
                    case .storeProductNotAvailable: errorText = NSLocalizedString("The product is not available in the current storefront", comment: "")
                    case .cloudServicePermissionDenied: errorText = NSLocalizedString("Access to cloud service information is not allowed", comment: "")
                    case .cloudServiceNetworkConnectionFailed: errorText = NSLocalizedString("Could not connect to the network", comment: "")
                    case .cloudServiceRevoked: errorText = NSLocalizedString("User has revoked permission to use this cloud service", comment: "")
                    default: errorText = skError.localizedDescription
                    }
                    self.showPopupDialog(title: NSLocalizedString("Error Starting Trial", comment: ""),
                                         message: errorText,
                        acceptButton: "Okay")
                }
                else if (self.popupErrorAsNSURLError(error)) {
                    return
                }
                else if (self.popupErrorAsApiError(error)) {
                    return
                }
                else {
                    self.showPopupDialog(title: NSLocalizedString("Error Starting Trial", comment: ""),
                                         message: NSLocalizedString("Please contact team@lockdownprivacy.com.\n\nError details:\n", comment: "") + "\(error)",
                        acceptButton: "Okay")
                }
        })
    }
    
    func toggleRestorePurchasesButton(_ enabled: Bool) {
        if (enabled) {
            restorePurchasesButton.isUserInteractionEnabled = true
            restorePurchasesButton.setOriginalState()
            restorePurchasesButton.layer.cornerRadius = 4
            unblockUserInteraction()
        }
        else {
            restorePurchasesButton.isUserInteractionEnabled = false
            restorePurchasesButton.startLoadingAnimation()
            blockUserInteraction()
        }
    }
    
    @IBAction func restorePurchases(_ sender: Any) {
        //toggleRestorePurchasesButton(false)
        firstly {
            try Client.signIn(forceRefresh: true)
        }
        .then { (signin: SignIn) -> Promise<GetKey> in
            try Client.getKey()
        }
        .done { (getKey: GetKey) in
            // we were able to get key, so subscription is valid -- follow pathway from HomeViewController to associate this with the email account if there is one
            let presentingViewController = self.presentingViewController as? HomeViewController
            self.dismiss(animated: true, completion: {
                if presentingViewController != nil {
                    presentingViewController?.toggleVPN("me")
                }
                else {
                    VPNController.shared.setEnabled(true)
                }
            })
        }
        .catch { error in
            self.toggleRestorePurchasesButton(true)
            DDLogError("Restore Failed: \(error)")
            if let apiError = error as? ApiError {
                switch apiError.code {
                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                    // now try email if it exists
                    if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
                        DDLogInfo("restore: have confirmed API credentials, using them")
                        self.toggleRestorePurchasesButton(false)
                        firstly {
                            try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                        }
                        .then { (signin: SignIn) -> Promise<GetKey> in
                            DDLogInfo("restore: signin result: \(signin)")
                            return try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
                            self.toggleRestorePurchasesButton(true)
                            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                            DDLogInfo("restore: setting VPN creds with ID and Dismissing: \(getKey.id)")
                            let presentingViewController = self.presentingViewController as? HomeViewController
                            self.dismiss(animated: true, completion: {
                                if presentingViewController != nil {
                                    presentingViewController?.toggleVPN("me")
                                }
                                else {
                                    VPNController.shared.setEnabled(true)
                                }
                            })
                        }
                        .catch { error in
                            self.toggleRestorePurchasesButton(true)
                            DDLogError("restore: Error doing restore with email-login: \(error)")
                            if (self.popupErrorAsNSURLError(error)) {
                                return
                            }
                            else if let apiError = error as? ApiError {
                                switch apiError.code {
                                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                                    self.showPopupDialog(title: NSLocalizedString("No Active Subscription", comment: ""),
                                                    message: NSLocalizedString("Please ensure that you have an active subscription. If you're attempting to share a subscription from the same account, you'll need to sign in with the same email address. Otherwise, start your free trial or e-mail team@lockdownprivacy.com", comment: ""),
                                                    acceptButton: NSLocalizedString("OK", comment: ""))
                                default:
                                    _ = self.popupErrorAsApiError(error)
                                }
                            }
                        }
                    }
                    else {
                        self.showPopupDialog(title: NSLocalizedString("No Active Subscription", comment: ""),
                                        message: NSLocalizedString("Please ensure that you have an active subscription. If you're attempting to share a subscription from the same account, you'll need to sign in with the same email address. Otherwise, start your free trial or e-mail team@lockdownprivacy.com", comment: ""),
                                        acceptButton: NSLocalizedString("OK", comment: ""))
                    }
                default:
                    self.showPopupDialog(title: NSLocalizedString("Error Restoring Subscription", comment: ""),
                                         message: NSLocalizedString("Please email team@lockdownprivacy.com with the following Error Code ", comment: "") + "\(apiError.code) : \(apiError.message)",
                                         acceptButton: NSLocalizedString("OK", comment: ""))
                }
            }
            else {
                self.showPopupDialog(title: NSLocalizedString("Error Restoring Subscription", comment: ""),
                                     message: NSLocalizedString("Please make sure your Internet connection is active. If this error persists, email team@lockdownprivacy.com with the following error message: ", comment: "") + "\(error)",
                    acceptButton: NSLocalizedString("OK", comment: ""))
            }
        }
    }
    
    @IBAction func openPrivacyPolicy (_ sender: Any) {
        self.showPrivacyPolicyModal()
    }
    
    @IBAction func openTermsAndConditions (_ sender: Any) {
        self.showTermsModal()
    }
    
    @IBAction func cancelButtonPressed (_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

extension SignupViewController {
    
    // MARK: - Functions for "Upgrade Plan" mode
    
    private func configureWithActiveSubscriptions(_ activePlans: [Subscription.PlanType]) {
        startTrialButton.setTitle(NSLocalizedString("Upgrade Plan", comment: ""), for: .normal)
        
        for plan in activePlans {
            configureForUnavailable(plan, reason: .purchased)
            if let unavailableToUpgrade = plan.unavailableToUpgrade {
                for unavailable in unavailableToUpgrade where unavailable != plan {
                    configureForUnavailable(unavailable, reason: .lowerTierThanPurchased)
                }
            }
        }
        
        selectAnnualOrFirstAvailable()
    }
    
    enum UnavailableReason {
        case purchased
        case lowerTierThanPurchased
    }
    
    private func configureForUnavailable(_ subscriptionPlanType: Subscription.PlanType, reason: UnavailableReason) {
        switch subscriptionPlanType {
        case .monthly:
            markAsUnavailable(monthlyPlanCheckbox, plan: subscriptionPlanType, reason: reason, container: monthlyPlanContainer)
        case .proMonthly:
            markAsUnavailable(monthlyProPlanCheckbox, plan: subscriptionPlanType, reason: reason, container: monthlyProPlanContainer)
        case .annual:
            markAsUnavailable(annualPlanCheckbox, plan: subscriptionPlanType, reason: reason, container: annualPlanContainer)
        case .proAnnual:
            markAsUnavailable(annualProPlanCheckbox, plan: subscriptionPlanType, reason: reason, container: annualProPlanContainer)
        default:
            break
        }
    }
    
    private func markAsUnavailable(_ checkbox: M13Checkbox, plan: Subscription.PlanType, reason: UnavailableReason, container: UIView) {
        disabledCheckboxes.insert(checkbox)
        checkbox.isEnabled = false
        
        switch reason {
        case .lowerTierThanPurchased:
            container.isHidden = true
        case .purchased:
            container.alpha = 0.4
            checkbox.setCheckState(.checked, animated: false)
            checkbox.tintColor = UIColor.gray
            checkbox.secondaryTintColor = UIColor.gray
            checkbox.isEnabled = false
            checkbox.accessibilityLabel = Accessibility.currentPlanCheckboxLabel(for: plan)
            checkbox.accessibilityHint = Accessibility.currentPlanCheckboxHint()
        }
    }
    
    private func animatedSetChecked(_ checkbox: M13Checkbox, _ state: M13Checkbox.CheckState) {
        if disabledCheckboxes.contains(checkbox) {
            return
        } else {
            checkbox.setCheckState(state, animated: true)
        }
    }
    
    func selectAnnualOrFirstAvailable() {
        if disabledCheckboxes.contains(annualPlanCheckbox) {
            // Annual is unavailable, find first available option to select
            if monthlyPlanCheckbox.isEnabled {
                selectMonthly()
            } else if annualPlanCheckbox.isEnabled {
                selectAnnual()
            } else if monthlyProPlanCheckbox.isEnabled {
                selectMonthlyPro()
            } else if annualProPlanCheckbox.isEnabled {
                selectAnnualPro()
            } else {
                selectAnnualPro()
                startTrialButton.isEnabled = false
                startTrialButton.backgroundColor = UIColor.gray
                startTrialButton.isUserInteractionEnabled = false
                startTrialButton.alpha = 0.5
                pricingSubtitle.alpha = 0.3
            }
        } else {
            selectAnnual()
        }
    }
}

extension SignupViewController {
    enum Accessibility {
        static func currentPlanCheckboxLabel(for plan: Subscription.PlanType) -> String? {
            switch plan {
            case .monthly:
                return NSLocalizedString("\"iOS Monthly\" is your current plan", comment: "")
            case .proMonthly:
                return NSLocalizedString("\"Pro Monthly\" is your current plan", comment: "")
            case .annual:
                return NSLocalizedString("\"iOS Annual\" is your current plan", comment: "")
            case .proAnnual:
                return NSLocalizedString("\"Pro Annual\" is your current plan", comment: "")
            default:
                return "\"\(plan.rawValue)\" is your current plan"
            }
        }
        
        static func currentPlanCheckboxHint() -> String? {
            return nil
        }
    }
}
