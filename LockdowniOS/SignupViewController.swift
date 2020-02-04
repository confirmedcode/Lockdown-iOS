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

class SignupViewController: BaseViewController {

    //MARK: - VARIABLES
    
    @IBOutlet var monthlyPlanCheckbox: M13Checkbox!
    @IBOutlet weak var monthlyProPlanCheckbox: M13Checkbox!
    
    @IBOutlet var annualPlanCheckbox: M13Checkbox!
    @IBOutlet weak var annualProPlanCheckbox: M13Checkbox!
    
    @IBOutlet var startTrialButton: TKTransitionSubmitButton!
    @IBOutlet var pricingSubtitle: UILabel!

    @IBOutlet var restorePurchasesButton: TKTransitionSubmitButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VPNSubscription.cacheLocalizedPrices()
        selectAnnual()
    }
    
    @objc func selectMonthly() {
        monthlyPlanCheckbox.setCheckState(.checked, animated: true)
        monthlyProPlanCheckbox.setCheckState(.unchecked, animated: true)
        annualPlanCheckbox.setCheckState(.unchecked, animated: true)
        annualProPlanCheckbox.setCheckState(.unchecked, animated: true)
        VPNSubscription.selectedProductId = VPNSubscription.productIdMonthly
        updatePricingSubtitle()
    }
    
    @objc func selectMonthlyPro() {
        monthlyPlanCheckbox.setCheckState(.unchecked, animated: true)
        monthlyProPlanCheckbox.setCheckState(.checked, animated: true)
        annualPlanCheckbox.setCheckState(.unchecked, animated: true)
        annualProPlanCheckbox.setCheckState(.unchecked, animated: true)
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
        monthlyPlanCheckbox.setCheckState(.unchecked, animated: true)
        monthlyProPlanCheckbox.setCheckState(.unchecked, animated: true)
        annualPlanCheckbox.setCheckState(.checked, animated: true)
        annualProPlanCheckbox.setCheckState(.unchecked, animated: true)
        VPNSubscription.selectedProductId = VPNSubscription.productIdAnnual
        updatePricingSubtitle()
    }
    
    @IBAction func annualTapped(_ sender: Any) {
        selectAnnual()
    }
    
    @objc func selectAnnualPro() {
        monthlyPlanCheckbox.setCheckState(.unchecked, animated: true)
        monthlyProPlanCheckbox.setCheckState(.unchecked, animated: true)
        annualPlanCheckbox.setCheckState(.unchecked, animated: true)
        annualProPlanCheckbox.setCheckState(.checked, animated: true)
        VPNSubscription.selectedProductId = VPNSubscription.productIdAnnualPro
        updatePricingSubtitle()
    }
    
    @IBAction func annualProTapped(_ sender: Any) {
        selectAnnualPro()
    }
    
    @objc func updatePricingSubtitle() {
        if monthlyPlanCheckbox.checkState == .checked {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthly)
        }
        else if annualPlanCheckbox.checkState == .checked {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnual)
        }
        else if annualProPlanCheckbox.checkState == .checked {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnualPro)
        }
        else if monthlyProPlanCheckbox.checkState == .checked {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthlyPro)
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
                let presentingViewController = self.presentingViewController as? HomeViewController
                self.dismiss(animated: true, completion: {
                    if presentingViewController != nil {
                        presentingViewController?.toggleVPN("me")
                    }
                    else {
                        VPNController.shared.setEnabled(true)
                    }
                })
            },
            errored: { error in
                self.toggleStartTrialButton(true)
                DDLogError("Start Trial Failed: \(error)")
                
                if (self.popupErrorAsNSURLError(error)) {
                    return
                }
                else if (self.popupErrorAsApiError(error)) {
                    return
                }
                else {
                    self.showPopupDialog(title: NSLocalizedString("Error Starting Trial", comment: ""),
                                         message: NSLocalizedString("Please contact team@lockdownhq.com.\n\nError details:\n", comment: "") + "\(error)",
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
        toggleRestorePurchasesButton(false)
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
                    self.showPopupDialog(title: NSLocalizedString("No Active Subscription", comment: ""),
                                        message: NSLocalizedString("Please make sure your Internet connection is active and that you have an active subscription. Otherwise, please start your free trial or e-mail team@lockdownhq.com", comment: ""),
                                        acceptButton: NSLocalizedString("OK", comment: ""))
                default:
                    self.showPopupDialog(title: NSLocalizedString("Error Restoring Subscription", comment: ""),
                                         message: NSLocalizedString("Please email team@lockdownhq.com with the following Error Code ", comment: "") + "\(apiError.code) : \(apiError.message)",
                                         acceptButton: NSLocalizedString("OK", comment: ""))
                }
            }
            else {
                self.showPopupDialog(title: NSLocalizedString("Error Restoring Subscription", comment: ""),
                                     message: NSLocalizedString("Please make sure your Internet connection is active. If this error persists, email team@lockdownhq.com with the following error message: ", comment: "") + "\(error)",
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
