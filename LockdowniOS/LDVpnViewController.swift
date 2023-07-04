//
//  LDVpnViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 19.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift
import PromiseKit
import NetworkExtension
import PopupDialog
import SwiftyStoreKit

final class LDVpnViewController: BaseViewController {
    
    // MARK: - Properties
    var activePlans: [Subscription.PlanType] = []
    
    var lastVPNStatus: NEVPNStatus?
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.anchors.height.equal(640)
        return view
    }()
    
    private lazy var yourCurrentPlanLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Your current plan is", comment: "")
        label.font = fontRegular14
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private lazy var upgradeLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Upgrade?", comment: "")
        label.font = fontBold13
        label.textColor = .tunnelsBlue
        label.isUserInteractionEnabled = true
        label.setOnClickListener {
            let vc = VPNPaywallViewController()
            self.present(vc, animated: true)
        }
        return label
    }()
    
    private lazy var protectionPlanLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Basic Protection", comment: "")
        label.font = fontBold22
        label.textColor = .label
        return label
    }()
    
    private lazy var mainTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Get Anonymous protection", comment: "")
        label.font = fontBold24
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private lazy var descriptionLabel1: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Block as many trackers as you want", comment: "")))
        return label
    }()
    
    private lazy var descriptionLabel2: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Import and export your own block lists", comment: "")))
        return label
    }()
    
    private lazy var descriptionLabel3: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Access to new curated lists of trackers", comment: "")))
        return label
    }()
    
    private lazy var descriptionLabel4: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("The only fully open source VPN", comment: "")))
        return label
    }()
    
    private lazy var descriptionLabel5: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Hide your identity around the world", comment: "")))
        return label
    }()
    
    private lazy var descriptionLabel6: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Protect all Apple devices", comment: "")))
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(mainTitle)
        stackView.addArrangedSubview(descriptionLabel1)
        stackView.addArrangedSubview(descriptionLabel2)
        stackView.addArrangedSubview(descriptionLabel3)
        stackView.addArrangedSubview(descriptionLabel4)
        stackView.addArrangedSubview(descriptionLabel5)
        stackView.addArrangedSubview(descriptionLabel6)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var upgradeButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setTitle(NSLocalizedString("Upgrade", comment: ""), for: .normal)
        button.titleLabel?.font = fontBold18
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        button.anchors.height.equal(56)
        button.addTarget(self, action: #selector(upgrade), for: .touchUpInside)
        return button
    }()
    
    private lazy var whitelistCard: LDCardView = {
        let view = LDCardView()
        view.title.text = "Whitelist"
        view.iconImageView.image = UIImage(named: "icn_whitelist")
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [weak self] in
            guard let self else { return }
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "WhitelistViewController") as! WhitelistViewController
            self.present(vc, animated: true, completion: nil)
        }
        return view
    }()
    
    private lazy var regionCard: LDCardView = {
        let view = LDCardView()
        view.title.text = "Region"
        view.iconImageView.image = UIImage(named: "icn_globe")
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [weak self] in
            guard let self else { return }
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "SetRegionViewController") as! SetRegionViewController
            self.present(vc, animated: true, completion: nil)
        }
        return view
    }()
    
    private lazy var hStack: UIStackView = {
        let stack = UIStackView()
        stack.addArrangedSubview(whitelistCard)
        stack.addArrangedSubview(regionCard)
        stack.alignment = .center
        stack.distribution = .equalCentering
        stack.spacing = 16
        return stack
    }()
    
    private lazy var vpnSwitchControl: CustomUISwitch = {
        let uiSwitch = CustomUISwitch(onImage: UIImage(named: "vpn-on-image")!, offImage: UIImage(named: "vpn-off-image")!)
        uiSwitch.setOnClickListener {
            self.toggleVPN()
        }
        return uiSwitch
    }()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(vpnSwitchControl)
        vpnSwitchControl.anchors.bottom.safeAreaPin()
        vpnSwitchControl.anchors.leading.marginsPin()
        vpnSwitchControl.anchors.trailing.marginsPin()
        vpnSwitchControl.anchors.height.equal(56)
        
        view.addSubview(yourCurrentPlanLabel)
        yourCurrentPlanLabel.anchors.leading.marginsPin()
        yourCurrentPlanLabel.anchors.top.safeAreaPin()
        
        view.addSubview(upgradeLabel)
        upgradeLabel.anchors.trailing.marginsPin()
        upgradeLabel.anchors.centerY.equal(yourCurrentPlanLabel.anchors.centerY)
        
        view.addSubview(protectionPlanLabel)
        protectionPlanLabel.anchors.top.spacing(8, to: yourCurrentPlanLabel.anchors.bottom)
        protectionPlanLabel.anchors.leading.marginsPin()
        
        view.addSubview(scrollView)
        scrollView.anchors.top.spacing(12, to: protectionPlanLabel.anchors.bottom)
        scrollView.anchors.leading.pin()
        scrollView.anchors.trailing.pin()
        scrollView.anchors.bottom.spacing(8, to: vpnSwitchControl.anchors.top)
        
        scrollView.addSubview(contentView)
        contentView.anchors.top.pin()
        contentView.anchors.centerX.align()
        contentView.anchors.width.equal(scrollView.anchors.width)
        contentView.anchors.bottom.pin()

        contentView.addSubview(stackView)
        stackView.anchors.top.marginsPin()
        stackView.anchors.leading.marginsPin()
        stackView.anchors.trailing.marginsPin()
        
        contentView.addSubview(upgradeButton)
        upgradeButton.anchors.top.spacing(18, to: stackView.anchors.bottom)
        upgradeButton.anchors.leading.marginsPin()
        upgradeButton.anchors.trailing.marginsPin()
        
        contentView.addSubview(hStack)
        hStack.anchors.top.spacing(18, to: upgradeButton.anchors.bottom)
        hStack.anchors.centerX.align()
        
        whitelistCard.anchors.width.equal(view.bounds.width / 2 - 20)
        whitelistCard.anchors.height.equal(view.bounds.width / 2 - 20)
        
        regionCard.anchors.width.equal(view.bounds.width / 2 - 20)
        regionCard.anchors.height.equal(view.bounds.width / 2 - 20)
        
        updateVPNButtonWithStatus(status: VPNController.shared.status())
        updateVPNRegionLabel()
        
        if (VPNController.shared.status() == .connected) {
            firstly {
                try Client.signIn()
            }
            .done { (signin: SignIn) in
                // successfully signed in with no subscription errors, do nothing
            }
            .catch { error in
                if (self.popupErrorAsNSURLError(error)) {
                    return
                }
                else if let apiError = error as? ApiError {
                    switch apiError.code {
                    case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                        self.showPopupDialog(title: NSLocalizedString("VPN Subscription Expired", comment: ""), message: NSLocalizedString("Please renew your subscription to re-activate the VPN.", comment: ""), acceptButton: NSLocalizedString("Okay", comment: ""), completionHandler: {
                            self.present(VPNPaywallViewController(), animated: true)
//                            self.performSegue(withIdentifier: "showSignup", sender: self)
                        })
                    default:
//                        _ = self.popupErrorAsApiError(error)
                        break
                    }
                }
                else {
                    self.showPopupDialog(title: NSLocalizedString("Error Signing In To Verify Subscription", comment: ""),
                                         message: "\(error)",
                        acceptButton: "Okay")
                }
            }
        }
        
        if UserDefaults.hasSeenAnonymousPaywall {
            mainTitle.text = "Get Universal protection"
            descriptionLabel1.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel2.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel3.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel4.lockImage.image = UIImage(named: "icn_checkmark")
            protectionPlanLabel.text = "Anonymous protection"
        } else if UserDefaults.hasSeenUniversalPaywall {
            mainTitle.text = "You're fully protected"
            descriptionLabel1.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel2.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel3.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel4.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel5.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel6.lockImage.image = UIImage(named: "icn_checkmark")
            upgradeButton.isHidden = true
            upgradeButton.anchors.height.equal(0)
            protectionPlanLabel.text = "Universal protection"
        } else if UserDefaults.hasSeenAdvancedPaywall {
            descriptionLabel1.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel2.lockImage.image = UIImage(named: "icn_checkmark")
            descriptionLabel3.lockImage.image = UIImage(named: "icn_checkmark")
            protectionPlanLabel.text = "Advanced protection"
        } else {
            protectionPlanLabel.text = "Basic protection"
        }
        
//        accountStateDidChange()
        
        NotificationCenter.default.addObserver(self, selector: #selector(tunnelStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
    }
}

// MARK: - Private functions

extension LDVpnViewController: Loadable {
    
    @objc func accountStateDidChange() {
        updateActiveSubscription()
    }
    
    func updateActiveSubscription() {
        showLoadingView()
        // not logged in via email, use receipt
        firstly {
            try Client.signIn()
        }.then { _ in
            try Client.activeSubscriptions()
        }.ensure {
            self.hideLoadingView()
        }.done { [self] subscriptions in
            self.activePlans = subscriptions.map({ $0.planType })
            if let active = subscriptions.first {
                if  active.planType == .advancedMonthly || active.planType == .advancedAnnual {
                    descriptionLabel1.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel2.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel3.lockImage.image = UIImage(named: "icn_checkmark")
                    UserDefaults.hasSeenAdvancedPaywall = true
                } else if active.planType == .anonymousMonthly || active.planType == .anonymousAnnual {
                    mainTitle.text = "Get Universal protection"
                    descriptionLabel1.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel2.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel3.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel4.lockImage.image = UIImage(named: "icn_checkmark")
                    UserDefaults.hasSeenAdvancedPaywall = true
                    UserDefaults.hasSeenAnonymousPaywall = true
                } else if active.planType == .universalAnnual || active.planType == .universalMonthly {
                    mainTitle.text = "You're fully protected"
                    descriptionLabel1.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel2.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel3.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel4.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel5.lockImage.image = UIImage(named: "icn_checkmark")
                    descriptionLabel6.lockImage.image = UIImage(named: "icn_checkmark")
                    upgradeButton.isHidden = true
                    upgradeButton.anchors.height.equal(0)
                    UserDefaults.hasSeenAdvancedPaywall = true
                    UserDefaults.hasSeenAnonymousPaywall = true
                    UserDefaults.hasSeenUniversalPaywall = true
                }
            }
        }.catch { [self] error in
            DDLogError("Error reloading subscription: \(error.localizedDescription)")
            hideLoadingView()
            if let apiError = error as? ApiError {
                switch apiError.code {
                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                    UserDefaults.hasSeenAdvancedPaywall = false
                    UserDefaults.hasSeenAnonymousPaywall = false
                    UserDefaults.hasSeenUniversalPaywall = false
                case kApiCodeSandboxReceiptNotAllowed:
                    UserDefaults.hasSeenAdvancedPaywall = false
                    UserDefaults.hasSeenAnonymousPaywall = false
                    UserDefaults.hasSeenUniversalPaywall = false
                default:
                    DDLogError("Error loading plan: API error code - \(apiError.code)")
                    UserDefaults.hasSeenAdvancedPaywall = false
                    UserDefaults.hasSeenAnonymousPaywall = false
                    UserDefaults.hasSeenUniversalPaywall = false
                }
            } else {
                DDLogError("Error loading plan: Non-API Error - \(error.localizedDescription)")
                UserDefaults.hasSeenAdvancedPaywall = false
                UserDefaults.hasSeenAnonymousPaywall = false
                UserDefaults.hasSeenUniversalPaywall = false
            }
        }
    }
    
    @objc func upgrade() {
        let vc = VPNPaywallViewController()
        present(vc, animated: true)
    }
    
    func toggleVPN() {
        
        DDLogInfo("Toggle VPN")
        switch VPNController.shared.status() {
        case .connected, .connecting, .reasserting:
            DDLogInfo("Toggle VPN: on currently, turning it off")
            updateVPNButtonWithStatus(status: .disconnecting)
            VPNController.shared.setEnabled(false)
        case .disconnected, .disconnecting, .invalid:
            DDLogInfo("Toggle VPN: off currently, turning it on")
            updateVPNButtonWithStatus(status: .connecting)
            // if there's a confirmed email, use that and sync the receipt with it
            if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
                DDLogInfo("have confirmed API credentials, using them")
                firstly {
                    try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                }
                .then { (signin: SignIn) -> Promise<SubscriptionEvent> in
                    DDLogInfo("signin result: \(signin)")
                    return try Client.subscriptionEvent()
                }
                .then { (result: SubscriptionEvent) -> Promise<GetKey> in
                    DDLogInfo("subscriptionevent result: \(result)")
                    return try Client.getKey()
                }
                .done { (getKey: GetKey) in
                    try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                    DDLogInfo("setting VPN creds with ID: \(getKey.id)")
                    VPNController.shared.setEnabled(true)
                }
                .catch { error in
                    DDLogError("Error doing email-login -> subscription-event: \(error)")
                    self.updateVPNButtonWithStatus(status: .disconnected)
                    if (self.popupErrorAsNSURLError(error)) {
                        return
                    }
                    else if let apiError = error as? ApiError {
                        switch apiError.code {
                        case kApiCodeInvalidAuth, kApiCodeIncorrectLogin:
                            let confirm = PopupDialog(title: "Incorrect Login",
                                                       message: "Your saved login credentials are incorrect. Please sign out and try again.",
                                                       image: nil,
                                                       buttonAlignment: .horizontal,
                                                       transitionStyle: .bounceDown,
                                                       preferredWidth: 270,
                                                       tapGestureDismissal: true,
                                                       panGestureDismissal: false,
                                                       hideStatusBar: false,
                                                       completion: nil)
                            confirm.addButtons([
                               DefaultButton(title: NSLocalizedString("Cancel", comment: ""), dismissOnTap: true) {
                               },
                               DefaultButton(title: NSLocalizedString("Sign Out", comment: ""), dismissOnTap: true) {
                                URLCache.shared.removeAllCachedResponses()
                                Client.clearCookies()
                                clearAPICredentials()
                                setAPICredentialsConfirmed(confirmed: false)
                                self.showPopupDialog(title: "Success", message: "Signed out successfully.", acceptButton: NSLocalizedString("Okay", comment: ""))
                               },
                            ])
                            self.present(confirm, animated: true, completion: nil)
                        case kApiCodeNoSubscriptionInReceipt:
                            self.present(VPNPaywallViewController(), animated: true)
//                            self.performSegue(withIdentifier: "showSignup", sender: self)
                        case kApiCodeNoActiveSubscription:
                            self.showPopupDialog(title: NSLocalizedString("Subscription Expired", comment: ""), message: NSLocalizedString("Please renew your subscription to activate the Secure Tunnel.", comment: ""), acceptButton: NSLocalizedString("Okay", comment: ""), completionHandler: {
                                self.present(VPNPaywallViewController(), animated: true)
//                                self.performSegue(withIdentifier: "showSignup", sender: self)
                            })
                        default:
                            _ = self.popupErrorAsApiError(error)
                        }
                    }
                }
            }
            else {
                firstly {
                    try Client.signIn() // this will fetch and set latest receipt, then submit to API to get cookie
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
                    self.updateVPNButtonWithStatus(status: .disconnected)
                    if (self.popupErrorAsNSURLError(error)) {
                        return
                    }
                    else if let apiError = error as? ApiError {
                        switch apiError.code {
                        case kApiCodeNoSubscriptionInReceipt:
                            self.present(VPNPaywallViewController(), animated: true)
//                            self.performSegue(withIdentifier: "showSignup", sender: self)
                        case kApiCodeNoActiveSubscription:
                            self.showPopupDialog(title: NSLocalizedString("Subscription Expired", comment: ""), message: NSLocalizedString("Please renew your subscription to activate the Secure Tunnel.", comment: ""), acceptButton: NSLocalizedString("Okay", comment: ""), completionHandler: {
                                self.present(VPNPaywallViewController(), animated: true)
//                                self.performSegue(withIdentifier: "showSignup", sender: self)
                            })
                        default:
                            if (apiError.code == kApiCodeNegativeError) {
                                if (getVPNCredentials() != nil) {
                                    DDLogError("Unknown error -1 from API, but VPNCredentials exists, so activating anyway.")
                                    self.updateVPNButtonWithStatus(status: .connecting)
                                    VPNController.shared.setEnabled(true)
                                }
                                else {
                                    self.showPopupDialog(title: NSLocalizedString("Apple Outage", comment: ""), message: "There is currently an outage at Apple which is preventing Secure Tunnel from activating. This will likely by resolved by Apple soon, and we apologize for this issue in the meantime." + NSLocalizedString("\n\n If this error persists, please contact team@lockdownprivacy.com.", comment: ""), acceptButton: NSLocalizedString("Okay", comment: ""))
                                }
                            }
                            else {
//                                _ = self.popupErrorAsApiError(error)
                                self.updateVPNButtonWithStatus(status: .connecting)
                                VPNController.shared.setEnabled(true)
                            }
                        }
                    }
                    else {
                        self.showPopupDialog(title: NSLocalizedString("Error Signing In To Verify Subscription", comment: ""),
                                             message: "\(error)",
                            acceptButton: NSLocalizedString("Okay", comment: ""))
                    }
                }
            }
        }
    }
    
    func updateVPNButtonWithStatus(status: NEVPNStatus) {
        DDLogInfo("UpdateVPNButton")
        switch status {
        case .connected:
            LatestKnowledge.isVPNEnabled = true
        case .disconnected:
            LatestKnowledge.isVPNEnabled = false
        default:
            break
        }
        updateToggleButtonWithStatus(lastStatus: lastVPNStatus,
                                     newStatus: status,
                                     switchControl: vpnSwitchControl)
    }
    
    func updateToggleButtonWithStatus(lastStatus: NEVPNStatus?,
                                      newStatus: NEVPNStatus,
                                      switchControl: CustomUISwitch) {
        DDLogInfo("UpdateToggleButton")
        if (newStatus == lastStatus) {
            DDLogInfo("No status change from last time, ignoring.");
        }
        else {
            DispatchQueue.main.async() {
                switch newStatus {
                case .connected:
                    switchControl.status = true
                case .connecting:
                    switchControl.status = true
                case .disconnected, .invalid:
                    switchControl.status = false
                case .disconnecting:
                    switchControl.status = false
                case .reasserting:
                    break;
                }
            }
        }
    }
    
    func updateVPNRegionLabel() {
        regionCard.subTitle.text = getSavedVPNRegion().regionDisplayNameShort
    }
    
    @objc func tunnelStatusDidChange(_ notification: Notification) {
        if let neVPNConnection = notification.object as? NEVPNConnection {
            DDLogInfo("VPNStatusDidChange as NEVPNConnection with status: \(neVPNConnection.status.description)");
            updateVPNButtonWithStatus(status: neVPNConnection.status);
            updateVPNRegionLabel()
            if NEVPNManager.shared().connection.status == .connected || NEVPNManager.shared().connection.status == .disconnected {
                //self.updateIP();
            }
        }
        else {
            DDLogInfo("VPNStatusDidChange neither TunnelProviderSession nor NEVPNConnection");
        }
    }
}
