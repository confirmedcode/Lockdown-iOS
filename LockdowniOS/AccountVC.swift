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
            tableView.showsVerticalScrollIndicator = false
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
    
    @objc private func accountStateDidChange() {
        DispatchQueue.main.async {
            self.reloadTable()
        }
    }
    
    func reloadTable() {
        tableView.clear()
        createTable()
        tableView.reloadData()
    }
    
    func createTable() {
        // Remove top separator
        tableView.tableHeaderView = UIView()
        
        var title: String = .localized("⚠️ Not Signed In")
        var message: String? = .localized("Sign up below to unlock benefits of a Lockdown account.")
        var firstButton = MakeDefaultCell(title: .localized("Sign Up  |  Sign In")) {
            // AccountViewController will update itself by observing
            // AccountUI.accountStateDidChange notification
            let signUpViewController = SignUpViewController(mode: .signUp)
            let idiom = UIScreen.main.traitCollection.userInterfaceIdiom
            signUpViewController.modalPresentationStyle = idiom == .pad ? .pageSheet : .fullScreen
            self.present(signUpViewController, animated: true)
        }
        firstButton.backgroundView = UIView()
        firstButton.backgroundView?.backgroundColor = .tunnelsBlue
        firstButton.label.textColor = UIColor.white
        
        if let apiCredentials = getAPICredentials() {
            message = apiCredentials.email
            if getAPICredentialsConfirmed() == true {
                title = .localized("Signed In")
                firstButton = MakeDefaultCell(title: .localizedSignOut) {
                    let confirm = PopupDialog(title: .localized("Sign Out?"),
                                              message: .localized("You'll be signed out from this account."),
                                              image: nil,
                                              buttonAlignment: .horizontal,
                                              transitionStyle: .bounceDown,
                                              preferredWidth: 270,
                                              tapGestureDismissal: true,
                                              panGestureDismissal: false,
                                              hideStatusBar: false,
                                              completion: nil)
                    confirm.addButtons([
                       DefaultButton(title: .localizedCancel, dismissOnTap: true) {},
                       DefaultButton(title: .localizedSignOut, dismissOnTap: true) { [weak self] in
                           guard let self = self else { return }
                           URLCache.shared.removeAllCachedResponses()
                           Client.clearCookies()
                           clearAPICredentials()
                           setAPICredentialsConfirmed(confirmed: false)
                           self.reloadTable()
                           self.showPopupDialog(
                            title: .localized("Success"),
                            message: .localized("Signed out successfully."),
                            acceptButton: .localizedOkay)
                       },
                    ])
                    self.present(confirm, animated: true, completion: nil)
                }
                firstButton.backgroundView?.backgroundColor = UIColor.clear
                firstButton.label.textColor = UIColor.systemRed
            } else {
                title = "⚠️ Email Not Confirmed"
                firstButton = MakeDefaultCell(title: .localized("Confirm Email")) {
                    self.showLoadingView()
                    
                    firstly {
                        try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                    }
                    .done { _ in
                        self.hideLoadingView()
                        // successfully signed in with no errors, show confirmation success
                        setAPICredentialsConfirmed(confirmed: true)
                        
                        // logged in and confirmed - update this email with the receipt and refresh VPN credentials
                        firstly { () -> Promise<SubscriptionEvent> in
                            try Client.subscriptionEvent()
                        }
                        .then { _ -> Promise<GetKey> in
                            try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
                            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                            if getUserWantsVPNEnabled() {
                                VPNController.shared.restart()
                            }
                        }
                        .catch { error in
                            // it's okay for this to error out with "no subscription in receipt"
                            DDLogError("""
HomeViewController ConfirmEmail subscriptionevent error \
(ok for it to be \"no subscription in receipt\"): \(error)
""")
                        }
                        
                        let message = """
Your account has been confirmed and you're now signed in. You'll get the latest \
block lists, access to Lockdown Mac, and get critical announcements.
"""
                        let popup = PopupDialog(title: .localized("Success! 🎉"),
                                                message: .localized(message),
                                                image: nil,
                                                buttonAlignment: .horizontal,
                                                transitionStyle: .bounceDown,
                                                preferredWidth: 270,
                                                tapGestureDismissal: true,
                                                panGestureDismissal: false,
                                                hideStatusBar: false,
                                                completion: nil)
                        popup.addButtons([
                            DefaultButton(title: .localizedOkay, dismissOnTap: true) {
                                self.reloadTable()
                            }
                        ])
                        self.present(popup, animated: true, completion: nil)
                    }
                    .catch { error in
                        self.hideLoadingView()
                        let clickConfirmation: String = .localized(
                            "To complete your signup, click the confirmation link we sent to",
                            comment: "Used in To complete your signup, click the confirmation link we sent to you@gmail.com")
                        let checkSpam: String = .localized("""
Be sure to check your spam folder in case it got stuck there.

You can also request a re-send of the confirmation.
""")
                        let popup = PopupDialog(title: .localized("Check Your Inbox"),
                                                message: "\(clickConfirmation) \(apiCredentials.email). \(checkSpam)",
                                                image: nil,
                                                buttonAlignment: .vertical,
                                                transitionStyle: .bounceDown,
                                                preferredWidth: 270,
                                                tapGestureDismissal: true,
                                                panGestureDismissal: false,
                                                hideStatusBar: false,
                                                completion: nil)
                        popup.addButtons([
                            DefaultButton(title: .localizedOkay, dismissOnTap: true) {},
                            DefaultButton(title: .localizedSignOut, dismissOnTap: true) {
                                URLCache.shared.removeAllCachedResponses()
                                Client.clearCookies()
                                clearAPICredentials()
                                setAPICredentialsConfirmed(confirmed: false)
                                self.reloadTable()
                                self.showPopupDialog(
                                    title: .localized("Success"),
                                    message: .localized("Signed out successfully."),
                                    acceptButton: .localizedOkay)
                            },
                            DefaultButton(title: .localized("Re-send"), dismissOnTap: true) {
                                firstly {
                                    try Client.resendConfirmCode(email: apiCredentials.email)
                                }
                                .done { (success: Bool) in
                                    var message: String = .localized("Successfully re-sent your email confirmation to ") + apiCredentials.email
                                    if !success {
                                        message = .localized("Failed to re-send email confirmation.")
                                    }
                                    self.showPopupDialog(title: "", message: message, acceptButton: .localizedOkay)
                                }
                                .catch { error in
                                    if self.popupErrorAsNSURLError(error) {
                                        return
                                    } else if let apiError = error as? ApiError {
                                        _ = self.popupErrorAsApiError(apiError)
                                    } else {
                                        self.showPopupDialog(title: .localized("Error Re-sending Email Confirmation"),
                                                             message: "\(error)",
                                                             acceptButton: .localizedOkay)
                                    }
                                }
                            },
                        ])
                        self.present(popup, animated: true, completion: nil)
                    }

                }
            }
        }
        
        let upgradeButton = MakeDefaultButtonCell(title: .localized("View or Upgrade Plan")) {
            BasePaywallService.shared.showPaywall(on: self)
        }
        upgradeButton.button.isEnabled = true
        upgradeButton.selectionStyle = .default
        upgradeButton.backgroundView?.backgroundColor = UIColor.tunnelsDarkBlue
        upgradeButton.button.setTitleColor(UIColor.white, for: UIControl.State())
        
        if let currentSubscription = BaseUserService.shared.user.currentSubscription,
            [.proAnnual, .proAnnualLTO].contains(currentSubscription.planType) {
            upgradeButton.button.isEnabled = false
            upgradeButton.selectionStyle = .none
            upgradeButton.button.setTitle(.localized("Plan: Annual Pro"), for: UIControl.State())
        }
        
        let notificationsButton = MakeDefaultCell(title: "", action: { })
        
        let updateNotificationButtonTitle = { (cell: DefaultCell) in
            if PushNotifications.Authorization.getUserWantsNotificationsEnabled(forCategory: .weeklyUpdate) {
                cell.label.text = .localized("Notifications: On")
            } else {
                cell.label.text = .localized("Notifications: Off")
            }
        }
        
        updateNotificationButtonTitle(notificationsButton)
                        
        notificationsButton.onSelect { [unowned notificationsButton, unowned self] in
            if PushNotifications.Authorization.getUserWantsNotificationsEnabled(forCategory: .weeklyUpdate) {
                PushNotifications.Authorization.setUserWantsNotificationsEnabled(false, forCategory: .weeklyUpdate)
                updateNotificationButtonTitle(notificationsButton)
            } else {
                UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                    DispatchQueue.main.async {
                        switch settings.authorizationStatus {
                        case .denied, .notDetermined:
                            let enableNotificationsViewController = EnableNotificationsViewController {
                                updateNotificationButtonTitle(notificationsButton)
                            }
                            
                            enableNotificationsViewController.modalPresentationStyle = .fullScreen
                            self.present(enableNotificationsViewController, animated: true)
                        case .authorized:
                            PushNotifications.Authorization.setUserWantsNotificationsEnabled(true, forCategory: .weeklyUpdate)
                            updateNotificationButtonTitle(notificationsButton)
                        default:
                            break
                        }
                    }
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
            titleLabel.font = .boldLockdownFont(size: 18)
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            stack.addArrangedSubview(titleLabel)
            
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.font = .mediumLockdownFont(size: 18)
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
            MakeDefaultCell(title: .localized("Tutorial")) { [unowned self] in
                self.startTutorial()
            },
            MakeDefaultCell(title: .localized("Why Trust Lockdown")) {
                self.showWhyTrustPopup()
            },
            MakeDefaultCell(title: .localized("Privacy Policy")) {
                self.showPrivacyPolicyModal()
            },
            MakeDefaultCell(title: .localized("What is VPN?")) {
                self.performSegue(withIdentifier: "showWhatIsVPN", sender: self)
            },
            MakeDefaultCell(title: .localized("Support | Feedback")) {
                let message = """
Remember to check our FAQs first, for answers to the most frequently asked questions.

If it's not answered there, we're happy to provide support and take feedback by email.
"""
                self.showPopupDialog(
                    title: nil,
                    message: .localized(message),
                    buttons: [
                        .custom(title: .localized("View FAQs"), completion: {
                            self.showFAQsModal()
                        }),
                        .custom(title: .localized("Email Us"), completion: {
                            self.composeEmail(.helpOrFeedback, attachments: [.diagnostics])
                        }),
                        .cancel()
                    ]
                )
            },
            MakeDefaultCell(title: .localized("FAQs")) {
                self.showFAQsModal()
            },
            MakeDefaultCell(title: .localized("Website")) {
                self.showWebsiteModal()
            },
        ]
        
        for cell in otherCells {
            tableView.addCell(cell)
        }
        
        if let creds = getAPICredentials() {
            tableView.addCell(MakeDefaultCell(title: .localized("delete_account"), color: .tunnelsWarning) {
                self.deleteAccount(userEmail: creds.email)
            })
        }
        
        #if DEBUG
        let fixVPNConfig = MakeDefaultCell(title: "_Fix Firewall Config", action: {
            self.showFixFirewallConnectionDialog {
                FirewallController.shared.deleteConfigurationAndAddAgain()
            }
        })
        tableView.addCell(fixVPNConfig)
        #endif
        
        tableView.addRowCell { (cell) in
            cell.textLabel?.text = Bundle.main.versionString
            cell.textLabel?.font = .semiboldLockdownFont(size: 17)
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
            tabBarController.homeViewController?.startTutorial()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showWhatIsVPN":
            if let vc = segue.destination as? WhatIsVpnViewController {
                vc.parentVC = (tabBarController as? MainTabBarController)?.homeViewController
            }
        case "showUpgradePlanAccount":
            if let vc = segue.destination as? OldSignupViewController {
                vc.parentVC = self
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
}

extension AccountViewController: EmailComposable {
    private func deleteAccount(userEmail: String) {
        let deleteAccountViewController = DeleteMyAccountViewController(userEmail: userEmail)
        deleteAccountViewController.modalPresentationStyle = .formSheet
        present(deleteAccountViewController, animated: true)
    }
}

// MARK: - Helpers / Extensions

class DefaultButtonCell: SelectableTableViewCell {
    let button = UIButton(type: .system)
}

func MakeDefaultButtonCell(title: String, action: @escaping () -> Void) -> DefaultButtonCell {
    let cell = DefaultButtonCell()
    cell.backgroundView = UIView()
    cell.button.setTitle(title, for: .normal)
    cell.button.isUserInteractionEnabled = false
    cell.button.titleLabel?.font = .semiboldLockdownFont(size: 17)
    cell.button.titleLabel?.adjustsFontSizeToFitWidth = true
    cell.button.titleLabel?.lineBreakMode = .byClipping
    cell.button.tintColor = .tunnelsBlue
    cell.contentView.addSubview(cell.button)
    cell.button.anchors.height.equal(21)
    cell.button.anchors.edges.marginsPin(insets: .init(top: 8, left: 0, bottom: 8, right: 0))
    return cell.onSelect(callback: action)
}

class DefaultCell: SelectableTableViewCell {
    let label = UILabel()
}

func MakeDefaultCell(title: String, color: UIColor = .tunnelsBlue, action: @escaping () -> Void) -> DefaultCell {
    let cell = DefaultCell()
    cell.label.text = title
    cell.label.font = .semiboldLockdownFont(size: 17)
    cell.label.textColor = color
    cell.label.textAlignment = .center
    cell.contentView.addSubview(cell.label)
    cell.label.anchors.edges.marginsPin(insets: .init(top: 8, left: 0, bottom: 8, right: 0))
    return cell.onSelect(callback: action)
}

fileprivate extension DefaultButtonCell {
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
