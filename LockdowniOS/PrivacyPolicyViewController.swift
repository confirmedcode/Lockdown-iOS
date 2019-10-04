//
//  PrivacyPolicyViewController.swift
//  Lockdown
//
//  Created by Johnny Lin on 8/9/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import UIKit
import PopupDialog

let kHasAgreedToFirewallPrivacyPolicy = "kHasAgreedToFirewallPrivacyPolicy"
let kHasAgreedToVPNPrivacyPolicy = "kHasAgreedToVPNPrivacyPolicy"

class PrivacyPolicyViewController: BaseViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var privacyPolicyWrap: UIView!
    @IBOutlet weak var privacyPolicyCheckbox: M13Checkbox!
    @IBOutlet weak var checkbox: M13Checkbox!
    @IBOutlet weak var whyTrustButton: UIButton!
    
    var parentVC: HomeViewController? = nil
    var privacyPolicyKey = kHasAgreedToFirewallPrivacyPolicy
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getStartedButton.backgroundColor = .gray
    }
    
    @IBAction func getStartedTapped(_ sender: Any) {
        if (checkbox.checkState == .unchecked) {
            showPopupDialog(title: NSLocalizedString("Privacy Policy", comment: ""), message: NSLocalizedString("Please tap the checkbox circle to agree to the Privacy Policy in order to continue.", comment: ""), acceptButton: NSLocalizedString("Okay", comment: ""))
        }
        else {
            defaults.set(true, forKey: privacyPolicyKey)
            if (privacyPolicyKey == kHasAgreedToFirewallPrivacyPolicy) {
                self.dismiss(animated: true, completion: {
                    self.parentVC?.toggleFirewall(self)
                })
            }
            else {
                self.dismiss(animated: true, completion: {
                    self.parentVC?.toggleVPN(self)
                })
            }
        }
    }
    
    @IBAction func checkboxTapped(_ sender: Any) {
        if checkbox.checkState == .checked {
            self.getStartedButton.backgroundColor = .tunnelsBlue
        }
        else {
            self.getStartedButton.backgroundColor = .gray
        }
    }
    
    @IBAction func privacyPolicyTapped(_ sender: Any) {
        showPrivacyPolicyModal()
    }
    
    @IBAction func whyTrustTapped(_ sender: Any) {
        showWhyTrustPopup()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
