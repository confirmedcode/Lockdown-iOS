//
//  SignInViewController.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import TextFieldEffects
import SwiftyStoreKit
import CocoaLumberjackSwift
import NetworkExtension

class SignInViewController: ConfirmedBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DDLogInfo("Height for button \(self.signinButton?.frame.height ?? 0)")
        
    }

    override func viewDidAppear(_ animated: Bool) {
        self.emailTextField?.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissSignInScreen() {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: {})
    }
    
    func showErrorMessage(errorString : String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.signinButton?.normalCornerRadius = 4
            self.signinError?.text = errorString
            self.signinButton?.isUserInteractionEnabled = true
            self.signinButton?.setOriginalState()
            self.signinButton?.layer.cornerRadius = 4
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                self.signinError?.alpha = 1
            }, completion: { (finished: Bool) in
            })
        }
    }
    
    func hideErrorMessage() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                self.signinError?.alpha = 0
            }, completion: { (finished: Bool) in
                self.signinError?.text = ""
            })
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showSubscriptionScreenAfterSignin" {
            if let vc = segue.destination as? SignupViewController {
                vc.didComeAfterSignin = true
            }
        }
    }
    
    @IBAction func restorePurchasesTapped() {
        self.restorePurchasesButton?.isUserInteractionEnabled = false
        self.restorePurchasesButton?.startLoadingAnimation()
        self.blockUserInteraction()
        
        Auth.clearCookies()
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            
            if results.restoreFailedPurchases.count > 0 {
                DDLogError("Restore Failed: \(results.restoreFailedPurchases)")
                self.showPopupDialog(title: "Error Restoring Purchases",
                                     message: "Please make sure your Internet connection is active and that you have an active subscription already. Otherwise, please start your free trial or e-mail team@confirmedvpn.com".localized(),
                                     acceptButton: "OK")
                
               
                self.restorePurchasesButton?.isUserInteractionEnabled = true
                self.restorePurchasesButton?.setOriginalState()
                self.restorePurchasesButton?.layer.cornerRadius = 4
                self.unblockUserInteraction()
            }
            else if results.restoredPurchases.count > 0 {
                DDLogInfo("Restore Success: \(results.restoredPurchases)")
                TunnelsSubscription.isSubscribed(
                    refreshITunesIfNeeded: true,
                    isSubscribed:
                    {
                        DDLogInfo("Is subscribed")
                        
                        self.restorePurchasesButton?.isUserInteractionEnabled = true
                        self.restorePurchasesButton?.setOriginalState()
                        self.restorePurchasesButton?.layer.cornerRadius = 4
                        
                        NotificationCenter.post(name: .dismissOnboarding)
                        
                        self.unblockUserInteraction()
                },
                    isNotSubscribed:
                    {
                        DDLogInfo("Subscription not active")
                        self.unblockUserInteraction()
                        self.showPopupDialog(title: "No Active Subscription",
                                             message: "Please make sure your Internet connection is active and that you have an active subscription already. Otherwise, please start your free trial or e-mail team@confirmedvpn.com",
                                             acceptButton: "OK")
                        
                        
                        self.restorePurchasesButton?.isUserInteractionEnabled = true
                        self.restorePurchasesButton?.setOriginalState()
                        self.restorePurchasesButton?.layer.cornerRadius = 4
                        
                })
            }
            else {
                DDLogInfo("Nothing to Restore")
                self.unblockUserInteraction()
                self.showPopupDialog(title: "No Active Subscription",
                                     message: "Please make sure your Internet connection is active and that you have an active subscription already. Otherwise, please start your free trial or e-mail team@confirmedvpn.com",
                                     acceptButton: "OK")                
            }
        }
    }
    
    @IBAction func forgotPasswordTapped() {
        UIApplication.shared.open(URL(string: Global.forgotPasswordURL)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
    func showPostboarding() {
        let stb = UIStoryboard(name: "Main", bundle: nil)
        let walkthrough = stb.instantiateViewController(withIdentifier: "postboarding") as! BWWalkthroughViewController
        
        let page_zero = stb.instantiateViewController(withIdentifier: "postboarding1")
        let page_one = stb.instantiateViewController(withIdentifier: "contentBlocker") as! ContentBlockerViewController
        //let page_two = stb.instantiateViewController(withIdentifier: "whitelisting") as! WhitelistingViewController
        page_one.isPostboarding = true
        //page_two.isPostboarding = true
        
        // Attach the pages to the master
        walkthrough.add(viewController:page_zero)
        walkthrough.add(viewController:page_one)
        //walkthrough.add(viewController:page_two)
        //walkthrough.view.bringSubview(toFront: walkthrough.scrollview)
        walkthrough.modalTransitionStyle = .crossDissolve
        
        self.modalTransitionStyle = .crossDissolve
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    @IBAction func signInUser() {
        self.signinButton?.isUserInteractionEnabled = false
        self.signinButton?.startLoadingAnimation()
        hideErrorMessage()
        
        //validate e-mail/password length
        let email = self.emailTextField?.text
        let password = self.passwordTextField?.text
        
        if email == nil || password == nil {
            showErrorMessage(errorString: "Please enter your e-mail and password.")
            return
        }
        if !Utils.isValidEmail(emailAddress: email!) {
            showErrorMessage(errorString: "Please enter a valid e-mail.".localized())
            return
        }
        
        Auth.clearCookies()
        
        Auth.signInForCookie(email:email, password: password, cookieCallback: { (status, code) in
            if status {
                
                Auth.getKey(callback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
                    if status {
                        //dismiss whether its modal window or onboarding
                        TunnelsSubscription.isSubscribed(
                            refreshITunesIfNeeded: false,
                            isSubscribed:
                            {
                                var shouldShowPostboarding = true
                                if NEVPNManager.shared().connection.status != .invalid {
                                    shouldShowPostboarding = false
                                }
                                
                                if shouldShowPostboarding {
                                    self.showPostboarding()
                                }
                                else {
                                    NotificationCenter.post(name: .dismissOnboarding)
                                    self.dismiss(animated: true, completion: nil)
                                }
                        },
                            isNotSubscribed:
                            {
                                //TODO: Add not subscribed here
                        })
                    }
                    else {
                        //check if e-mail is confirmed here
                        if errorCode == Global.kEmailNotConfirmed {
                            self.showErrorMessage(errorString: "Please confirm your e-mail with the confirmation link and try again (check spam if you don't see a message from us).")
                        }
                        else if errorCode == 6 {
                            //TODO: Add not subscribed here too
                            //if payment is missing, request user to pay?
                            //self.performSegue(withIdentifier: "showSubscriptionScreenAfterSignin", sender: self)
                            //show postboarding since subscription not required
                            self.showPostboarding()
                        }
                        else {
                            self.showErrorMessage(errorString: reason)
                        }
                    }
                })
            }
            else {
                //failed here
                if code == Global.kInvalidAuth || code == Global.kIncorrectLogin {
                    self.showErrorMessage(errorString: "Login failed: please make sure your e-mail & password are correct.")
                }
                else if code == Global.kTooManyRequests {
                    self.showErrorMessage(errorString: "Too many requests: please wait a few minutes before trying again.")
                }
                else if code == Global.kEmailNotConfirmed {
                    self.showErrorMessage(errorString: "Please check your e-mail for a confirmation link and try again (check spam if you don't see a message from us).")
                }
                else {
                    self.showErrorMessage(errorString: "Please make sure your Internet is active.")
                }
            }
        })
    }

    @IBOutlet var restorePurchasesButton: TKTransitionSubmitButton?
    @IBOutlet var signinButton: TKTransitionSubmitButton?
    @IBOutlet var emailTextField: HoshiTextField?
    @IBOutlet var passwordTextField: HoshiTextField?
    @IBOutlet var signinError: UILabel?
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
