//
//  AccountVC.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 02.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import UIKit
import PopupDialog
import PromiseKit
import CocoaLumberjackSwift

final class AccountViewController: BaseViewController, Loadable {
    
    let tableView = StaticTableView(frame: .zero, style: .plain)
    var activePlans: [Subscription.PlanType] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            view.addSubview(tableView)
            tableView.anchors.edges.pin()
            tableView.separatorStyle = .singleLine
            tableView.cellLayoutMarginsFollowReadableWidth = true
            tableView.deselectsCellsAutomatically = true
            tableView.contentInset.top += 12
            tableView.tableFooterView = UIView()
            
            tableView.clear()
            createTable()
        }
        
        do {
            NotificationCenter.default.addObserver(self, selector: #selector(accountStateDidChange), name: AccountUI.accountStateDidChange, object: nil)
        }
    }
    
    @objc
    func accountStateDidChange() {
        assert(Thread.isMainThread)
        self.reloadTable()
    }
    
    func reloadTable() {
        tableView.clear()
        createTable()
        tableView.reloadData()
    }
    
    func createTable() {
        var title = "⚠️ Not Signed In"
        var message: String? = "Sign up below to unlock benefits of a Lockdown account."
        var firstButton = DefaultCell(title: NSLocalizedString("Sign Up  |  Sign In", comment: "")) {
            // AccountViewController will update itself by observing
            // AccountUI.accountStateDidChange notification
            AccountUI.presentCreateAccount(on: self)
        }
        firstButton.backgroundView = UIView()
        firstButton.backgroundView?.backgroundColor = UIColor.tunnelsBlue
        firstButton.label.textColor = UIColor.white
        
        if let apiCredentials = getAPICredentials() {
            message = apiCredentials.email
            if getAPICredentialsConfirmed() == true {
                title = "Signed In"
                firstButton = DefaultCell(title: NSLocalizedString("Sign Out", comment: "")) {
                    let confirm = PopupDialog(title: "Sign Out?",
                                               message: "You'll be signed out from this account.",
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
                       DefaultButton(title: NSLocalizedString("Sign Out", comment: ""), dismissOnTap: true) { [unowned self] in
                        URLCache.shared.removeAllCachedResponses()
                        Client.clearCookies()
                        clearAPICredentials()
                        setAPICredentialsConfirmed(confirmed: false)
                        self.reloadTable()
//                        self.reloadMenuDot()
                        self.showPopupDialog(title: "Success", message: "Signed out successfully.", acceptButton: NSLocalizedString("Okay", comment: ""))
                       },
                    ])
                    self.present(confirm, animated: true, completion: nil)
                }
                firstButton.backgroundView?.backgroundColor = UIColor.clear
                firstButton.label.textColor = UIColor.systemRed
            }
            else {
                title = "⚠️ Email Not Confirmed"
                firstButton = DefaultCell(title: NSLocalizedString("Confirm Email", comment: "")) {
                    self.showLoadingView()
                    
                    firstly {
                        try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                    }
                    .done { (signin: SignIn) in
                        self.hideLoadingView()
                        // successfully signed in with no errors, show confirmation success
                        setAPICredentialsConfirmed(confirmed: true)
                        
                        // logged in and confirmed - update this email with the receipt and refresh VPN credentials
                        firstly { () -> Promise<SubscriptionEvent> in
                            try Client.subscriptionEvent()
                        }
                        .then { (result: SubscriptionEvent) -> Promise<GetKey> in
                            try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
                            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                            if (getUserWantsVPNEnabled() == true) {
                                VPNController.shared.restart()
                            }
                        }
                        .catch { error in
                            // it's okay for this to error out with "no subscription in receipt"
                            DDLogError("HomeViewController ConfirmEmail subscriptionevent error (ok for it to be \"no subscription in receipt\"): \(error)")
                        }
                        
                        let popup = PopupDialog(title: "Success! 🎉",
                                                message: NSLocalizedString("Your account has been confirmed and you're now signed in. You'll get the latest block lists, access to Lockdown Mac, and get critical announcements.", comment: ""),
                                                image: nil,
                                                buttonAlignment: .horizontal,
                                                transitionStyle: .bounceDown,
                                                preferredWidth: 270,
                                                tapGestureDismissal: true,
                                                panGestureDismissal: false,
                                                hideStatusBar: false,
                                                completion: nil)
                        popup.addButtons([
                           DefaultButton(title: NSLocalizedString("Okay", comment: ""), dismissOnTap: true) {
                            self.reloadTable()
                            }
                        ])
                        self.present(popup, animated: true, completion: nil)
                    }
                    .catch { error in
                        self.hideLoadingView()
                        let popup = PopupDialog(title: "Check Your Inbox",
                                                message: "To complete your signup, click the confirmation link we sent to \(apiCredentials.email). Be sure to check your spam folder in case it got stuck there.\n\nYou can also request a re-send of the confirmation.",
                                                image: nil,
                                                buttonAlignment: .vertical,
                                                transitionStyle: .bounceDown,
                                                preferredWidth: 270,
                                                tapGestureDismissal: true,
                                                panGestureDismissal: false,
                                                hideStatusBar: false,
                                                completion: nil)
                        popup.addButtons([
                            DefaultButton(title: NSLocalizedString("Okay", comment: ""), dismissOnTap: true) {},
                            DefaultButton(title: NSLocalizedString("Sign Out", comment: ""), dismissOnTap: true) {
                                URLCache.shared.removeAllCachedResponses()
                                Client.clearCookies()
                                clearAPICredentials()
                                setAPICredentialsConfirmed(confirmed: false)
                                self.reloadTable()
                                self.showPopupDialog(title: "Success", message: "Signed out successfully.", acceptButton: NSLocalizedString("Okay", comment: ""))
                            },
                            DefaultButton(title: NSLocalizedString("Re-send", comment: ""), dismissOnTap: true) {
                                firstly {
                                    try Client.resendConfirmCode(email: apiCredentials.email)
                                }
                                .done { (success: Bool) in
                                    var message = "Successfully re-sent your email confirmation to \(apiCredentials.email)"
                                    if (success == false) {
                                        message = "Failed to re-send email confirmation."
                                    }
                                    self.showPopupDialog(title: "", message: message, acceptButton: NSLocalizedString("Okay", comment: ""))
                                }
                                .catch { error in
                                    if (self.popupErrorAsNSURLError(error)) {
                                        return
                                    }
                                    else if let apiError = error as? ApiError {
                                        _ = self.popupErrorAsApiError(apiError)
                                    }
                                    else {
                                        self.showPopupDialog(title: NSLocalizedString("Error Re-sending Email Confirmation", comment: ""),
                                                             message: "\(error)",
                                            acceptButton: NSLocalizedString("Okay", comment: ""))
                                    }
                                }
                            },
                        ])
                        self.present(popup, animated: true, completion: nil)
                    }

                }
            }
        }
        
        let upgradeButton = DefaultButtonCell(title: "Loading Plan") {
            self.performSegue(withIdentifier: "showUpgradePlanAccount", sender: self)
        }
        upgradeButton.startActivityIndicator()
        upgradeButton.button.isEnabled = false
        upgradeButton.selectionStyle = .none
        
        self.activePlans = []

        firstly {
            try Client.signIn()
        }.then { _ in
            try Client.activeSubscriptions()
        }.ensure {
            upgradeButton.stopActivityIndicator()
        }.done { subscriptions in
            self.activePlans = subscriptions.map({ $0.planType })
            if let active = subscriptions.first {
                if active.planType == .proAnnual {
                    upgradeButton.button.isEnabled = false
                    upgradeButton.selectionStyle = .none
                    upgradeButton.button.setTitle("Plan: Annual Pro", for: UIControl.State())
                } else {
                    upgradeButton.button.isEnabled = true
                    upgradeButton.selectionStyle = .default
                    upgradeButton.backgroundView?.backgroundColor = UIColor.tunnelsDarkBlue
                    upgradeButton.button.setTitleColor(UIColor.white, for: UIControl.State())
                    upgradeButton.button.setTitle("View or Upgrade Plan", for: UIControl.State())
                }
            } else {
                upgradeButton.button.isEnabled = true
                upgradeButton.selectionStyle = .default
                upgradeButton.backgroundView?.backgroundColor = UIColor.tunnelsDarkBlue
                upgradeButton.button.setTitleColor(UIColor.white, for: UIControl.State())
                upgradeButton.button.setTitle("View Upgrade Options", for: UIControl.State())
            }
        }.catch { error in
            DDLogWarn(error.localizedDescription)
            if let apiError = error as? ApiError {
                switch apiError.code {
                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                    upgradeButton.button.isEnabled = true
                    upgradeButton.selectionStyle = .default
                    upgradeButton.backgroundView?.backgroundColor = UIColor.tunnelsDarkBlue
                    upgradeButton.button.setTitleColor(UIColor.white, for: UIControl.State())
                    upgradeButton.button.setTitle("View Upgrade Options", for: UIControl.State())
                default:
                    upgradeButton.button.isEnabled = true
                    upgradeButton.selectionStyle = .default
                    upgradeButton.button.setTitleColor(UIColor.systemRed, for: UIControl.State())
                    upgradeButton.button.setTitle("Error Loading Plan: Retry", for: UIControl.State())
                    upgradeButton.onSelect {
                        self.reloadTable()
                    }
                }
            } else {
                upgradeButton.button.isEnabled = true
                upgradeButton.selectionStyle = .default
                upgradeButton.button.setTitleColor(UIColor.systemRed, for: UIControl.State())
                upgradeButton.button.setTitle("Error Loading Plan: Retry", for: UIControl.State())
                upgradeButton.onSelect {
                    self.reloadTable()
                }
            }
        }
        
        let notificationsButton = DefaultCell(title: "", action: { })
        
        let updateNotificationButtonTitle = { (cell: _DefaultCell) in
            if PushNotifications.Authorization.getUserWantsNotificationsEnabled(forCategory: .weeklyUpdate) {
                cell.label.text = "Notifications: On"
            } else {
                cell.label.text = "Notifications: Off"
            }
        }
        
        updateNotificationButtonTitle(notificationsButton)
                        
        notificationsButton.onSelect { [unowned notificationsButton, unowned self] in
            if PushNotifications.Authorization.getUserWantsNotificationsEnabled(forCategory: .weeklyUpdate) {
                PushNotifications.Authorization.setUserWantsNotificationsEnabled(false, forCategory: .weeklyUpdate)
                updateNotificationButtonTitle(notificationsButton)
            } else {
                PushNotifications.Authorization.requestWeeklyUpdateAuthorization(presentingDialogOn: self).done { status in
                    DDLogInfo("New authorization status for push notifications: \(status)")
                    updateNotificationButtonTitle(notificationsButton)
                }.catch { error in
                    DDLogError("Error updating notification authorization status: \(error.localizedDescription)")
                }
            }
        }
        
        tableView.addRow { (contentView) in
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 8
            contentView.addSubview(stack)
            stack.anchors.edges.marginsPin(insets: .init(top: 8, left: 0, bottom: 8, right: 0))
            
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = fontBold18
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            stack.addArrangedSubview(titleLabel)
            
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.font = fontMedium18
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            stack.addArrangedSubview(messageLabel)
        }
        
        let firstButtons: [SelectableTableViewCell] = [
            firstButton,
            upgradeButton,
            notificationsButton,
        ]
        
        for cell in firstButtons {
            tableView.addCell(cell)
        }
        
        let otherCells = [
            DefaultCell(title: NSLocalizedString("Tutorial", comment: "")) { [unowned self] in
                self.startTutorial()
            },
            DefaultCell(title: NSLocalizedString("Why Trust Lockdown", comment: "")) {
                self.showWhyTrustPopup()
            },
            DefaultCell(title: NSLocalizedString("Privacy Policy", comment: "")) {
                self.showPrivacyPolicyModal()
            },
            DefaultCell(title: NSLocalizedString("What is VPN?", comment: "")) {
                self.performSegue(withIdentifier: "showWhatIsVPN", sender: self)
            },
            DefaultCell(title: NSLocalizedString("Email Support", comment: "")) {
                self.showPopupDialog(
                    title: nil,
                    message: NSLocalizedString("We're happy to help answer questions or feedback you have through our email support, but the quickest way to get an answer is to check out our Frequently Asked Questions (FAQs). Do you want to continue to email support?", comment: ""),
                    buttons: [
                        .custom(title: NSLocalizedString("See FAQs", comment: ""), completion: {
                            self.showFAQsModal()
                        }),
                        .custom(title: NSLocalizedString("Email Support", comment: ""), completion: {
                            self.emailTeam()
                        }),
                        .cancel()
                    ]
                )
            },
            DefaultCell(title: NSLocalizedString("FAQs", comment: "")) {
                self.showFAQsModal()
            },
            DefaultCell(title: NSLocalizedString("Website", comment: "")) {
                self.showWebsiteModal()
            },
        ]
        
        for cell in otherCells {
            tableView.addCell(cell)
        }
        
        #if DEBUG
        let fixVPNConfig = DefaultCell(title: "_Fix Firewall Config", action: {
            self.showFixFirewallConnectionDialog {
                FirewallController.shared.deleteConfigurationAndAddAgain()
            }
        })
        tableView.addCell(fixVPNConfig)
        #endif
        
        tableView.addRowCell { (cell) in
            cell.textLabel?.text = Bundle.main.versionString
            cell.textLabel?.font = fontSemiBold17
            cell.textLabel?.textColor = UIColor.systemGray
            cell.textLabel?.textAlignment = .right
            
            // removing the bottom separator
            cell.separatorInset = .init(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            cell.directionalLayoutMargins = .zero
        }
    }
    
    func startTutorial() {
        if let tabBarController = tabBarController as? MainTabBarController {
            tabBarController.selectedViewController = tabBarController.homeViewController
            tabBarController.homeViewController.startTutorial()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showWhatIsVPN":
            if let vc = segue.destination as? WhatIsVpnViewController {
                vc.parentVC = (tabBarController as? MainTabBarController)?.homeViewController
            }
        case "showUpgradePlanAccount":
            if let vc = segue.destination as? SignupViewController {
                vc.parentVC = self
                if activePlans.isEmpty {
                    vc.mode = .newSubscription
                    vc.enableVPNAfterSubscribe = true
                } else {
                    vc.mode = .upgrade(active: activePlans)
                    vc.enableVPNAfterSubscribe = true
                }
            }
        default:
            break
        }
    }
}

// MARK: - Helpers / Extensions

class _DefaultButtonCell: SelectableTableViewCell {
    let button = UIButton(type: .system)
}

func DefaultButtonCell(title: String, action: @escaping () -> ()) -> _DefaultButtonCell {
    let cell = _DefaultButtonCell()
    cell.backgroundView = UIView()
    cell.button.setTitle(title, for: .normal)
    cell.button.isUserInteractionEnabled = false
    cell.button.titleLabel?.font = fontSemiBold17
    cell.button.tintColor = .tunnelsBlue
    cell.contentView.addSubview(cell.button)
    cell.button.anchors.height.equal(21)
    cell.button.anchors.edges.marginsPin(insets: .init(top: 8, left: 0, bottom: 8, right: 0))
    return cell.onSelect(callback: action)
}

class _DefaultCell: SelectableTableViewCell {
    let label = UILabel()
}

func DefaultCell(title: String, action: @escaping () -> ()) -> _DefaultCell {
    let cell = _DefaultCell()
    cell.label.text = title
    cell.label.font = fontSemiBold17
    cell.label.textColor = .tunnelsBlue
    cell.label.textAlignment = .center
    cell.contentView.addSubview(cell.label)
    cell.label.anchors.edges.marginsPin(insets: .init(top: 8, left: 0, bottom: 8, right: 0))
    return cell.onSelect(callback: action)
}

fileprivate extension _DefaultButtonCell {
    func startActivityIndicator() {
        let activity = UIActivityIndicatorView()
        
        if let label = button.titleLabel {
            label.addSubview(activity)
            activity.translatesAutoresizingMaskIntoConstraints = false
            activity.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
            activity.leadingAnchor.constraint(equalToSystemSpacingAfter: label.trailingAnchor, multiplier: 1).isActive = true
            activity.startAnimating()
        }
    }
    
    func stopActivityIndicator() {
        if let label = button.titleLabel {
            let indicators = label.subviews.compactMap { $0 as? UIActivityIndicatorView }
            for indicator in indicators {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
}
