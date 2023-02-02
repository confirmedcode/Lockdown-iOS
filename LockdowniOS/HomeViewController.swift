//
//  HomeViewController.swift
//  Lockdown
//
//  Created by Johnny Lin on 7/31/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import NetworkExtension
import CocoaLumberjackSwift
import UIKit
import PromiseKit
import StoreKit
import SwiftyStoreKit
import PopupDialog
import AwesomeSpotlightView

class CircularView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        corners = .continuous(bounds.midX)
    }
    
    @IBInspectable var shadowUIColor: UIColor? {
        didSet {
            redrawShadowColor()
        }
    }
    
    func redrawShadowColor() {
        self.layer.shadowColor = shadowUIColor?.cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        redrawShadowColor()
    }
}

let kHasSeenEmailSignup = "hasSeenEmailSignup"

// swiftlint:disable type_body_length
class HomeViewController: BaseViewController, Loadable {
    
    let kHasViewedTutorial = "hasViewedTutorial"
    let kHasSeenInitialFirewallConnectedDialog = "hasSeenInitialFirewallConnectedDialog11"
    let kHasSeenShare = "hasSeenShareDialog4"
    
    let ratingCountKey = "ratingCount" + lastVersionToAskForRating
    let ratingTriggeredKey = "ratingTriggered" + lastVersionToAskForRating
    
    @IBOutlet var mainStack: UIStackView!
    
    @IBOutlet weak var firewallTitleLabel: UILabel!
    @IBOutlet weak var firewallActive: UILabel!
    @IBOutlet weak var firewallToggleCircle: UIButton!
    @IBOutlet weak var firewallToggleAnimatedCircle: NVActivityIndicatorView!
    @IBOutlet weak var firewallButton: UIButton!
    @IBOutlet weak var tapToActivateFirewallLabel: UILabel!
    var lastFirewallStatus: NEVPNStatus?
    @IBOutlet weak var metricsStack: UIStackView!
    @IBOutlet weak var dailyMetrics: UILabel?
    @IBOutlet weak var weeklyMetrics: UILabel?
    @IBOutlet weak var allTimeMetrics: UILabel?
    var metricsTimer: Timer?
    @IBOutlet weak var firewallSettingsButton: UIButton!
    @IBOutlet weak var firewallViewLogButton: UIButton!
    @IBOutlet weak var firewallShareButton: UIButton!
    
    @IBOutlet weak var vpnHeaderView: UIView!
    @IBOutlet weak var vpnActive: UILabel!
    @IBOutlet weak var vpnToggleCircle: UIButton!
    @IBOutlet weak var vpnToggleAnimatedCircle: NVActivityIndicatorView!
    @IBOutlet weak var vpnButton: UIButton!
    var lastVPNStatus: NEVPNStatus?
    @IBOutlet weak var vpnSetRegionButton: UIButton!
    @IBOutlet weak var vpnRegionLabel: UILabel!
    @IBOutlet weak var vpnWhitelistButton: UIButton!
    
    private let paywallService = BasePaywallService.shared
    private var countdownDisplayService: CountdownDisplayService { paywallService.countdownDisplayService }
    
    private var ltoButton: UIButton?
    
    var activePlans: [Subscription.PlanType] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateFirewallButtonWithStatus(status: FirewallController.shared.status())
        updateMetrics()
        if metricsTimer == nil {
            metricsTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(updateMetrics), userInfo: nil, repeats: true)
            metricsTimer?.fire()
        }
        firewallViewLogButton.corners = .continuous(8)
        firewallViewLogButton.layer.maskedCorners = [.layerMinXMaxYCorner]
        firewallSettingsButton.corners = .continuous(8)
        firewallSettingsButton.layer.maskedCorners = [.layerMaxXMaxYCorner]

        updateVPNButtonWithStatus(status: VPNController.shared.status())
        //updateIP()
        vpnWhitelistButton.corners = .continuous(8)
        vpnWhitelistButton.layer.maskedCorners = [.layerMinXMaxYCorner]
        vpnSetRegionButton.corners = .continuous(8)
        vpnSetRegionButton.layer.maskedCorners = [.layerMaxXMaxYCorner]
        updateVPNRegionLabel()
        
        updateStackViewAxis(basedOn: view.frame.size)
        
        // Check Subscription - if VPN active but not subscribed, then disconnect and show dialog (don't do this if connection error)
        if VPNController.shared.status() == .connected {
            firstly {
                try Client.signIn()
            }
            .done { _ in
                // successfully signed in with no subscription errors, do nothing
            }
            .catch { error in
                if self.popupErrorAsNSURLError(error) {
                    return
                } else if let apiError = error as? ApiError {
                    switch apiError.code {
                    case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                        self.showPopupDialog(
                            title: .localized("VPN Subscription Expired"),
                            message: .localized("Please renew your subscription to re-activate the VPN."),
                            acceptButton: .localizedOkay) {
                            self.showPaywallIfNoSubscription()
                        }
                    default:
                        _ = self.popupErrorAsApiError(error)
                    }
                } else {
                    self.showPopupDialog(title: .localized("Error Signing In To Verify Subscription"),
                                         message: "\(error)",
                                         acceptButton: .localizedOkay)
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(tunnelStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let inset = firewallButton.frame.width * 0.175
        firewallButton.contentEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        vpnButton.contentEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Used for debugging signup
        //performSegue(withIdentifier: "showSignup", sender: nil)
        
        if defaults.bool(forKey: kHasViewedTutorial) == false {
            startTutorial()
        } else if OneTimeActions.hasSeen(.newFancyOnboarding),
                  !OneTimeActions.hasSeen(.newEnableNotificationsController) {
            showEnableNotifications()
        } else if UserDefaults.hasSeenPaywallOnHomeScreen == false {
            showPaywallIfNoSubscription()
        } else if Calendar.hasExceededLapse(between: Date(), and: UserDefaults.lastPaywallDisplayDate) {
            showPaywallIfNoSubscription()
        }
        
        if defaults.bool(forKey: kHasSeenInitialFirewallConnectedDialog) == false {
            tapToActivateFirewallLabel.isHidden = false
        }
        
        // If total blocked > 1000, and have not shown share dialog before, ask if user wants to share
        if getTotalMetrics() > 1000 && defaults.bool(forKey: kHasSeenShare) == false {
            defaults.set(true, forKey: kHasSeenShare)
            let popup = PopupDialog(
                title: "You've blocked over 1000 trackers! 🎊",
                message: .localized("Share your anonymized metrics and show other people how to block invasive tracking."),
                image: nil,
                buttonAlignment: .horizontal,
                transitionStyle: .bounceDown,
                preferredWidth: 270,
                tapGestureDismissal: true,
                panGestureDismissal: false,
                hideStatusBar: false,
                completion: nil)
             popup.addButtons([
                CancelButton(title: .localized("Not Now"), dismissOnTap: true) {
                    let s0 = AwesomeSpotlight(
                        withRect: self.getRectForView(self.firewallShareButton).insetBy(dx: -13.0, dy: -13.0),
                        shape: .roundRectangle,
                        text: .localized("You can tap this later if you feel like sharing.\n(Tap anywhere to dismiss)"))
                    let spotlightView = AwesomeSpotlightView(frame: self.view.frame, spotlight: [s0])
                    spotlightView.cutoutRadius = 8
                    spotlightView.spotlightMaskColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
                    spotlightView.enableArrowDown = true
                    spotlightView.textLabelFont = .mediumLockdownFont(size: 16)
                    spotlightView.labelSpacing = 24
                    spotlightView.delegate = self
                    self.view.addSubview(spotlightView)
                    spotlightView.start()
                },
                DefaultButton(title: .localized("Next"), dismissOnTap: true) {
                    self.shareFirewallMetricsTapped("")
                }
             ])
             self.present(popup, animated: true, completion: nil)
        }
        
        if paywallService.context == .followUpLimitedTimeOffer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showLTOButtonIfEligible()
            }
        }
        
        addLTOButtonIfEligible()
    }
    
    func updateStackViewAxis(basedOn size: CGSize) {
        guard traitCollection.userInterfaceIdiom == .pad else {
            // axis always vertical on iPhone
            return
        }
        
        if size.width > size.height {
            mainStack.axis = .horizontal
        } else {
            mainStack.axis = .vertical
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard traitCollection.userInterfaceIdiom == .pad else {
            return
        }
        
        coordinator.animate { [unowned self] _ in
            self.updateLtoButtonFrame()
            self.updateStackViewAxis(basedOn: size)
        } completion: { (_) in
            return
        }
    }
    
    func showVPNSubscriptionDialog(title: String, message: String) {
        let popup = PopupDialog(
            title: title,
            message: message,
            image: nil,
            buttonAlignment: .horizontal,
            transitionStyle: .bounceUp,
            preferredWidth: 300.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true,
            completion: nil)
        
        let getEnhancedPrivacyButton = DefaultButton(title: .localized("1 Week Free"), dismissOnTap: true) {
            self.showPaywallIfNoSubscription()
        }
        let laterButton = CancelButton(title: .localized("Skip Trial"), dismissOnTap: true) { }
        
        popup.addButtons([laterButton, getEnhancedPrivacyButton])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    // This notification is triggered for both Firewall and VPN
    @objc func tunnelStatusDidChange(_ notification: Notification) {
        // Firewall
        if let tunnelProviderSession = notification.object as? NETunnelProviderSession {
            DDLogInfo("VPNStatusDidChange as NETunnelProviderSession with status: \(tunnelProviderSession.status.description)")
            if !getUserWantsFirewallEnabled() {
                updateFirewallButtonWithStatus(status: .disconnected)
            } else {
                updateFirewallButtonWithStatus(status: tunnelProviderSession.status)
                if tunnelProviderSession.status == .connected && defaults.bool(forKey: kHasSeenInitialFirewallConnectedDialog) == false {
                    defaults.set(true, forKey: kHasSeenInitialFirewallConnectedDialog)
                    self.tapToActivateFirewallLabel.isHidden = true
                    if VPNController.shared.status() == .invalid {
                        guard BaseUserService.shared.user.currentSubscription == nil else { return }
                        let message = "trackers_ads_and_malicious_scripts_are_now_blocked_get_max_privacy"
                        self.showVPNSubscriptionDialog(title: .localized("🔥🧱 Firewall Activated 🎊🎉"), message: .localized(message))
                    }
                }
            }
        }
        // VPN
        else if let neVPNConnection = notification.object as? NEVPNConnection {
            DDLogInfo("VPNStatusDidChange as NEVPNConnection with status: \(neVPNConnection.status.description)")
            updateVPNButtonWithStatus(status: neVPNConnection.status)
            updateVPNRegionLabel()
            if NEVPNManager.shared().connection.status == .connected || NEVPNManager.shared().connection.status == .disconnected {
                //self.updateIP();
            }
        } else {
            DDLogInfo("VPNStatusDidChange neither TunnelProviderSession nor NEVPNConnection")
        }
    }
    
    // MARK: - Top Buttons
    
    func startTutorial() {
        var spotlights: [AwesomeSpotlight] = []
        let centerPoint = UIScreen.main.bounds.center
        
        let spotlight0Message: String = .localized("Welcome to the Lockdown Tutorial.\n\nTap anywhere to continue.")
        let s0 = AwesomeSpotlight(withRect: CGRect(x: centerPoint.x, y: centerPoint.y - 100, width: 0, height: 0), shape: .circle, text: spotlight0Message)
        
        let spotlight1Message: String = .localized("Lockdown Firewall blocks bad and untrusted connections in all your apps - not just Safari.")
        let firewallTitleLabelRect = getRectForView(firewallTitleLabel).insetBy(dx: -13.0, dy: -30.0)
        let s1 = AwesomeSpotlight(withRect: firewallTitleLabelRect, shape: .roundRectangle, text: spotlight1Message)
        
        let spotlight2Message: String = .localized("Activate Firewall with this button.")
        let s2 = AwesomeSpotlight(withRect: getRectForView(firewallToggleCircle).insetBy(dx: -10.0, dy: -10.0), shape: .circle, text: spotlight2Message)
        
        let spotlight3Message: String = .localized("See live metrics for how many bad connections Firewall has blocked.")
        let s3 = AwesomeSpotlight(withRect: getRectForView(metricsStack).insetBy(dx: -10.0, dy: 0.0), shape: .roundRectangle, text: spotlight3Message)
        
        let spotlight4Message = """
\"View Log\" shows exactly what connections were blocked in the past day. This log is cleared at midnight and stays on-device, \
so it's only visible to you.
"""
        let firewallLogButtonRect = getRectForView(firewallViewLogButton).insetBy(dx: -10.0, dy: -10.0)
        let s4 = AwesomeSpotlight(withRect: firewallLogButtonRect, shape: .roundRectangle, text: .localized(spotlight4Message))
        
        let spotlight5Message = """
\"Block List\" lets you choose what you want to block (e.g, Facebook, clickbait, etc). \
You can also set custom domains to block.
"""
        let firewallSettingButtonRect = getRectForView(firewallSettingsButton).insetBy(dx: -10.0, dy: -10.0)
        let s5 = AwesomeSpotlight(withRect: firewallSettingButtonRect, shape: .roundRectangle, text: .localized(spotlight5Message))
        
        let spotlight6Message = """
For maximum privacy, activate Secure Tunnel, which uses bank-level encryption to protect connections, anonymize your browsing, \
and hide your location and IP.
"""
        let headerViewRect = getRectForView(vpnHeaderView).insetBy(dx: -10.0, dy: -10.0)
        let s6 = AwesomeSpotlight(withRect: headerViewRect, shape: .roundRectangle, text: .localized(spotlight6Message))
        
        spotlights.append(contentsOf: [s0, s1, s2, s3, s4, s5, s6])
        
        if let tabBarButton = (tabBarController as? MainTabBarController)?.accountTabBarButton {
            let spotlight7Message: String = .localized("To see this tutorial again, open the Account tab.")
            let tabBarButtonRect = getRectForView(tabBarButton).insetBy(dx: -10.0, dy: -10.0)
            let s7 = AwesomeSpotlight(withRect: tabBarButtonRect, shape: .roundRectangle, text: spotlight7Message)
            spotlights.append(s7)
        }
        
        let spotlightView = AwesomeSpotlightView(frame: view.frame,
                                                 spotlight: spotlights)
        spotlightView.accessibilityIdentifier = "tutorial"
        spotlightView.cutoutRadius = 8
        spotlightView.spotlightMaskColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        spotlightView.enableArrowDown = true
        spotlightView.textLabelFont = .mediumLockdownFont(size: 16)
        spotlightView.labelSpacing = 24
        spotlightView.delegate = self
        tabBarController?.view.addSubview(spotlightView)
        spotlightView.start()
    }
    
    func spotlightViewDidCleanup(_ spotlightView: AwesomeSpotlightView) {
        guard spotlightView.accessibilityIdentifier == "tutorial" else {
            return
        }
        
        defaults.set(true, forKey: kHasViewedTutorial)
    }
    
    @IBAction func shareFirewallMetricsTapped(_ sender: Any) {
        let thousandsFormatter = NumberFormatter()
        thousandsFormatter.groupingSeparator = ","
        thousandsFormatter.numberStyle = .decimal
        
        let imageSize = CGSize(width: 720, height: 420)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        let image = renderer.image { ctx in
            
            let rectangle = CGRect(origin: CGPoint.zero, size: imageSize)
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.addRect(rectangle)
            ctx.cgContext.drawPath(using: .fill)

            UIImage(named: "share.png")!.draw(in: CGRect(origin: CGPoint.zero, size: imageSize))

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let sinceAttrs = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30, weight: .semibold),
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: UIColor(red: 176/255, green: 176/255, blue: 176/255, alpha: 0.59)
            ]
            let sinceY = 90
            
            var date = "INSTALL"
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMM d YYYY")
            if let appInstall = appInstallDate {
                date = formatter.string(from: appInstall).uppercased()
            }
            
            "since_date".localized(inserting: date).draw(
                with: CGRect(origin: CGPoint(x: 0, y: sinceY), size: CGSize(width: 720, height: 50)),
                options: .usesLineFragmentOrigin, attributes: sinceAttrs, context: nil)
            
            let attributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 46, weight: .bold),
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: UIColor(red: 149/255, green: 149/255, blue: 149/255, alpha: 1.0)
            ]
            
            let countSize = CGSize(width: 240, height: 50)
            let countY = 216
            
            thousandsFormatter.string(for: getDayMetrics())!.draw(
                with: CGRect(origin: CGPoint(x: 0, y: countY), size: countSize),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil)
            thousandsFormatter.string(for: getWeekMetrics())!.draw(
                with: CGRect(origin: CGPoint(x: 240, y: countY), size: countSize),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil)
            thousandsFormatter.string(for: getTotalMetrics())!.draw(
                with: CGRect(origin: CGPoint(x: 480, y: countY), size: countSize),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil)
        }

        let message = """
Show how invasive today's apps are, and help other people block trackers and badware, too.

Your block log is not included - only the image above. Choose where to share in the next step.
"""
        let popup = PopupDialog(
            title: .localized("Share Your Stats"),
            message: .localized(message),
            image: image,
            buttonAlignment: .horizontal,
            transitionStyle: .bounceDown,
            preferredWidth: 300.0,
            tapGestureDismissal: true,
            panGestureDismissal: false,
            hideStatusBar: true,
            completion: nil)
        
        let cancelButton = CancelButton(title: .localizedCancel, dismissOnTap: true) {  }
        
        let shareButton = DefaultButton(title: .localized("Next"), dismissOnTap: true) {
            
            let metrics = thousandsFormatter.string(for: getTotalMetrics())!
            let shareText = "i_blocked_trackers_ads_and_badware_with_lockdown".localized(inserting: metrics)
            
            let vc = UIActivityViewController(activityItems: [LockdownCustomActivityItemProvider(text: shareText), image], applicationActivities: [])
            vc.completionWithItemsHandler = { (_, success, _, _) in
                if success {
                    self.showPopupDialog(
                        title: .localized("Success!"),
                        message: .localized("Thanks for helping to increase privacy and tracking awareness."),
                        acceptButton: .localized("Nice", comment: "Used as a button text in a popup. Like 'OK' except more excited."))
                }
            }
            vc.excludedActivityTypes = [.assignToContact, .addToReadingList, .openInIBooks, .postToVimeo, .print]
            
            if let popoverPC = vc.popoverPresentationController {
                popoverPC.sourceView = self.firewallShareButton
                popoverPC.sourceRect = self.firewallShareButton.bounds
                popoverPC.permittedArrowDirections = .up
            }
            self.present(vc, animated: true)
        }
        
        popup.addButtons([cancelButton, shareButton])
        self.present(popup, animated: true, completion: nil)
        
    }
    
    // MARK: - Firewall
    
    @objc func updateMetrics() {
        DispatchQueue.main.async {
            self.dailyMetrics?.text = getDayMetricsString()
            self.weeklyMetrics?.text = getWeekMetricsString()
            self.allTimeMetrics?.text = getTotalMetricsString()
        }
    }
    
    @IBAction func toggleFirewall(_ sender: Any) {
        if defaults.bool(forKey: kHasAgreedToFirewallPrivacyPolicy) == false {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let identifier = "firewallPrivacyPolicyViewController"
            guard let viewController = storyboard.instantiateViewController(withIdentifier: identifier) as? PrivacyPolicyViewController else { return }
            viewController.privacyPolicyKey = kHasAgreedToFirewallPrivacyPolicy
            viewController.parentVC = self
            self.present(viewController, animated: true, completion: nil)
            return
        }
        
        if getIsCombinedBlockListEmpty() {
            FirewallController.shared.setEnabled(false, isUserExplicitToggle: true)
            self.showPopupDialog(
                title: .localized("No Block Lists Enabled"),
                message: .localized("Please tap Block List and enable at least one block list to activate Firewall."),
                acceptButton: .localizedOkay)
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
            
            checkForAskRating()
        case .connected:
            updateFirewallButtonWithStatus(status: .disconnecting)
            FirewallController.shared.setEnabled(false, isUserExplicitToggle: true)
        case .connecting, .disconnecting, .reasserting:
            break
        }
    }
    
    func ensureFirewallWorkingAfterEnabling(waitingSeconds: TimeInterval) {
        FirewallController.shared.existingManagerCount { (count) in
            if count ?? 0 > 0 {
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
                                     activeLabel: firewallActive,
                                     toggleCircle: firewallToggleCircle,
                                     toggleAnimatedCircle: firewallToggleAnimatedCircle,
                                     button: firewallButton,
                                     prefixText: .localized("Firewall").uppercased())
    }
    
    // swiftlint:disable function_parameter_count
    func updateToggleButtonWithStatus(
        lastStatus: NEVPNStatus?,
        newStatus: NEVPNStatus,
        activeLabel: UILabel,
        toggleCircle: UIButton,
        toggleAnimatedCircle: NVActivityIndicatorView,
        button: UIButton,
        prefixText: String) {
            
        DDLogInfo("UpdateToggleButton")
        if newStatus == lastStatus {
            DDLogInfo("No status change from last time, ignoring.")
        } else {
            DispatchQueue.main.async {
                switch newStatus {
                case .connected:
                    activeLabel.text = "\(prefixText)\(String.localized(" On").uppercased())"
                    activeLabel.backgroundColor = UIColor.tunnelsBlue
                    toggleCircle.tintColor = .tunnelsBlue
                    toggleCircle.isHidden = false
                    toggleAnimatedCircle.stopAnimating()
                    button.tintColor = .tunnelsBlue
                case .connecting:
                    activeLabel.text = .localized("Activating").uppercased()
                    activeLabel.backgroundColor = .tunnelsBlue
                    toggleCircle.isHidden = true
                    toggleAnimatedCircle.color = .tunnelsBlue
                    toggleAnimatedCircle.startAnimating()
                    button.tintColor = .tunnelsBlue
                case .disconnected, .invalid:
                    activeLabel.text = "\(prefixText)\(String.localized(" Off").uppercased())"
                    activeLabel.backgroundColor = .tunnelsWarning
                    toggleCircle.tintColor = .lightGray
                    toggleCircle.isHidden = false
                    toggleAnimatedCircle.stopAnimating()
                    button.tintColor = .lightGray
                case .disconnecting:
                    activeLabel.text = .localized("Deactivating").uppercased()
                    activeLabel.backgroundColor = .lightGray
                    toggleCircle.isHidden = true
                    toggleAnimatedCircle.color = .lightGray
                    toggleAnimatedCircle.startAnimating()
                    button.tintColor = .lightGray
                case .reasserting:
                    break
                }
            }
        }
    }
    
    func highlightBlockLog() {
        let logButtonRect = getRectForView(firewallViewLogButton).insetBy(dx: -10.0, dy: -10.0)
        let logButtonSpotlightText: String = .localized("Tap to see the blocked tracking attempts.")
        let blockLogSpotlight = AwesomeSpotlight(withRect: logButtonRect, shape: .roundRectangle, text: logButtonSpotlightText)
        
        let spotlightView = AwesomeSpotlightView(frame: view.frame, spotlight: [blockLogSpotlight])
        spotlightView.accessibilityIdentifier = "highlightBlockLog"
        spotlightView.cutoutRadius = 8
        spotlightView.spotlightMaskColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        spotlightView.enableArrowDown = true
        spotlightView.textLabelFont = .mediumLockdownFont(size: 16)
        spotlightView.labelSpacing = 24
        view.addSubview(spotlightView)
        spotlightView.start()
    }
    
    // MARK: - VPN
    

    @IBAction func vpnQuestionTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "showWhatIsVPN", sender: self)
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
                                     activeLabel: vpnActive,
                                     toggleCircle: vpnToggleCircle,
                                     toggleAnimatedCircle: vpnToggleAnimatedCircle,
                                     button: vpnButton,
                                     prefixText: .localized("Tunnel").uppercased())
    }
    
    @IBAction func toggleVPN(_ sender: Any) {
        
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
                    if self.popupErrorAsNSURLError(error) {
                        return
                    } else if let apiError = error as? ApiError {
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
                               DefaultButton(title: .localizedCancel, dismissOnTap: true) {
                               },
                               DefaultButton(title: .localizedSignOut, dismissOnTap: true) {
                                URLCache.shared.removeAllCachedResponses()
                                Client.clearCookies()
                                clearAPICredentials()
                                setAPICredentialsConfirmed(confirmed: false)
                                self.showPopupDialog(
                                    title: .localized("Success"),
                                    message: .localized("Signed out successfully."),
                                    acceptButton: .localizedOkay)
                               },
                            ])
                            self.present(confirm, animated: true, completion: nil)
                        case kApiCodeNoSubscriptionInReceipt:
                            self.showPaywallIfNoSubscription()
                        case kApiCodeNoActiveSubscription:
                            self.showPopupDialog(
                                title: .localized("Subscription Expired"),
                                message: .localized("Please renew your subscription to activate the Secure Tunnel."),
                                acceptButton: .localizedOkay) {
                                    self.showPaywallIfNoSubscription()
                                }
                        default:
                            _ = self.popupErrorAsApiError(error)
                        }
                    }
                }
            } else {
                firstly {
                    try Client.signIn() // this will fetch and set latest receipt, then submit to API to get cookie
                }
                .then { _ -> Promise<GetKey> in
                    // TODO: don't always do this -- if we already have a key, then only do it once per day max
                    try Client.getKey()
                }
                .done { (getKey: GetKey) in
                    try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                    VPNController.shared.setEnabled(true)
                }
                .catch { error in
                    self.updateVPNButtonWithStatus(status: .disconnected)
                    
                    if self.popupErrorAsNSURLError(error) {
                        return
                    } else if let apiError = error as? ApiError {
                        switch apiError.code {
                        case kApiCodeNoSubscriptionInReceipt:
                            self.showPaywallIfNoSubscription()
                        case kApiCodeNoActiveSubscription:
                            self.showPopupDialog(
                                title: .localized("Subscription Expired"),
                                message: .localized("Please renew your subscription to activate the Secure Tunnel."),
                                acceptButton: .localizedOkay) {
                                    self.showPaywallIfNoSubscription()
                                }
                        default:
                            if apiError.code == kApiCodeNegativeError {
                                if getVPNCredentials() != nil {
                                    DDLogError("Unknown error -1 from API, but VPNCredentials exists, so activating anyway.")
                                    self.updateVPNButtonWithStatus(status: .connecting)
                                    VPNController.shared.setEnabled(true)
                                } else {
                                    let message = """
There is currently an outage at Apple which is preventing Secure Tunnel from activating. \
This will likely by resolved by Apple soon, and we apologize for this issue in the meantime.
""" + .localized("\n\n If this error persists, please contact team@lockdownprivacy.com.")
                                    self.showPopupDialog(
                                        title: .localized("Apple Outage"),
                                        message: message,
                                        acceptButton: .localizedOkay)
                                }
                            } else {
                                _ = self.popupErrorAsApiError(error)
                            }
                        }
                    } else {
                        self.showPopupDialog(title: .localized("Error Signing In To Verify Subscription"),
                                             message: "\(error)",
                                             acceptButton: .localizedOkay)
                    }
                }
            }
            
        }
    }
    
    @IBAction func viewAuditReportTapped(_ sender: Any) {
        showAuditModal()
    }
    
    @IBAction func showWhitelist(_ sender: Any) {
        performSegue(withIdentifier: "showWhitelist", sender: nil)
    }
    
    @IBAction func showSetRegion(_ sender: Any) {
        performSegue(withIdentifier: "showSetRegion", sender: nil)
    }
    
    func showBlockLog(_ sender: Any) {
        performSegue(withIdentifier: "showBlockLog", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showSetRegion":
            if let vc = segue.destination as? SetRegionViewController {
                vc.homeVC = self
            }
        case "showWhatIsVPN":
            if let vc = segue.destination as? WhatIsVpnViewController {
                vc.parentVC = self
            }
        case "showUpgradePlan":
            if let vc = segue.destination as? OldSignupViewController {
                if activePlans.isEmpty {
                    vc.mode = .newSubscription
                } else {
                    vc.mode = .upgrade(active: activePlans)
                }
            }
        default:
            break
        }
    }
    
    func updateVPNRegionLabel() {
        vpnRegionLabel.text = getSavedVPNRegion().regionDisplayNameShort
    }
    
    // MARK: - Helpers
    
    func checkForAskRating(delayInSeconds: TimeInterval = 5.0) {
        DDLogInfo("Checking for ask rating")
        let ratingCount = defaults.integer(forKey: ratingCountKey) + 1
        DDLogInfo("Incrementing Rating Count: " + String(ratingCount))
        defaults.set(ratingCount, forKey: ratingCountKey)
        // not testflight
        if isTestFlight {
            DDLogInfo("Not doing rating for TestFlight")
            return
        }
        // greater than 3 days since install
        if let installDate = appInstallDate,
            let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day, daysSinceInstall <= 3 {
            DDLogInfo("Rating Check: Skipping - App was installed on \(installDate), fewer than 4 days since install - \(daysSinceInstall) days")
            return
        }
        // only check every 8th time connecting to this version
        if ratingCount % 8 != 0 {
            DDLogInfo("Rating Check: Skipping - ratingCount % 8 != 0: \(ratingCount)")
            return
        }
        // hasn't asked for this version 2 times already
        let ratingTriggered = defaults.integer(forKey: ratingTriggeredKey)
        if ratingTriggered >= 3 {
            DDLogInfo("Rating Check: Skipping - ratingTriggered greater or equal to 3: \(ratingTriggered)")
            return
        }
        // passed all checks, ask for rating
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            defaults.set(ratingTriggered + 1, forKey: self.ratingTriggeredKey)
            SKStoreReviewController.requestReview()
        }
    }
}

class LockdownCustomActivityItemProvider: UIActivityItemProvider {

    let shareText: String
    
    init(text: String) {
        self.shareText = text
        super.init(placeholderItem: text)
    }
    
    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            if let type = activityType {
                switch type {
                case .postToTwitter:
                    return shareText + " @lockdown_hq"
                default:
                    return shareText
                }
            } else {
                return shareText
            }
        }
}

// MARK: - Paywalling
extension HomeViewController: PaywallViewControllerCloseDelegate {
    func didClosePaywall() {
        guard UserDefaults.hasSeenLTO == false else { return }
        
        showLTOButtonIfEligible()
    }
    
    private func showEnableNotifications() {
        let enableNotificationsViewController = EnableNotificationsViewController()
        enableNotificationsViewController.modalPresentationStyle = .overFullScreen
        present(enableNotificationsViewController, animated: true)
    }
    
    private func showPaywallIfNoSubscription() {
        guard BaseUserService.shared.user.currentSubscription == nil else { return }
        guard BasePaywallService.shared.context == .normal else { return }
        
        BasePaywallService.shared.showPaywall(on: self)
        
        UserDefaults.hasSeenPaywallOnHomeScreen = true
    }
}

fileprivate extension PopupDialogButton {
    func startActivityIndicator() {
        let activity = UIActivityIndicatorView()
        
        if let label = titleLabel {
            label.addSubview(activity)
            activity.translatesAutoresizingMaskIntoConstraints = false
            activity.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
            activity.leadingAnchor.constraint(equalToSystemSpacingAfter: label.trailingAnchor, multiplier: 1).isActive = true
            activity.startAnimating()
        }
    }
    
    func stopActivityIndicator() {
        if let label = titleLabel {
            let indicators = label.subviews.compactMap { $0 as? UIActivityIndicatorView }
            for indicator in indicators {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
}

final class DynamicButton: PopupDialogButton {
    var onTap: ((DynamicButton) -> Void)?
    
    override var buttonAction: PopupDialogButton.PopupDialogButtonAction? {
        if let onTap = onTap {
            return { [weak self] in if let value = self { return onTap(value) } }
        } else {
            return nil
        }
    }
}

extension NEVPNStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .invalid:
            return "invalid"
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .reasserting:
            return "reasserting"
        case .disconnecting:
            return "disconnecting"
        }
    }
    
}

extension HomeViewController: AwesomeSpotlightViewDelegate {
    func spotlightView(_ spotlightView: AwesomeSpotlightView, willNavigateToIndex index: Int) {
        let accountTabSpotlightIndex = 7
        
        if index == accountTabSpotlightIndex {
            spotlightView.backgroundColor = .white.withAlphaComponent(0.2)
            spotlightView.spotlightMaskColor = .clear.withAlphaComponent(0.8)
        }
    }
}

// MARK: - LTO
extension HomeViewController: LTOViewControllerCloseDelegate, CountdownDisplayDelegate {
    func didFinishCountdown() {
        DDLogInfo("Removing lto button.")
        UIView.animate(withDuration: 0.4, animations: {
            self.ltoButton?.transform = .init(scaleX: 0.001, y: 0.001)
            self.ltoButton?.titleLabel?.alpha = 0
        }) { _ in
            self.ltoButton?.removeFromSuperview()
            self.ltoButton = nil
        }
    }
    
    func didCloseLTOPaywall() {
        guard let ltoButton else { return }
        countdownDisplayService.startUpdating(button: ltoButton)
    }
    
    func showLTOButtonIfEligible() {
        // To check for case when when user has redeemed code and has got a subscription.
        // In this case, the button has already been created, but we should remove it and show nothing.
        guard BaseUserService.shared.user.currentSubscription == nil else {
            DDLogInfo("Removing lto button when user has redeemed code but button has been created.")
            ltoButton?.removeFromSuperview()
            ltoButton = nil
            return
        }
        guard let ltoButton = self.ltoButton else { return }
        
        countdownDisplayService.startUpdating(button: ltoButton)
        countdownDisplayService.delegates.append(WeakObject(self))
        
        DDLogInfo("Showing lto button.")
        ltoButton.showAnimatedPress(duration: 0.4, withScale: 1.2) {
            UserDefaults.hasSeenLTO = true
        }
    }
    
    private func addLTOButtonIfEligible() {
        guard UserDefaults.hasSeenLTO == false else { return }
        guard LimitedTimeOffer() != nil else { return }
        guard ltoButton == nil else { return }
        
        DDLogInfo("Creating lto button")
        ltoButton = UIButton()
        
        guard let ltoButton else { return }
        updateLtoButtonFrame()
        
        ltoButton.addTarget(self, action: #selector(didTapLTOButton), for: .touchUpInside)
        
        view.addSubview(ltoButton)
        
        ltoButton.backgroundColor = .fromHex("#F93B58")
        ltoButton.corners = .continuous(ltoButton.frame.height / 2)
        
        ltoButton.titleLabel?.font = .boldLockdownFont(size: 18)
        ltoButton.transform = .init(scaleX: 0, y: 0)
        ltoButton.applyGradient(.ltoButtonOnHomePage, corners: ltoButton.corners)
    }
    
    private func updateLtoButtonFrame() {
        guard let tabBarButton = (tabBarController as? MainTabBarController)?.accountTabBarButton else { return }
        
        let buttonHeight: CGFloat = 64
        let buttonWidth: CGFloat = 100
        let buttonTrailingOffset: CGFloat = 16
        let buttonBottomOffset: CGFloat = 50
        ltoButton?.frame = .init(origin: .init(x: tabBarButton.frame.maxX - buttonWidth - buttonTrailingOffset,
                                                        y: view.frame.maxY - tabBarButton.frame.height - buttonBottomOffset - buttonHeight),
                                          size: .init(width: buttonWidth, height: buttonHeight))
    }
    
    @objc private func didTapLTOButton() {
        ltoButton?.showAnimatedPress { [weak self] in
            guard let self else { return }
            self.paywallService.showPaywall(on: self, forceSpecialOffer: true)
        }
    }
}
