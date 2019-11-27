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
        self.layer.cornerRadius = self.bounds.size.width * 0.50
    }
}

class HomeViewController: BaseViewController, AwesomeSpotlightViewDelegate {
    
    let kHasViewedTutorial = "hasViewedTutorial"
    let kHasSeenInitialFirewallConnectedDialog = "hasSeenInitialFirewallConnectedDialog11"
    let kVPNBodyViewVisible = "VPNBodyViewVisible"
    let kHasSeenShare = "hasSeenShareDialog4"
    
    let ratingCountKey = "ratingCount" + lastVersionToAskForRating
    let ratingTriggeredKey = "ratingTriggered" + lastVersionToAskForRating
    
    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet var stackEqualHeightConstraint: NSLayoutConstraint!
    
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
    var metricsTimer : Timer?
    @IBOutlet weak var firewallSettingsButton: UIButton!
    @IBOutlet weak var firewallViewLogButton: UIButton!
    @IBOutlet weak var firewallShareButton: UIButton!
    
    @IBOutlet var vpnViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var vpnHeaderView: UIView!
    @IBOutlet weak var vpnHideButton: UIButton!
    @IBOutlet weak var vpnBodyView: UIView!
    @IBOutlet weak var vpnActive: UILabel!
    @IBOutlet var vpnActiveHeaderConstraint: NSLayoutConstraint!
    @IBOutlet var vpnActiveTopBodyConstraint: NSLayoutConstraint!
    @IBOutlet var vpnActiveVerticalBodyConstraint: NSLayoutConstraint!
    @IBOutlet weak var vpnToggleCircle: UIButton!
    @IBOutlet weak var vpnToggleAnimatedCircle: NVActivityIndicatorView!
    @IBOutlet weak var vpnButton: UIButton!
//    @IBOutlet weak var vpnIP: UILabel!
//    @IBOutlet weak var vpnSpeed: UILabel!
    var lastVPNStatus: NEVPNStatus?
    @IBOutlet weak var vpnSetRegionButton: UIButton!
    @IBOutlet weak var vpnRegionLabel: UILabel!
    @IBOutlet weak var vpnWhitelistButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateFirewallButtonWithStatus(status: FirewallController.shared.status())
        updateMetrics()
        if metricsTimer == nil {
            metricsTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(updateMetrics), userInfo: nil, repeats: true)
            metricsTimer?.fire()
        }
        firewallViewLogButton.layer.cornerRadius = 8
        firewallViewLogButton.layer.maskedCorners = [.layerMinXMaxYCorner]
        firewallSettingsButton.layer.cornerRadius = 8
        firewallSettingsButton.layer.maskedCorners = [.layerMaxXMaxYCorner]

        vpnHeaderView.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector (vpnHeaderTapped(_:))) )
        updateVPNButtonWithStatus(status: VPNController.shared.status())
        //updateIP()
        vpnWhitelistButton.layer.cornerRadius = 8
        vpnWhitelistButton.layer.maskedCorners = [.layerMinXMaxYCorner]
        vpnSetRegionButton.layer.cornerRadius = 8
        vpnSetRegionButton.layer.maskedCorners = [.layerMaxXMaxYCorner]
        updateVPNRegionLabel()
        
        // Check Subscription - if VPN active but not subscribed, then disconnect and show dialog (don't do this if connection error)
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
        
        // Check that Firewall is still working correctly, restart it if it's not
        FirewallController.shared.refreshManager(completion: { error in
            if let e = error {
                DDLogError("Error refreshing Manager in Home viewdidappear: \(e)")
                return
            }
            if getUserWantsFirewallEnabled() && (FirewallController.shared.status() == .connected || FirewallController.shared.status() == .invalid) {
                DDLogInfo("User wants firewall enabled and connected/invalid, testing blocking in Home")
                _ = Client.getBlockedDomainTest(connectionSuccessHandler: {
                    DDLogError("Home Firewall Test: Connected to \(testFirewallDomain) even though it's supposed to be blocked, restart the Firewall")
                    FirewallController.shared.restart(completion: {
                        error in
                        if error != nil {
                            DDLogError("Error restarting firewall on Home: \(error!)")
                        }
                    })
                }, connectionFailedHandler: {
                    error in
                    if error != nil {
                        let nsError = error! as NSError
                        if nsError.domain == NSURLErrorDomain {
                            DDLogInfo("Home Firewall Test: Successful blocking of \(testFirewallDomain) with NSURLErrorDomain error: \(nsError)")
                        }
                        else {
                            DDLogInfo("Home Firewall Test: Successful blocking of \(testFirewallDomain), but seeing non-NSURLErrorDomain error: \(error!)")
                        }
                    }
                })
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toggleVPNBodyView(animate: false, show: defaults.bool(forKey: kVPNBodyViewVisible))
        if (defaults.bool(forKey: kHasViewedTutorial) == false) {
            startTutorial()
        }
        if defaults.bool(forKey: kHasSeenInitialFirewallConnectedDialog) == false {
            tapToActivateFirewallLabel.isHidden = false
        }
        
        // If total blocked > 1000, and have not shown share dialog before, ask if user wants to share
        if (getTotalMetrics() > 1000 && defaults.bool(forKey: kHasSeenShare) != true) {
            defaults.set(true, forKey: kHasSeenShare)
            let popup = PopupDialog(title: "You've blocked over 1000 trackers! 🎊",
                                     message: NSLocalizedString("Share your anonymized metrics and show other people how to block invasive tracking.", comment: ""),
                                     image: nil,
                                     buttonAlignment: .horizontal,
                                     transitionStyle: .bounceDown,
                                     preferredWidth: 270,
                                     tapGestureDismissal: true,
                                     panGestureDismissal: false,
                                     hideStatusBar: false,
                                     completion: nil)
             popup.addButtons([
                CancelButton(title: NSLocalizedString("Not Now", comment: ""), dismissOnTap: true) {
                    let s0 = AwesomeSpotlight(withRect: self.getRectForView(self.firewallShareButton).insetBy(dx: -13.0, dy: -13.0), shape: .roundRectangle, text: NSLocalizedString("You can tap this later if you feel like sharing.\n(Tap anywhere to dismiss)", comment: ""))
                    let spotlightView = AwesomeSpotlightView(frame: self.view.frame,
                                                             spotlight: [s0])
                    spotlightView.cutoutRadius = 8
                    spotlightView.spotlightMaskColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75);
                    spotlightView.enableArrowDown = true
                    spotlightView.textLabelFont = fontMedium16
                    spotlightView.labelSpacing = 24;
                    spotlightView.delegate = self
                    self.view.addSubview(spotlightView)
                    spotlightView.start()
                },
                DefaultButton(title: NSLocalizedString("Next", comment: ""), dismissOnTap: true) {
                    self.shareFirewallMetricsTapped("")
                }
             ])
             self.present(popup, animated: true, completion: nil)
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
        
//        let whatisVpnButton = DefaultButton(title: "What is a VPN?", dismissOnTap: true) {
//            self.toggleVPNBodyView(animate: true, show: true)
//            self.performSegue(withIdentifier: "showWhatIsVPN", sender: self)
//        }
        let getEnhancedPrivacyButton = DefaultButton(title: NSLocalizedString("1 Week Free", comment: ""), dismissOnTap: true) {
            self.toggleVPNBodyView(animate: true, show: true)
            self.performSegue(withIdentifier: "showSignup", sender: self)
        }
        let laterButton = CancelButton(title: NSLocalizedString("Skip Trial", comment: ""), dismissOnTap: true) { }
        
        popup.addButtons([laterButton, getEnhancedPrivacyButton])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    // This notification is triggered for both Firewall and VPN
    @objc func tunnelStatusDidChange(_ notification: Notification) {
        // Firewall
        if let tunnelProviderSession = notification.object as? NETunnelProviderSession {
            DDLogInfo("VPNStatusDidChange as NETunnelProviderSession with status: \(tunnelProviderSession.status.rawValue)");
            if (!getUserWantsFirewallEnabled()) {
                updateFirewallButtonWithStatus(status: .disconnected)
            }
            else {
                updateFirewallButtonWithStatus(status: tunnelProviderSession.status)
                if (tunnelProviderSession.status == .connected && defaults.bool(forKey: kHasSeenInitialFirewallConnectedDialog) == false) {
                    defaults.set(true, forKey: kHasSeenInitialFirewallConnectedDialog)
                    self.tapToActivateFirewallLabel.isHidden = true
                    if (VPNController.shared.status() == .invalid) {
                        self.showVPNSubscriptionDialog(title: NSLocalizedString("🔥🧱 Firewall Activated 🎊🎉", comment: ""), message: NSLocalizedString("Trackers, ads, and other malicious scripts are now blocked in all your apps, even outside of Safari.\n\nGet maximum privacy with a Secure Tunnel that uses bank-level encryption to protect your connections, anonymize your browsing history, and hide your location.", comment: ""))
                    }
                }
            }
        }
        // VPN
        else if let neVPNConnection = notification.object as? NEVPNConnection {
            DDLogInfo("VPNStatusDidChange as NEVPNConnection with status: \(neVPNConnection.status.rawValue)");
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
    
    // MARK: - Top Buttons
    
    @IBAction func menuTapped(_ sender: Any) {
        let popup = PopupDialog(title: nil,
                                message: NSLocalizedString("For suggestions, questions, and issues, please tap Email Support.", comment: ""),
                                image: nil,
                                buttonAlignment: .vertical,
                                transitionStyle: .bounceDown,
                                preferredWidth: 270,
                                tapGestureDismissal: true,
                                panGestureDismissal: false,
                                hideStatusBar: false,
                                completion: nil)
        popup.addButtons([
            DefaultButton(title: NSLocalizedString("Tutorial", comment: ""), dismissOnTap: true) {
                self.startTutorial()
            },
            DefaultButton(title: NSLocalizedString("Why Trust Lockdown", comment: ""), dismissOnTap: true) {
                self.showWhyTrustPopup()
            },
            DefaultButton(title: NSLocalizedString("Privacy Policy", comment: ""), dismissOnTap: true) {
                self.showPrivacyPolicyModal()
            },
            DefaultButton(title: NSLocalizedString("What is VPN?", comment: ""), dismissOnTap: true) {
                self.performSegue(withIdentifier: "showWhatIsVPN", sender: self)
            },
            DefaultButton(title: NSLocalizedString("Email Support", comment: ""), dismissOnTap: true) {
                self.emailTeam()
            },
            DefaultButton(title: NSLocalizedString("Website", comment: ""), dismissOnTap: true) {
                self.showWebsiteModal()
            },
            CancelButton(title: NSLocalizedString("Cancel", comment: ""), dismissOnTap: true) {}
        ])
        self.present(popup, animated: true, completion: nil)
    }
    
    func startTutorial() {
        let centerPoint = UIScreen.main.bounds.center
        let s0 = AwesomeSpotlight(withRect: CGRect(x: centerPoint.x, y: centerPoint.y - 100, width: 0, height: 0), shape: .circle, text: NSLocalizedString("Welcome to the Lockdown Tutorial.\n\nTap anywhere to continue.", comment: ""))
        let s1 = AwesomeSpotlight(withRect: getRectForView(firewallTitleLabel).insetBy(dx: -13.0, dy: -13.0), shape: .roundRectangle, text: NSLocalizedString("Lockdown Firewall blocks bad and untrusted connections in all your apps - not just Safari.", comment: ""))
        let s2 = AwesomeSpotlight(withRect: getRectForView(firewallToggleCircle).insetBy(dx: -10.0, dy: -10.0), shape: .circle, text: NSLocalizedString("Activate Firewall with this button.", comment: ""))
        let s3 = AwesomeSpotlight(withRect: getRectForView(metricsStack).insetBy(dx: -10.0, dy: -10.0), shape: .roundRectangle, text: NSLocalizedString("See live metrics for how many bad connections Firewall has blocked.", comment: ""))
        let s4 = AwesomeSpotlight(withRect: getRectForView(firewallViewLogButton).insetBy(dx: -10.0, dy: -10.0), shape: .roundRectangle, text: NSLocalizedString("\"View Log\" shows exactly what connections were blocked in the past day. This log is cleared at midnight and stays on-device, so it's only visible to you.", comment: ""))
        let s5 = AwesomeSpotlight(withRect: getRectForView(firewallSettingsButton).insetBy(dx: -10.0, dy: -10.0), shape: .roundRectangle, text: NSLocalizedString("\"Block List\" lets you choose what you want to block (e.g, Facebook, clickbait, etc). You can also set custom domains to block.", comment: ""))
        let s6 = AwesomeSpotlight(withRect: getRectForView(vpnHeaderView).insetBy(dx: -10.0, dy: -10.0), shape: .roundRectangle, text: NSLocalizedString("For maximum privacy, activate Secure Tunnel, which uses bank-level encryption to protect connections, anonymize your browsing, and hide your location and IP.", comment: ""))
        let s7 = AwesomeSpotlight(withRect: getRectForView(menuButton).insetBy(dx: -10.0, dy: -10.0), shape: .roundRectangle, text: NSLocalizedString("To see this tutorial again, tap the Menu button.", comment: ""))
        
        let spotlightView = AwesomeSpotlightView(frame: view.frame,
                                                 spotlight: [s0, s1, s2, s3, s4, s5, s6, s7])
        spotlightView.cutoutRadius = 8
        spotlightView.spotlightMaskColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75);
        spotlightView.enableArrowDown = true
        spotlightView.textLabelFont = fontMedium16
        spotlightView.labelSpacing = 24;
        spotlightView.delegate = self
        view.addSubview(spotlightView)
        spotlightView.start()
    }
    
    func spotlightViewDidCleanup(_ spotlightView: AwesomeSpotlightView) {
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
            
            let sinceAttrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30, weight: .semibold), NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: UIColor(red: 176/255, green: 176/255, blue: 176/255, alpha: 0.59)]
            let sinceY = 90
            
            var date = "INSTALL"
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d YYYY"
            if let appInstall = appInstallDate {
                date = formatter.string(from: appInstall).uppercased()
            }
            
            "SINCE \(date)".draw(with: CGRect(origin: CGPoint(x: 0, y: sinceY), size: CGSize(width: 720, height: 50)), options: .usesLineFragmentOrigin, attributes: sinceAttrs, context: nil)
            
            let attrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 46, weight: .bold), NSAttributedString.Key.paragraphStyle: paragraphStyle,  NSAttributedString.Key.foregroundColor: UIColor(red: 149/255, green: 149/255, blue: 149/255, alpha: 1.0)]
            
            let countSize = CGSize(width: 240, height: 50)
            let countY = 216
            
            thousandsFormatter.string(for: getDayMetrics())!.draw(with: CGRect(origin: CGPoint(x: 0, y: countY), size: countSize), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            thousandsFormatter.string(for: getWeekMetrics())!.draw(with: CGRect(origin: CGPoint(x: 240, y: countY), size: countSize), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            thousandsFormatter.string(for: getTotalMetrics())!.draw(with: CGRect(origin: CGPoint(x: 480, y: countY), size: countSize), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
         
        }

        let popup = PopupDialog(
            title: NSLocalizedString("Share Your Stats", comment: ""),
            message: NSLocalizedString("Show how invasive today's apps are, and help other people block trackers and badware, too.\n\nYour block log is not included - only the image above. Choose where to share in the next step.", comment: ""),
            image: image,
            buttonAlignment: .horizontal,
            transitionStyle: .bounceDown,
            preferredWidth: 300.0,
            tapGestureDismissal: true,
            panGestureDismissal: false,
            hideStatusBar: true,
            completion: nil)
        
        let cancelButton = CancelButton(title: NSLocalizedString("Cancel", comment: ""), dismissOnTap: true) {  }
        
        let shareButton = DefaultButton(title: NSLocalizedString("Next", comment: ""), dismissOnTap: true) {
            let shareText = NSLocalizedString("I blocked \(thousandsFormatter.string(for: getTotalMetrics())!) trackers, ads, and badware with Lockdown, the firewall that blocks unwanted connections in all your apps. Get it free at lockdownhq.com.", comment: "")
            let vc = UIActivityViewController(activityItems: [LockdownCustomActivityItemProvider(text: shareText), image], applicationActivities: [])
            vc.completionWithItemsHandler = { (activity, success, items, error) in
                if (success) {
                    self.showPopupDialog(title: NSLocalizedString("Success!", comment: ""), message: NSLocalizedString("Thanks for helping to increase privacy and tracking awareness.", comment: ""), acceptButton: NSLocalizedString("Nice", comment: ""))
                }
                print(success ? "SUCCESS!" : "FAILURE")
            }
            vc.excludedActivityTypes = [ UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.postToVimeo, UIActivity.ActivityType.print ]
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
        if (defaults.bool(forKey: kHasAgreedToFirewallPrivacyPolicy) == false) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "firewallPrivacyPolicyViewController") as! PrivacyPolicyViewController
            viewController.privacyPolicyKey = kHasAgreedToFirewallPrivacyPolicy
            viewController.parentVC = self
            self.present(viewController, animated: true, completion: nil)
            return
        }
        
        switch FirewallController.shared.status() {
        case .invalid:
            FirewallController.shared.setEnabled(true, isUserExplicitToggle: true)
        case .disconnected:
            updateFirewallButtonWithStatus(status: .connecting)
            FirewallController.shared.setEnabled(true, isUserExplicitToggle: true)
            
            checkForAskRating()
        case .connected:
            updateFirewallButtonWithStatus(status: .disconnecting)
            FirewallController.shared.setEnabled(false, isUserExplicitToggle: true)
        case .connecting, .disconnecting, .reasserting:
            break;
        }
    }
    
    func updateFirewallButtonWithStatus(status: NEVPNStatus) {
        DDLogInfo("UpdateFirewallButton")
        updateToggleButtonWithStatus(lastStatus: lastFirewallStatus,
                                     newStatus: status,
                                     activeLabel: firewallActive,
                                     toggleCircle: firewallToggleCircle,
                                     toggleAnimatedCircle: firewallToggleAnimatedCircle,
                                     button: firewallButton,
                                     prefixText: NSLocalizedString("FIREWALL", comment: ""))
    }
    
    func updateToggleButtonWithStatus(lastStatus: NEVPNStatus?, newStatus: NEVPNStatus, activeLabel: UILabel, toggleCircle: UIButton, toggleAnimatedCircle: NVActivityIndicatorView, button: UIButton, prefixText: String) {
        DDLogInfo("UpdateToggleButton")
        if (newStatus == lastStatus) {
            DDLogInfo("No status change from last time, ignoring.");
        }
        else {
            DispatchQueue.main.async() {
                switch newStatus {
                case .connected:
                    activeLabel.text = prefixText + NSLocalizedString(" ON", comment: "")
                    activeLabel.backgroundColor = UIColor.tunnelsBlue
                    toggleCircle.tintColor = .tunnelsBlue
                    toggleCircle.isHidden = false
                    toggleAnimatedCircle.stopAnimating()
                    button.tintColor = .tunnelsBlue
                case .connecting:
                    activeLabel.text = NSLocalizedString("ACTIVATING", comment: "")
                    activeLabel.backgroundColor = .tunnelsBlue
                    toggleCircle.isHidden = true
                    toggleAnimatedCircle.color = .tunnelsBlue
                    toggleAnimatedCircle.startAnimating()
                    button.tintColor = .tunnelsBlue
                case .disconnected, .invalid:
                    activeLabel.text = prefixText + NSLocalizedString(" OFF", comment: "")
                    activeLabel.backgroundColor = .tunnelsWarning
                    toggleCircle.tintColor = .lightGray
                    toggleCircle.isHidden = false
                    toggleAnimatedCircle.stopAnimating()
                    button.tintColor = .lightGray
                case .disconnecting:
                    activeLabel.text = NSLocalizedString("DEACTIVATING", comment: "")
                    activeLabel.backgroundColor = .lightGray
                    toggleCircle.isHidden = true
                    toggleAnimatedCircle.color = .lightGray
                    toggleAnimatedCircle.startAnimating()
                    button.tintColor = .lightGray
                case .reasserting:
                    break;
                }
            }
        }
    }
    
    // MARK: - VPN
    
    @objc @IBAction func vpnHeaderTapped(_ sender: Any) {
        toggleVPNBodyView(animate: true)
    }
    
    @IBAction func vpnQuestionTapped(_ sender: Any) {
        toggleVPNBodyView(animate: false, show: true)
        self.performSegue(withIdentifier: "showWhatIsVPN", sender: self)
    }
    
    func toggleVPNBodyView(animate: Bool, show: Bool? = nil) {
        // always show
        self.vpnHideButton.setTitle(NSLocalizedString("HIDE", comment: ""), for: .normal)
        self.vpnBodyView.alpha = 1
        self.vpnActiveHeaderConstraint.isActive = false
        self.vpnActiveTopBodyConstraint.isActive = true
        self.vpnActiveVerticalBodyConstraint.isActive = true
        self.stackEqualHeightConstraint.isActive = true
        self.vpnViewHeightConstraint.isActive = false
        self.view.layoutIfNeeded()
        return
        
        // If supplied a "show", use that. Otherwise, use the opposite of the current visible state (show -> hide, hide -> show)
        var shouldShow = false
        if show != nil {
            shouldShow = show!
        }
        else {
            shouldShow = !(defaults.bool(forKey: kVPNBodyViewVisible))
        }
        
        var animationTime = 0.0
        if (animate) {
            animationTime = 0.2
        }
        if (shouldShow) {
            vpnBodyView.alpha = 0
            self.vpnBodyView.isHidden = false
            UIView.animate(withDuration: animationTime, animations: {
                self.vpnHideButton.setTitle(NSLocalizedString("HIDE", comment: ""), for: .normal)
                self.vpnBodyView.alpha = 1
                self.vpnActiveHeaderConstraint.isActive = false
                self.vpnActiveTopBodyConstraint.isActive = true
                self.vpnActiveVerticalBodyConstraint.isActive = true
                self.stackEqualHeightConstraint.isActive = true
                self.vpnViewHeightConstraint.isActive = false
                self.view.layoutIfNeeded()
            }, completion: { complete in
                defaults.set(true, forKey: self.kVPNBodyViewVisible)
            })
        }
        else {
            UIView.animate(withDuration: animationTime, animations: {
                self.vpnHideButton.setTitle(NSLocalizedString("SHOW", comment: ""), for: .normal)
                self.vpnBodyView.alpha = 0
                self.vpnActiveHeaderConstraint.isActive = true
                self.vpnActiveTopBodyConstraint.isActive = false
                self.vpnActiveVerticalBodyConstraint.isActive = false
                self.stackEqualHeightConstraint.isActive = false
                self.vpnViewHeightConstraint.constant = self.vpnHeaderView.frame.height
                self.vpnViewHeightConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { complete in
                self.vpnBodyView.isHidden = true
                defaults.set(false, forKey: self.kVPNBodyViewVisible)
            })
        }
    }
    
    func updateVPNButtonWithStatus(status: NEVPNStatus) {
        DDLogInfo("UpdateVPNButton")
        updateToggleButtonWithStatus(lastStatus: lastVPNStatus,
                                     newStatus: status,
                                     activeLabel: vpnActive,
                                     toggleCircle: vpnToggleCircle,
                                     toggleAnimatedCircle: vpnToggleAnimatedCircle,
                                     button: vpnButton,
                                     prefixText: NSLocalizedString("TUNNEL", comment: ""))
    }
    
    @IBAction func toggleVPN(_ sender: Any) {
        // redundant - privacy policy agreement already happens in Firewall activation
//        if (defaults.bool(forKey: kHasAgreedToVPNPrivacyPolicy) == false) {
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let viewController = storyboard.instantiateViewController(withIdentifier: "vpnPrivacyPolicyViewController") as! PrivacyPolicyViewController
//            viewController.privacyPolicyKey = kHasAgreedToVPNPrivacyPolicy
//            viewController.parentVC = self
//            self.present(viewController, animated: true, completion: nil)
//            return
//        }
        
        DDLogInfo("Toggle VPN")
        switch VPNController.shared.status() {
        case .connected, .connecting, .reasserting:
            DDLogInfo("Toggle VPN: on currently, turning it off")
            updateVPNButtonWithStatus(status: .disconnecting)
            VPNController.shared.setEnabled(false)
        case .disconnected, .disconnecting, .invalid:
            DDLogInfo("Toggle VPN: off currently, turning it on")
            updateVPNButtonWithStatus(status: .connecting)
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
                        _ = self.popupErrorAsApiError(error)
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
    
    @IBAction func viewAuditReportTapped(_ sender: Any) {
        showAuditModal()
    }
    
    @IBAction func showWhitelist(_ sender: Any) {
        performSegue(withIdentifier: "showWhitelist", sender: nil)
    }
    
    @IBAction func showSetRegion(_ sender: Any) {
        performSegue(withIdentifier: "showSetRegion", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showSetRegion") {
            if let vc = segue.destination as? SetRegionViewController {
                vc.homeVC = self
            }
        }
        else if (segue.identifier == "showWhatIsVPN") {
            if let vc = segue.destination as? WhatIsVpnViewController {
                vc.parentVC = self
            }
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
        if (isTestFlight) {
            DDLogInfo("Not doing rating for TestFlight")
            return
        }
        // greater than 3 days since install
        if let installDate = appInstallDate, let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day, daysSinceInstall <= 3 {
            DDLogInfo("Rating Check: Skipping - App was installed on \(installDate), fewer than 4 days since install - \(daysSinceInstall) days")
            return
        }
        // only check every 8th time connecting to this version
        if (ratingCount % 8 != 0) {
            DDLogInfo("Rating Check: Skipping - ratingCount % 8 != 0: \(ratingCount)")
            return
        }
        // hasn't asked for this version 2 times already
        let ratingTriggered = defaults.integer(forKey: ratingTriggeredKey)
        if (ratingTriggered >= 3) {
            DDLogInfo("Rating Check: Skipping - ratingTriggered greater or equal to 3: \(ratingTriggered)")
            return
        }
        // passed all checks, ask for rating
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            defaults.set(ratingTriggered + 1, forKey: self.ratingTriggeredKey)
            SKStoreReviewController.requestReview()
        }
    }
    
//    func updateIP() {
//        DDLogInfo("Updating IP")
//        self.vpnIP.text = "—"
//        firstly {
//            Client.getIP()
//        }
//        .done { (ip: IP) in
//            DispatchQueue.main.async {
//                self.vpnIP.text = ip.ip
//            }
//        }
//        .catch { error in
//            self.vpnIP.text = "error"
//            DDLogError("Error getting IP: \(error)")
//        }
//    }
    
//    @IBAction func runSpeedTest() {
//        DDLogInfo("Speed Test")
//        vpnSpeed.text = "Testing..."
//        vpnSpeed.alpha = 0.2
//        UIView.animate(withDuration: 0.65, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
//            self.vpnSpeed.alpha = 1.0
//        })
//        firstly {
//            SpeedTest().testDownloadSpeedWithTimeout(timeout: 10.0)
//        }
//        .done { (mbps: Double) in
//            DispatchQueue.main.async {
//                self.vpnSpeed.layer.removeAllAnimations()
//                self.vpnSpeed.text = String(format: "%.1f", mbps)
//                    + " Mbps"
//                UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut], animations: {
//                    self.vpnSpeed.alpha = 1.0
//                })
//            }
//        }
//        .catch { error in
//            self.vpnSpeed.text = "error"
//            DDLogError("Error testing speed: \(error)")
//        }
//    }
    
}

class LockdownCustomActivityItemProvider : UIActivityItemProvider {

    let shareText: String
    
    init(text: String) {
        self.shareText = text
        super.init(placeholderItem: text)
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if let type = activityType {
            switch type {
                case UIActivity.ActivityType.postToTwitter:
                    return shareText + " @lockdown_hq"
                default:
                    return shareText
            }
        }
        else {
            return shareText
        }
    }

}
