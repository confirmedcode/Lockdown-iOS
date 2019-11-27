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
    @IBOutlet var monthlyTitle: UILabel!
    @IBOutlet var monthlyDescription: UILabel!
    
    @IBOutlet var annualPlanCheckbox: M13Checkbox!
    @IBOutlet var annualTitle: UILabel!
    @IBOutlet var annualDescription: UILabel!
    
    @IBOutlet var startTrialButton: TKTransitionSubmitButton!
    @IBOutlet var pricingSubtitle: UILabel!

    @IBOutlet var restorePurchasesButton: TKTransitionSubmitButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VPNSubscription.cacheLocalizedPrices()
        selectAnnual()
    }
    
    @objc func selectMonthly() {
        annualPlanCheckbox.setCheckState(.unchecked, animated: true)
        monthlyPlanCheckbox.setCheckState(.checked, animated: true)
        VPNSubscription.selectedProductId = VPNSubscription.productIdMonthly
        updatePricingSubtitle()
    }
    
    @IBAction func monthlyTapped(_ sender: Any) {
        selectMonthly()
    }
    
    @objc func selectAnnual() {
        monthlyPlanCheckbox.setCheckState(.unchecked, animated: true)
        annualPlanCheckbox.setCheckState(.checked, animated: true)
        VPNSubscription.selectedProductId = VPNSubscription.productIdAnnual
        updatePricingSubtitle()
    }
    
    @IBAction func annualTapped(_ sender: Any) {
        selectAnnual()
    }
    
    @objc func updatePricingSubtitle() {
        if monthlyPlanCheckbox.checkState == .checked {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthly)
        }
        else if annualPlanCheckbox.checkState == .checked {
            pricingSubtitle.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnual)
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
                    // TODO: show onboarding, and THEN activate VPN
                    VPNController.shared.setEnabled(true)
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
            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
            self.dismiss(animated: true, completion: {
                VPNController.shared.setEnabled(true)
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
