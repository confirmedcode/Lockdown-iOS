//
//  LDFirewallViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 17.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift
import PromiseKit
import NetworkExtension
import PopupDialog
import SwiftyStoreKit

final class LDFirewallViewController: BaseViewController {
    
    // MARK: Properties
    let kHasViewedTutorial = "hasViewedTutorial"
    let kHasSeenInitialFirewallConnectedDialog = "hasSeenInitialFirewallConnectedDialog11"
    let kHasSeenShare = "hasSeenShareDialog4"
    
    let ratingCountKey = "ratingCount" + lastVersionToAskForRating
    let ratingTriggeredKey = "ratingTriggered" + lastVersionToAskForRating
    
    var lastFirewallStatus: NEVPNStatus?
    var activePlans: [Subscription.PlanType] = []
    let vc = FirewallPaywallViewController()
    
    enum Mode {
        case newSubscription
        case upgrade(active: [Subscription.PlanType])
    }
    
    var mode = Mode.newSubscription
    
    var metricsTimer : Timer?
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.anchors.height.equal(800)
        return view
    }()
    
    lazy var yourCurrentPlanLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Your current plan is", comment: "")
        label.font = fontRegular14
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    lazy var upgradeLabel: UILabel = {
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
    
    lazy var protectionPlanLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Basic Protection", comment: "")
        label.font = fontBold22
        label.textColor = .label
        return label
    }()
    
    lazy var firewallTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Get complete protection", comment: "")
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
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(firewallTitle)
        stackView.addArrangedSubview(firewallDescriptionLabel1)
        stackView.addArrangedSubview(firewallDescriptionLabel2)
        stackView.addArrangedSubview(firewallDescriptionLabel3)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var cpTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Don't let those trackers know your every move – Upgrade to Advanced now!", comment: "")
        label.textColor = .black
        label.font = fontBold15
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var cpTrackersGroupView1: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#1"
        view.placeNumber.textColor = .black
        view.titleLabel.textColor = .black
        view.number.textColor = .black
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_game_marketing")!, title: "Game Marketing", number: 4678))
        view.number.isHidden = true
        return view
    }()
    
    private lazy var cpTrackersGroupView2: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#2"
        view.placeNumber.textColor = .black
        view.titleLabel.textColor = .black
        view.number.textColor = .black
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_marketing_trackers")!, title: "Marketing Trackers", number: 3432))
        view.number.isHidden = true
        return view
    }()
    
    private lazy var cpTrackersGroupView3: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#3"
        view.placeNumber.textColor = .black
        view.titleLabel.textColor = .black
        view.number.textColor = .black
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_email_trackers")!, title: "Email Trackers", number: 2756))
        view.number.isHidden = true
        return view
    }()
    
    private lazy var cpStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(cpTitle)
        stackView.addArrangedSubview(cpTrackersGroupView1)
        stackView.addArrangedSubview(cpTrackersGroupView2)
        stackView.addArrangedSubview(cpTrackersGroupView3)
        stackView.layer.cornerRadius = 8
        stackView.layer.borderWidth = 2
        stackView.layer.borderColor = UIColor.gray.cgColor
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.backgroundColor = .extraLightGray
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
    
    private lazy var maTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Most active this week", comment: "")
        label.textColor = .label
        label.font = fontBold15
        label.textAlignment = .center
        return label
    }()
    
    private lazy var maTrackersGroupView1: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#1"
        view.number.textColor = .label
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_facebook_trackers")!, title: "Facebook Trackers", number: 89))
        view.lockImage.isHidden = true
        return view
    }()
    
    private lazy var maTrackersGroupView2: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#2"
        view.number.textColor = .label
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_data_trackers")!, title: "Data Trackers", number: 32))
        view.lockImage.isHidden = true
        return view
    }()
    
    private lazy var maTrackersGroupView3: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#3"
        view.number.textColor = .label
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_clickbait_trackers")!, title: "Clickbait", number: 21))
        view.lockImage.isHidden = true
        return view
    }()
    
    private lazy var maStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(maTitle)
        stackView.addArrangedSubview(maTrackersGroupView1)
        stackView.addArrangedSubview(maTrackersGroupView2)
        stackView.addArrangedSubview(maTrackersGroupView3)
        stackView.layer.cornerRadius = 8
        stackView.layer.borderWidth = 1
        stackView.layer.borderColor = UIColor.lightGray.cgColor
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()
    
    lazy var statisitcsView: OverallStatiscticView = {
        let view = OverallStatiscticView()
        return view
    }()
    
    private lazy var firewallSwitchControl: CustomUISwitch = {
        let uiSwitch = CustomUISwitch(onImage: UIImage(named: "firewall-on-image")!, offImage: UIImage(named: "firewall-off-image")!)
        uiSwitch.setOnClickListener {
            self.toggleFirewall()
        }
        return uiSwitch
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VPNSubscription.cacheLocalizedPrices()
        
        updateFirewallButtonWithStatus(status: FirewallController.shared.status())
        updateMetrics()
        if metricsTimer == nil {
            metricsTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(updateMetrics), userInfo: nil, repeats: true)
            metricsTimer?.fire()
        }
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(firewallSwitchControl)
        firewallSwitchControl.anchors.bottom.safeAreaPin()
        firewallSwitchControl.anchors.leading.marginsPin()
        firewallSwitchControl.anchors.trailing.marginsPin()
        firewallSwitchControl.anchors.height.equal(56)
        
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
        scrollView.anchors.bottom.spacing(8, to: firewallSwitchControl.anchors.top)
        
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
        
        contentView.addSubview(maStackView)
        maStackView.anchors.top.spacing(18, to: upgradeButton.anchors.bottom)
        maStackView.anchors.leading.marginsPin()
        maStackView.anchors.trailing.marginsPin()
        
        contentView.addSubview(statisitcsView)
        statisitcsView.anchors.top.spacing(18, to: maStackView.anchors.bottom)
        statisitcsView.anchors.leading.marginsPin()
        statisitcsView.anchors.trailing.marginsPin()
        
        updateProtectionPlanUI()

//        accountStateDidChange()
        
        NotificationCenter.default.addObserver(self, selector: #selector(tunnelStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMetrics()
    }
}

extension LDFirewallViewController: Loadable {
    
    @objc func accountStateDidChange() {
        updateActiveSubscription()
    }
    
    func updateProtectionPlanUI() {
        if UserDefaults.hasSeenUniversalPaywall {
            updateUI()
            protectionPlanLabel.text = "Universal protection"
        } else if UserDefaults.hasSeenAnonymousPaywall {
            updateUI()
            protectionPlanLabel.text = "Anonymous protection"
        } else if UserDefaults.hasSeenAdvancedPaywall {
            updateUI()
            protectionPlanLabel.text = "Advanced protection"
        } else {
            protectionPlanLabel.text = "Basic protection"
        }
    }
    
    func updateUI() {
        firewallTitle.isHidden = true
        firewallDescriptionLabel1.isHidden = true
        firewallDescriptionLabel2.isHidden = true
        firewallDescriptionLabel3.isHidden = true
        upgradeButton.isHidden = true
        upgradeButton.anchors.height.equal(0)
        cpTrackersGroupView1.lockImage.isHidden = true
        cpTrackersGroupView1.number.isHidden = false
        cpTrackersGroupView2.lockImage.isHidden = true
        cpTrackersGroupView2.number.isHidden = false
        cpTrackersGroupView3.lockImage.isHidden = true
        cpTrackersGroupView3.number.isHidden = false
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
                if active.planType == .universalAnnual || active.planType == .universalMonthly {
                    protectionPlanLabel.text = "Universal protection"
                    updateUI()
                } else if active.planType == .anonymousMonthly || active.planType == .anonymousAnnual {
                    updateUI()
                    protectionPlanLabel.text = "Anonymous protection"
                } else if active.planType == .advancedMonthly || active.planType == .advancedAnnual {
                    updateUI()
                    protectionPlanLabel.text = "Advanced protection"
                } else {
                    firewallTitle.textColor = .red
                }
            } else {
                firewallTitle.textColor = .red
            }
        }.catch { [self] error in
            DDLogError("Error reloading subscription: \(error.localizedDescription)")
            hideLoadingView()
            if let apiError = error as? ApiError {
                switch apiError.code {
                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                    UserDefaults.hasSeenAdvancedPaywall = false
                case kApiCodeSandboxReceiptNotAllowed:
                    UserDefaults.hasSeenAdvancedPaywall = false
                default:
                    DDLogError("Error loading plan: API error code - \(apiError.code)")
                    UserDefaults.hasSeenAdvancedPaywall = false
                }
            } else {
                DDLogError("Error loading plan: Non-API Error - \(error.localizedDescription)")
                UserDefaults.hasSeenAdvancedPaywall = false
            }
        }
    }
    
    @objc func upgrade() {
        let vc = FirewallPaywallViewController()
        present(vc, animated: true)
    }
    
    @objc func tunnelStatusDidChange(_ notification: Notification) {
        // Firewall
        if let tunnelProviderSession = notification.object as? NETunnelProviderSession {
            DDLogInfo("VPNStatusDidChange as NETunnelProviderSession with status: \(tunnelProviderSession.status.description)");
            if (!getUserWantsFirewallEnabled()) {
                updateFirewallButtonWithStatus(status: .disconnected)
            }
            else {
                updateFirewallButtonWithStatus(status: tunnelProviderSession.status)
                if (tunnelProviderSession.status == .connected && defaults.bool(forKey: kHasSeenInitialFirewallConnectedDialog) == false) {
                    defaults.set(true, forKey: kHasSeenInitialFirewallConnectedDialog)
//                    self.tapToActivateFirewallLabel.isHidden = true
//                    if (VPNController.shared.status() == .invalid) {
//                        self.showVPNSubscriptionDialog(title: NSLocalizedString("🔥🧱 Firewall Activated 🎊🎉", comment: ""), message: NSLocalizedString("Trackers, ads, and other malicious scripts are now blocked in all your apps, even outside of Safari.\n\nGet maximum privacy with a Secure Tunnel that protects connections, anonymizes your browsing, and hides your location.", comment: ""))
//                    }
                }
            }
        }
    }
    
    @objc func updateMetrics() {
        DispatchQueue.main.async { [unowned self] in
            self.statisitcsView.enabledBoxView.numberLabel.text = String(getTotalEnabled().count)
            self.statisitcsView.disabledBoxView.numberLabel.text = String(getTotalDisabled().count)
            self.statisitcsView.blockedBoxView.numberLabel.text = String(getAllBlockedDomains().count)
        }
    }
    
    func toggleFirewall() {
        if (defaults.bool(forKey: kHasAgreedToFirewallPrivacyPolicy) == false) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "firewallPrivacyPolicyViewController") as! PrivacyPolicyViewController
            viewController.privacyPolicyKey = kHasAgreedToFirewallPrivacyPolicy
            viewController.parentVC1 = self
            self.present(viewController, animated: true, completion: nil)
            return
        }
        
        if getIsCombinedBlockListEmpty() {
            FirewallController.shared.setEnabled(false, isUserExplicitToggle: true)
            self.showPopupDialog(title: NSLocalizedString("No Block Lists Enabled", comment: ""), message: NSLocalizedString("Please tap Block List and enable at least one block list to activate Firewall.", comment: ""), acceptButton: NSLocalizedString("Okay", comment: ""))
            return
        }
        
        switch FirewallController.shared.status() {
        case .invalid:
            FirewallController.shared.setEnabled(true, isUserExplicitToggle: true)
            //ensureFirewallWorkingAfterEnabling(waitingSeconds: 5.0)
        case .disconnected:
            updateFirewallButtonWithStatus(status: .connecting)
            FirewallController.shared.setEnabled(true, isUserExplicitToggle: true)
            //ensureFirewallWorkingAfterEnabling(waitingSeconds: 5.0)
            
//            checkForAskRating()
        case .connected:
            updateFirewallButtonWithStatus(status: .disconnecting)
            FirewallController.shared.setEnabled(false, isUserExplicitToggle: true)
        case .connecting, .disconnecting, .reasserting:
            break;
        }
    }
    
    func ensureFirewallWorkingAfterEnabling(waitingSeconds: TimeInterval) {
        FirewallController.shared.existingManagerCount { (count) in
            if let count = count, count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + waitingSeconds) {
                    DDLogInfo("\(waitingSeconds) seconds passed, checking if Firewall is enabled")
                    guard getUserWantsFirewallEnabled() else {
                        // firewall shouldn't be enabled, no need to act
                        DDLogInfo("User doesn't want Firewall enabled, no action")
                        return
                    }
                    
                    let status = FirewallController.shared.status()
                    switch status {
                    case .connecting, .disconnecting, .reasserting:
                        // check again in three seconds
                        DDLogInfo("Firewall is in transient state, will check again in 3 seconds")
                        self.ensureFirewallWorkingAfterEnabling(waitingSeconds: 3.0)
                    case .connected:
                        // all good
                        DDLogInfo("Firewall is connected, no action")
                        break
                    case .disconnected, .invalid:
                        // we suppose that the connection is somehow broken, trying to fix
                        DDLogInfo("Firewall is not connected even though it should be, attempting to fix")
                        self.showFixFirewallConnectionDialog {
                            FirewallController.shared.deleteConfigurationAndAddAgain()
                        }
                    }
                }
            } else {
                DDLogInfo("No Firewall configurations in settings (likely fresh install): not checking")
                return
            }
        }
    }
    
    func updateFirewallButtonWithStatus(status: NEVPNStatus) {
        DDLogInfo("UpdateFirewallButton")
        switch status {
        case .connected:
            LatestKnowledge.isFirewallEnabled = true
        case .disconnected:
            LatestKnowledge.isFirewallEnabled = false
        default:
            break
        }
        updateToggleButtonWithStatus(lastStatus: lastFirewallStatus,
                                     newStatus: status,
                                     switchControl: firewallSwitchControl)
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
}
