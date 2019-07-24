//
//  PostboardingViewController.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import SafariServices
import CocoaLumberjackSwift

class PostboardingViewController: BWWalkthroughViewController, BWWalkthroughViewControllerDelegate {

    @objc func appIsActive() {
        DDLogInfo("App active")
        if currentPage == 0 {
            if NEVPNManager.shared().connection.status == .invalid {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.postboardingActionButton?.setOriginalState()
                    self.postboardingActionButton?.layer.cornerRadius = 4
                    
                    self.postboardingActionButton?.setTitle("Get Secure".localized(), for: UIControl.State.normal)
                }
            }
        }
        if currentPage == 1 {
            refreshContentBlockerPage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.postboardingActionButton?.isEnabled = false
        self.postboardingActionButton?.backgroundColor = UIColor.darkGray
        self.delegate = self
        scrollview.isScrollEnabled = false
        
        //no need to show white listing on initial connect if we show postboarding
        UserDefaults.standard.set(true, forKey: "showedWhitelisting")
        UserDefaults.standard.synchronize()
    
        NotificationCenter.default.addObserver(self, selector: #selector(appIsActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: OperationQueue.main) { (notification) -> Void in
            if self.currentPage == 0 {
                VPNController.shared.lockdownState(completion: {(_ status: NEVPNStatus) -> Void in
                    if status == .connected || status == .connecting {
                        //advance with animation
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.postboardingActionButton?.setOriginalState()
                            self.postboardingActionButton?.layer.cornerRadius = 4
                            
                            self.postboardingActionButton?.setTitle("Continue".localized(), for: UIControl.State.normal)
                        }
                    }
                    
                })
            }
        }
                    //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "VPN Did Connect"), object: nil)
                    
                    /*UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseOut, animations: {
                     spinner.alpha = 1
                     }, completion: nil)
                     
                     connectButton?.setOriginalState()*/
            
        
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if manager.connection.status == .connected {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.postboardingActionButton?.setOriginalState()
                    self.postboardingActionButton?.layer.cornerRadius = 4
                    
                    self.postboardingActionButton?.setTitle("Continue".localized(), for: UIControl.State.normal)
                }
            }
        })
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(forName: .eulaPolicyAgreed, object: nil, queue: OperationQueue.main) { (notification) -> Void in
            self.postboardingActionButton?.isEnabled = true
            self.postboardingActionButton?.backgroundColor = .tunnelsBlueColor
            
        }
        NotificationCenter.default.addObserver(forName: .eulaPolicyDisagreed, object: nil, queue: OperationQueue.main) { (notification) -> Void in
            self.postboardingActionButton?.isEnabled = false
            self.postboardingActionButton?.backgroundColor = UIColor.darkGray
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func walkthroughPageDidChange(_ pageNumber: Int) {
        DDLogInfo("Walkthrough page change - \(pageNumber)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            if pageNumber == 4 {
                //no need to set original state
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseOut, animations: {
                        self.postboardingActionButton?.alpha = 0.0
                        self.postboardingLaterButton?.alpha = 0
                    }, completion: { _ in
                        
                    })
                }
                let addEmail = self.controllers.last as! AddEmailViewController
                addEmail.emailTextField?.becomeFirstResponder()
                return
            }
            
            self.postboardingActionButton?.setOriginalState()
            self.postboardingActionButton?.layer.cornerRadius = 4
            
            
            if pageNumber == 0 || pageNumber == 2 || pageNumber == 4 {
                self.postboardingLaterButton?.isHidden = true
            }
            else {
                if pageNumber != 1 {
                    self.postboardingLaterButton?.isHidden = false
                }
            }
            
            if self.currentPage == 0 {
                self.postboardingActionButton?.setTitle("Get Secure".localized(), for: UIControl.State.normal)
            }
            if self.currentPage == 1 {
                //content blocker {

                
            }
            if self.currentPage == 2 {
                self.postboardingActionButton?.setTitle("Save & Continue".localized(), for: UIControl.State.normal)
            }
        }
    }
    
    
    @IBAction func performLaterAction() {
        nextPage()
        
        if currentPage == 1 { //fade out
            self.postboardingActionButton?.startLoadingAnimation()
            self.postboardingActionButton?.alpha = 0
            self.postboardingActionButton?.isHidden = false
            UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseOut, animations: {
                self.postboardingActionButton?.alpha = 1.0
                self.postboardingLaterButton?.alpha = 0
            }, completion: { _ in
                self.postboardingLaterButton?.isHidden = true
            })
        }
        else {
            self.postboardingActionButton?.startLoadingAnimation()
            self.postboardingActionButton?.alpha = 1.0
            self.postboardingActionButton?.isHidden = false
            self.postboardingLaterButton?.isHidden = true
        }
    }
    
    func refreshContentBlockerPage() {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Global.contentBlockerBundleID, completionHandler: { (state, error) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.postboardingLaterButton?.frame = (self.postboardingActionButton?.frame)!
                
                if error != nil {
                    self.postboardingLaterButton?.alpha = 0
                    self.postboardingLaterButton?.isHidden = false
                    UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseOut, animations: {
                        self.postboardingActionButton?.alpha = 0
                        self.postboardingLaterButton?.alpha = 1
                    }, completion: { _ in
                        self.postboardingActionButton?.isHidden = true
                        
                    })
                }
                
                if let state = state {
                    if state.isEnabled == true {
                        self.postboardingActionButton?.alpha = 1.0
                        self.postboardingActionButton?.isHidden = false
                        self.postboardingLaterButton?.isHidden = true
                    }
                    else {
                        self.postboardingLaterButton?.alpha = 0
                        self.postboardingLaterButton?.isHidden = false
                        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseOut, animations: {
                            self.postboardingActionButton?.alpha = 0
                            self.postboardingLaterButton?.alpha = 1
                        }, completion: { _ in
                            self.postboardingActionButton?.isHidden = true
                            
                        })
                    }
                }
            }
        })
    }
    
    @IBAction func performPostboardingAction() {
        postboardingActionButton?.startLoadingAnimation()
        
        if currentPage == 0 {
            NotificationCenter.post(name: .removeEULA)
            VPNController.shared.lockdownState(completion: {(status: NEVPNStatus) in
                if status == .connected {
                    NotificationCenter.post(name: .dismissOnboarding)
                }
                else {
                    VPNController.shared.connectToLockdown()
                }
            })
        }
        if currentPage == 1{
            nextPage()
            self.postboardingActionButton?.alpha = 1.0
            self.postboardingActionButton?.isHidden = false
            self.postboardingLaterButton?.isHidden = true
        }
        if currentPage == 2 {
            nextPage()
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.postboardingLaterButton?.isHidden = true
                UIView.transition(with: self.postboardingActionButton!,
                                  duration: 0.25,
                                  options: .transitionCrossDissolve,
                                  animations: { [weak self] in
                                    self?.postboardingActionButton?.alpha = 0
                    }, completion: nil)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if let addEmail = self.controllers.last as? AddEmailViewController {
                    addEmail.emailTextField?.becomeFirstResponder()
                }
                else {
                    NotificationCenter.post(name: .dismissOnboarding)
                }
                
            }
        }
        
    }
    
    @IBOutlet weak var postboardingLaterButton: UIButton?
    @IBOutlet weak var postboardingActionButton: TKTransitionSubmitButton?
    

}
