//
//  InstallVPNViewController.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import CocoaLumberjackSwift

class InstallVPNViewController: BWWalkthroughViewController {

    // MARK: - OVERRIDES
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DDLogInfo("Showing install View")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(appIsActive), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: NEVPNManager.shared().connection, queue: OperationQueue.main) { (notification) -> Void in
            VPNController.shared.lockdownState(completion: { status in
                if status != .invalid {
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }
        
        NotificationCenter.default.addObserver(forName: .appActive, object: nil, queue: OperationQueue.main) { (notification) -> Void in
            VPNController.shared.lockdownState(completion: { status in
                if status != .invalid {
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }
        
        self.agreeCheckbox?.cornerRadius = 0
        self.installVPNButton?.backgroundColor = .darkGray
        NotificationCenter.default.addObserver(forName: .removeEULA, object: nil, queue: OperationQueue.main) { (notification) -> Void in
            UIView.transition(with: self.agreeCheckbox!,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.agreeCheckbox?.alpha = 0
                }, completion: nil)
            
            UIView.transition(with: self.privacyPolicyText!,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.privacyPolicyText?.alpha = 0
                }, completion: nil)
            
            UIView.transition(with: self.privacyPolicyButton!,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.privacyPolicyButton?.alpha = 0
                }, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        VPNController.shared.lockdownState(completion: { status in
            if status != .invalid {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - ACTION
    @IBAction func openPrivacyPolicy() {
        guard let url = URL(string: "https://lockdownhq.com/privacy") else {
            return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func dismissInstallVPNView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func agreeToPolicy() {
        if agreeCheckbox?.checkState == .checked {
            self.installVPNButton?.isEnabled = true
            self.installVPNButton?.backgroundColor = .tunnelsBlueColor
        }
        else {
            self.installVPNButton?.isEnabled = false
            self.installVPNButton?.backgroundColor = .darkGray
        }
    }
    
    @IBAction func installVPN() {
        if !isConnected {
            DDLogInfo("Installing VPN in Postboarding")
            VPNController.shared.connectToLockdown()
        }
    }
    
    @objc func appIsActive() {
        DDLogInfo("App becomes active")
    }
    
    
    // MARK: - VARIABLES

    @IBOutlet weak var privacyPolicyButton: UIButton?
    @IBOutlet weak var privacyPolicyText: UILabel?
    @IBOutlet weak var agreeCheckbox: M13Checkbox?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var installVPNButton: UIButton?
    var isConnected = false
 
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
