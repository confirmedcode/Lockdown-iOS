//
//  SignupViewController.swift
//  Tunnels
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit
import SwiftyStoreKit
import Segmentio
import NetworkExtension
import CocoaLumberjackSwift

class SignupViewController: ConfirmedBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.allDevicesPlan?.setCheckState(.checked, animated: true)
        self.iOSDevicesPlan?.setCheckState(.unchecked, animated: true)
        TunnelsSubscription.productType = 1
        
        self.allDevicesTitle?.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.tappedAllDevicesLabel)))
        self.allDevicesDescription?.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.tappedAllDevicesLabel)))

        self.iosDevicesTitle?.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.tappediosDevicesLabel)))
        self.iosDevicesDescription?.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.tappediosDevicesLabel)))

        NotificationCenter.default.addObserver(self, selector: #selector(updatePlanLabels), name: NSNotification.Name(rawValue: "Subscription Price Updated"), object: nil)
        
        updatePlanLabels()
        setupMonthlyAnnualPlans()
        
        self.monthlyAnnualToggle?.isHidden = false
        self.monthlyAnnualToggle?.selectedSegmentioIndex = 0

        
        //set up custom font sizes for languages with longer texts
        //self.allDevicesTitle.font = UIFont.init(name: self.allDevicesTitle.font.fontName, size: self.allDevicesTitle.font.pointSize - 2)
        
    }
    
    func setupMonthlyAnnualPlans() {
        self.monthlyAnnualToggle?.setup(content: [SegmentioItem(title: Global.monthly, image: nil), SegmentioItem(title: Global.annual, image: nil)], style: .onlyLabel, options: segmentioOptions())
        
        self.monthlyAnnualToggle?.selectedSegmentioIndex = 0
        
        self.monthlyAnnualToggle?.valueDidChange = { segmentio, segmentIndex in
            self.updatePlanLabels()
            self.updateSubscriptionSelection()
        }
    }
    
    @objc func updatePlanLabels() {
        
        UIView.transition(with: self.pricingSubtitle!,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            if self?.monthlyAnnualToggle?.selectedSegmentioIndex == 1 {
                                if self?.iOSDevicesPlan?.checkState == .checked {
                                    self?.pricingSubtitle?.text = String(format: NSLocalizedString("%@ per year after", comment: ""), TunnelsSubscription.localizedPriceAnnual)
                                }
                                else {
                                    self?.pricingSubtitle?.text = String(format: NSLocalizedString("%@ per year after", comment: ""), TunnelsSubscription.localizedPriceAllDevicesAnnual)
                                }
                            }
                            else {
                                if self?.iOSDevicesPlan?.checkState == .checked {
                                    self?.pricingSubtitle?.text = String(format: NSLocalizedString("%@ per month after", comment: ""), TunnelsSubscription.localizedPrice)
                                }
                                else {
                                    self?.pricingSubtitle?.text = String(format: NSLocalizedString("%@ per month after", comment: ""), TunnelsSubscription.localizedPriceAllDevices)
                                }
                            }
        })
        
        UIView.transition(with: self.allDevicesDescription!,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            if self?.monthlyAnnualToggle?.selectedSegmentioIndex == 1 {
                                self?.allDevicesDescription?.text = String(format: NSLocalizedString("Up to five devices on any platform", comment: ""), TunnelsSubscription.localizedPriceAllDevicesAnnual) + " (" + "two months free".localized() + ")"
                                
                            }
                            else {
                                self?.allDevicesDescription?.text = String(format: NSLocalizedString("Up to five devices on any platform", comment: ""), TunnelsSubscription.localizedPriceAllDevices)
                                
                            }
            }, completion: nil)
        
        UIView.transition(with: self.iosDevicesDescription!,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            if self?.monthlyAnnualToggle?.selectedSegmentioIndex == 1 {
                                self?.iosDevicesDescription?.text = String(format: NSLocalizedString("Up to three of your iPhones and iPads", comment: ""), TunnelsSubscription.localizedPriceAnnual) + " (" + "two months free".localized() + ")"
                                
                                
                            }
                            else {
                                self?.iosDevicesDescription?.text = String(format: NSLocalizedString("Up to three of your iPhones and iPads", comment: ""), TunnelsSubscription.localizedPrice)
                            }
            }, completion: nil)
       
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissSignUpScreen() {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: {})
    }
    
    @objc func tappedAllDevicesLabel(gesture : UIGestureRecognizer) {
        self.allDevicesSelected(self.allDevicesPlan!)
        updatePlanLabels()
    }
    
    @objc func tappediosDevicesLabel(gesture : UIGestureRecognizer) {
        self.iOSDevicesSelected(self.iOSDevicesPlan!)
        updatePlanLabels()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func updateSubscriptionSelection() {
        if self.allDevicesPlan?.checkState == .checked {
            if self.monthlyAnnualToggle?.selectedSegmentioIndex == 0 {
                 TunnelsSubscription.productType = 1
            }
            else {
                 TunnelsSubscription.productType = 3
            }
        }
        else {
            if self.monthlyAnnualToggle?.selectedSegmentioIndex == 0 {
                TunnelsSubscription.productType = 0
            }
            else {
                TunnelsSubscription.productType = 2
            }
        }
    }
    
    @IBAction func allDevicesSelected (_ sender: M13Checkbox) {
        self.allDevicesPlan?.setCheckState(.checked, animated: true)
        self.iOSDevicesPlan?.setCheckState(.unchecked, animated: true)
        updateSubscriptionSelection()
        updatePlanLabels()
    }
    
    @IBAction func iOSDevicesSelected (_ sender: M13Checkbox) {
        self.iOSDevicesPlan?.setCheckState(.checked, animated: true)
        self.allDevicesPlan?.setCheckState(.unchecked, animated: true)
        updateSubscriptionSelection()
        updatePlanLabels()
    }
    
    @IBAction func startFreeTrial (_ sender: UIButton) {
        //setPurchaseButtonState(button : self.purchaseTunnelsButton!, buttonState: .Loading)
        
        self.startFreeTrialButton?.isUserInteractionEnabled = false
        self.startFreeTrialButton?.startLoadingAnimation()
        blockUserInteraction()
        
        UIView.transition(with: self.pricingSubtitle!,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            self?.pricingSubtitle?.alpha = 0.0
            })
        
        TunnelsSubscription.purchaseTunnels(
            succeeded : {
                
                self.startFreeTrialButton?.isUserInteractionEnabled = true
                self.startFreeTrialButton?.setOriginalState()
                self.startFreeTrialButton?.layer.cornerRadius = 4
                self.unblockUserInteraction()
                
                var shouldShowPostboarding = true
                if NEVPNManager.shared().connection.status != .invalid {
                    shouldShowPostboarding = false
                }
                if Global.keychain[Global.kConfirmedEmail] != nil && Global.keychain[Global.kConfirmedPassword] != nil {
                    shouldShowPostboarding = false
                }
                
                if shouldShowPostboarding {
                    self.showPostboarding()
                }
                else {
                    NotificationCenter.post(name: .dismissOnboarding)
                }
                
                UIView.transition(with: self.pricingSubtitle!,
                                  duration: 0.25,
                                  options: .transitionCrossDissolve,
                                  animations: { [weak self] in
                                    self?.pricingSubtitle?.alpha = 1.0
                })
        },
            errored: {
                self.startFreeTrialButton?.isUserInteractionEnabled = true
                self.startFreeTrialButton?.setOriginalState()
                self.startFreeTrialButton?.layer.cornerRadius = 4
                self.unblockUserInteraction()
                self.showPopupDialog(title: "Error Signing Up",
                                message: "Please make sure your Internet connection is active. Otherwise, please e-mail team@confirmedvpn.com".localized(),
                                acceptButton: "OK")
                
                
                UIView.transition(with: self.pricingSubtitle!,
                                  duration: 0.25,
                                  options: .transitionCrossDissolve,
                                  animations: { [weak self] in
                                    self?.pricingSubtitle?.alpha = 1.0
                })
        })
    }
    
    func showPostboarding() {
        let stb = UIStoryboard(name: "Main", bundle: nil)
        let walkthrough = stb.instantiateViewController(withIdentifier: "postboarding") as! BWWalkthroughViewController
        
        let page_zero = stb.instantiateViewController(withIdentifier: "postboarding1")
        let page_one = stb.instantiateViewController(withIdentifier: "contentBlocker") as! ContentBlockerViewController
        let page_two = stb.instantiateViewController(withIdentifier: "whitelisting") as! WhitelistingViewController
        let page_three = stb.instantiateViewController(withIdentifier: "addEmail") as! AddEmailViewController
        page_one.isPostboarding = true
        page_two.isPostboarding = true
        page_three.isPostboarding = true
        
        // Attach the pages to the master
        walkthrough.add(viewController:page_zero)
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        //walkthrough.view.bringSubview(toFront: walkthrough.scrollview)
        walkthrough.modalTransitionStyle = .crossDissolve

        self.modalTransitionStyle = .crossDissolve
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    @IBAction func restorePurchases(_ sender: Any) {
        
        self.restorePurchasesButton?.isUserInteractionEnabled = false
        self.restorePurchasesButton?.startLoadingAnimation()
        self.blockUserInteraction()
        
        Auth.clearCookies()
        
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            
            if results.restoreFailedPurchases.count > 0 {
                DDLogError("Restore Failed: \(results.restoreFailedPurchases)")
                self.showPopupDialog(title: "Error Restoring Purchases",
                                message: "Please make sure your Internet connection is active and that you have an active subscription already. Otherwise, please start your free trial or e-mail team@confirmedvpn.com",
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
    
    @IBAction func openPrivacyPolicy (_ sender: Any) {
        let url = URL(string: "https://confirmedvpn.com/privacy")!
        UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
    @IBAction func openTermsAndConditions (_ sender: Any) {
        let url = URL(string: "https://confirmedvpn.com/terms")!
        UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
    @IBAction func cancelButtonPressed (_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.allDevicesPlan?.stateChangeAnimation = .stroke
        self.iOSDevicesPlan?.stateChangeAnimation = .stroke
        
        self.allDevicesPlan?.setCheckState(.checked, animated: true)
        self.iOSDevicesPlan?.setCheckState(.unchecked, animated: true)
       
        setupMonthlyAnnualPlans()
    }
    
    func segmentioOptions() -> SegmentioOptions {
        var font = UIFont.init(name: "Montserrat-Regular", size: 14)
        if UIDevice.current.userInterfaceIdiom == .pad {
            font = UIFont.init(name: "Montserrat-Regular", size: 20)
        }
        return SegmentioOptions(
            backgroundColor: .clear,
            segmentPosition: .dynamic,
            scrollEnabled: false,
            indicatorOptions: SegmentioIndicatorOptions(
                type: .bottom,
                ratio: 0.6,
                height: 1,
                color: UIColor.init(red: 0, green: 173.0/255.0, blue: 231.0/255.0, alpha: 1.0)
            ),
            horizontalSeparatorOptions: SegmentioHorizontalSeparatorOptions(
                type: .none
            ),
            verticalSeparatorOptions: SegmentioVerticalSeparatorOptions(
                ratio: 0.5,
                color: UIColor.init(white: 0.9, alpha: 1.0)
            ),
            imageContentMode: .scaleAspectFit,
            labelTextAlignment: .center,
            labelTextNumberOfLines: 1,
            segmentStates: SegmentioStates(
                defaultState: SegmentioState(
                    backgroundColor: .clear,
                    titleFont: font!,
                    titleTextColor: .darkGray
                ),
                selectedState: SegmentioState(
                    backgroundColor: .clear,
                    titleFont: font!,
                    titleTextColor: UIColor.init(red: 0, green: 173.0/255.0, blue: 231.0/255.0, alpha: 1.0)
                ),
                highlightedState: SegmentioState(
                    backgroundColor: .clear,
                    titleFont: font!,
                    titleTextColor: UIColor.init(red: 0, green: 173.0/255.0, blue: 231.0/255.0, alpha: 1.0)
                )
            ),
            animationDuration: 0.2
        )
    }
    
    //MARK: - VARIABLES
    
    public var didComeAfterSignin = false
    
    @IBOutlet var pricingSubtitle: UILabel?
    
    @IBOutlet var allDevicesTitle: UILabel?
    @IBOutlet var allDevicesDescription: UILabel?
    
    @IBOutlet var iosDevicesTitle: UILabel?
    @IBOutlet var iosDevicesDescription: UILabel?
    
    @IBOutlet var allDevicesPlan: M13Checkbox?
    @IBOutlet var iOSDevicesPlan: M13Checkbox?
    @IBOutlet var startFreeTrialButton: TKTransitionSubmitButton?
    @IBOutlet var restorePurchasesButton: TKTransitionSubmitButton?
    
    
    @IBOutlet var accountView: UIView?
    @IBOutlet var addEmailView: UIView?
    
    @IBOutlet var signupError: UILabel?
    @IBOutlet var monthlyAnnualToggle: Segmentio?
    

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
