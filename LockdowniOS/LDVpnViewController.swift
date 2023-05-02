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

final class LDVpnViewController: BaseViewController {
    
    // MARK: - Properties
    
    var lastVPNStatus: NEVPNStatus?
    
    lazy var accessLevelslView: AccessLevelslView = {
        let view = AccessLevelslView()
        return view
    }()
    
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
    
    private lazy var firewallTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Get Anonymous protection", comment: "")
        label.font = fontBold24
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private lazy var firewallDescriptionLabel1: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Block as many trackers as you want", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel2: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Import and export your own block lists", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel3: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Access to new curated lists of trackers", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel4: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("The only fully open source VPN", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel5: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Hide your identity around the world", comment: "")))
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(firewallTitle)
        stackView.addArrangedSubview(firewallDescriptionLabel1)
        stackView.addArrangedSubview(firewallDescriptionLabel2)
        stackView.addArrangedSubview(firewallDescriptionLabel3)
        stackView.addArrangedSubview(firewallDescriptionLabel4)
        stackView.addArrangedSubview(firewallDescriptionLabel5)
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
        
        view.addSubview(accessLevelslView)
        accessLevelslView.anchors.top.safeAreaPin(inset: 0)
        accessLevelslView.anchors.leading.marginsPin()
        accessLevelslView.anchors.trailing.marginsPin()
        
        view.addSubview(vpnSwitchControl)
        vpnSwitchControl.anchors.bottom.safeAreaPin()
        vpnSwitchControl.anchors.leading.marginsPin()
        vpnSwitchControl.anchors.trailing.marginsPin()
        vpnSwitchControl.anchors.height.equal(56)
        
        view.addSubview(scrollView)
        scrollView.anchors.top.spacing(18, to: accessLevelslView.anchors.bottom)
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
                            self.performSegue(withIdentifier: "showSignup", sender: self)
                        })
                    default:
                        _ = self.popupErrorAsApiError(error)
                    }
                }
                else {
                    self.showPopupDialog(title: NSLocalizedString("Error Signing In To Verify Subscription", comment: ""),
                                         message: "\(error)",
                        acceptButton: "Okay")
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(tunnelStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
    }
}

// MARK: - Private functions

extension LDVpnViewController {
    
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
                            self.performSegue(withIdentifier: "showSignup", sender: self)
                        case kApiCodeNoActiveSubscription:
                            self.showPopupDialog(title: NSLocalizedString("Subscription Expired", comment: ""), message: NSLocalizedString("Please renew your subscription to activate the Secure Tunnel.", comment: ""), acceptButton: NSLocalizedString("Okay", comment: ""), completionHandler: {
                                self.performSegue(withIdentifier: "showSignup", sender: self)
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
                            self.performSegue(withIdentifier: "showSignup", sender: self)
                        case kApiCodeNoActiveSubscription:
                            self.showPopupDialog(title: NSLocalizedString("Subscription Expired", comment: ""), message: NSLocalizedString("Please renew your subscription to activate the Secure Tunnel.", comment: ""), acceptButton: NSLocalizedString("Okay", comment: ""), completionHandler: {
                                self.performSegue(withIdentifier: "showSignup", sender: self)
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
                                _ = self.popupErrorAsApiError(error)
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

