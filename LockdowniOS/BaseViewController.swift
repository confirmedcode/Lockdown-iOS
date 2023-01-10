//
//  BaseViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import MessageUI
import CocoaLumberjackSwift
import PopupDialog

open class BaseViewController: UIViewController, MFMailComposeViewControllerDelegate {

    let interactionBlockViewTag = 84814
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // disable swipe down to dismiss
        isModalInPresentation = true
    }
    
    // MARK: - AwesomeSpotlight Helper
    
    func getRectForView(_ v: UIView) -> CGRect {
        if let sv = v.superview {
            return sv.convert(v.frame, to: self.view)
        }
        return CGRect.zero
    }
    
    // MARK: - Handle NSURLError and APIErrors
    
    func popupErrorAsNSURLError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            let message = """
Please check your internet connection. If this persists, please contact team@lockdownprivacy.com.

Error Description\n
"""
            let title: String = .localized("Network Error")
            self.showPopupDialog(title: title, message: .localized(message) + nsError.localizedDescription, acceptButton: .localizedOkay)
            return true
        } else {
            return false
        }
    }
    
    func popupErrorAsApiError(_ error: Error) -> Bool {
        if let e = error as? ApiError {
            let title = .localized("Error Code ") + "\(e.code)"
            let message = "\(e.message)" + .localized("\n\n If this persists, please contact team@lockdownprivacy.com.")
            self.showPopupDialog(title: title, message: message, acceptButton: .localizedOkay)
            return true
        } else {
            return false
        }
    }
    
    func showWhyTrustPopup() {
        let message = """
Lockdown is open source and fully transparent, which means anyone can see exactly what it's doing. \
Also, Lockdown Firewall has a simple, strict Privacy Policy, while Lockdown VPN is fully audited by security experts.
"""
        let popup = PopupDialog(
            title: .localized("Why Trust Lockdown?"),
            message: .localized(message),
            image: UIImage(named: "whyTrustImage")!,
            buttonAlignment: .vertical,
            transitionStyle: .bounceDown,
            preferredWidth: 300.0,
            tapGestureDismissal: true,
            panGestureDismissal: false,
            hideStatusBar: true,
            completion: nil)
        (popup.view as? PopupDialogContainerView)?.cornerRadius = 16
        (popup.view as? PopupDialogContainerView)?.layer.cornerCurve = .continuous
        
        let privacyPolicyButton = DefaultButton(title: .localized("Privacy Policy"), dismissOnTap: true) {
            self.showPrivacyPolicyModal()
        }
        
        let auditReportsButton = DefaultButton(title: .localized("Audit Reports"), dismissOnTap: true) {
            self.showAuditModal()
        }
        
        let pressButton = DefaultButton(title: .localized("Press & Media"), dismissOnTap: true) {
            self.showWebsitePressModal()
        }
        
        let okayButton = CancelButton(title: .localized("Done"), dismissOnTap: true) {  }
        popup.addButtons([privacyPolicyButton, auditReportsButton, pressButton, okayButton])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    func showVPNDetails() {
        self.showModalWebView(title: .localized("Secure Tunnel VPN"), urlString: "https://lockdownprivacy.com/secure-tunnel")
//        let popup = PopupDialog(
//            title: NSLocalizedString("About Lockdown VPN", comment: ""),
//            message: NSLocalizedString("Lockdown VPN is powered by Confirmed VPN, the open source, no-logs, and fully audited VPN.", comment: ""),
//            buttonAlignment: .vertical,
//            transitionStyle: .bounceDown,
//            preferredWidth: 300.0,
//            tapGestureDismissal: true,
//            panGestureDismissal: false,
//            hideStatusBar: true,
//            completion: nil)
//
//        let whyUseVPNButton = DefaultButton(title: NSLocalizedString("Why Use VPN?", comment: ""), dismissOnTap: true) {
//            self.showModalWebView(title: NSLocalizedString("Why Use VPN?", comment: ""), urlString: "https://confirmedvpn.com/why-vpn")
//        }
//
//        let auditReportsButton = DefaultButton(title: NSLocalizedString("Audit Reports", comment: ""), dismissOnTap: true) {
//            self.showAuditModal()
//        }
//
//        let confirmedWebsiteButton = DefaultButton(title: NSLocalizedString("Confirmed Site", comment: ""), dismissOnTap: true) {
//            self.showModalWebView(title: NSLocalizedString("Why Use VPN?", comment: ""), urlString: "https://confirmedvpn.com")
//        }
        
//        let okayButton = CancelButton(title: NSLocalizedString("Done", comment: ""), dismissOnTap: true) {  }
//        popup.addButtons([whyUseVPNButton, auditReportsButton, confirmedWebsiteButton, okayButton])
//
//        self.present(popup, animated: true, completion: nil)
    }
    
    // MARK: - WebView
    
    func showPrivacyPolicyModal() {
        self.showModalWebView(title: .localized("Privacy Policy"), urlString: "https://lockdownprivacy.com/privacy")
    }
    
    func showTermsModal() {
        self.showModalWebView(title: .localized("Terms"), urlString: "https://lockdownprivacy.com/terms")
    }
    
    func showFAQsModal() {
        self.showModalWebView(title: .localized("FAQs"), urlString: "https://lockdownprivacy.com/faq")
    }
    
    func showWebsiteModal() {
        self.showModalWebView(title: .localized("Website"), urlString: "https://lockdownprivacy.com")
    }
    
    func showWebsitePressModal() {
        self.showModalWebView(title: .localized("Press & Media"), urlString: "https://lockdownprivacy.com/#press")
    }
    
    func showAuditModal() {
        self.showModalWebView(title: .localized("Audit Reports"), urlString: "https://openaudit.com/lockdownprivacy")
    }
    
    func showModalWebView(title: String, urlString: String, delegate: WebViewViewControllerDelegate? = nil) {
        if let url = URL(string: urlString) {
            let storyboardToUse = storyboard != nil ? storyboard! : UIStoryboard(name: "Main", bundle: nil)
            if let webViewVC = storyboardToUse.instantiateViewController(withIdentifier: "webview") as? WebViewViewController {
                webViewVC.titleLabelText = title
                webViewVC.url = url
                webViewVC.delegate = delegate
                self.present(webViewVC, animated: true, completion: nil)
            } else {
                DDLogError("Unable to instantiate webview VC")
            }
        } else {
            DDLogError("Invalid URL \(urlString)")
        }
    }
    
    // MARK: - Block user interactions during transactions
    
    func unblockUserInteraction() {
        let view = self.view.viewWithTag(interactionBlockViewTag)
        if view != nil {
            view?.removeFromSuperview()
        }
    }
    
    func blockUserInteraction() {
        let view = UIView(frame: self.view.frame)
        view.tag = interactionBlockViewTag
        view.backgroundColor = UIColor.init(white: 1.0, alpha: 0.0)
        self.view.addSubview(view)
    }

    // MARK: - Popup Helper
    
    func showPopupDialog(title: String,
                         message: String,
                         transitionStyle: PopupDialogTransitionStyle = .bounceDown,
                         acceptButton: String,
                         tapGestureDismissal: Bool = true,
                         panGestureDismissal: Bool = true,
                         completionHandler: @escaping () -> Void = {}) {
        let popup = PopupDialog(
            title: title.uppercased(),
            message: message, image: nil,
            transitionStyle: transitionStyle,
            tapGestureDismissal: tapGestureDismissal,
            panGestureDismissal: panGestureDismissal,
            hideStatusBar: false)
        (popup.view as? PopupDialogContainerView)?.cornerRadius = 16
        (popup.view as? PopupDialogContainerView)?.layer.cornerCurve = .continuous
        
        let acceptButton = DefaultButton(title: .localizedOK, dismissOnTap: true) { completionHandler() }
        popup.addButtons([acceptButton])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    enum PopupButton {
        case custom(PopupDialogButton)
        case defaultAccept(completion: () -> Void)
        
        static func custom(title: String, titleColor: UIColor? = nil, completion: @escaping () -> Void) -> PopupButton {
            let button = DefaultButton(title: title, dismissOnTap: true, action: completion)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.lineBreakMode = .byClipping
            button.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
            
            if let color = titleColor {
                button.titleColor = color
            }
            return .custom(button)
        }
        
        static func destructive(title: String, completion: @escaping () -> Void) -> PopupButton {
            return .custom(title: title, titleColor: UIColor.systemRed, completion: completion)
        }
        
        static func cancel(completion: @escaping () -> Void = { }) -> PopupButton {
            return .custom(CancelButton(title: .localizedCancel, dismissOnTap: true, action: completion))
        }
        
        static func preferredCancel(completion: @escaping () -> Void = { }) -> PopupButton {
            return .custom(title: .localizedCancel, titleColor: nil, completion: completion)
        }
        
        fileprivate func makeButton() -> PopupDialogButton {
            switch self {
            case .custom(let button):
                return button
            case .defaultAccept(completion: let completion):
                let acceptButton = DefaultButton(title: .localizedOK, dismissOnTap: true) { completion() }
                return acceptButton
            }
        }
    }
    
    func showPopupDialog(
        title: String?,
        message: String?,
        buttonAlignment: NSLayoutConstraint.Axis = .vertical,
        hideStatusBar: Bool = false,
        buttons: [PopupButton]) {
        let popup = PopupDialog(
            title: title?.uppercased(),
            message: message,
            image: nil,
            buttonAlignment: buttonAlignment,
            transitionStyle: .bounceDown,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: hideStatusBar)
            
        (popup.view as? PopupDialogContainerView)?.cornerRadius = 16
        (popup.view as? PopupDialogContainerView)?.layer.cornerCurve = .continuous

        for action in buttons {
            let button = action.makeButton()
            popup.addButton(button)
        }
        
        self.present(popup, animated: true, completion: nil)
    }
    
    func showFixFirewallConnectionDialog(completion: @escaping () -> Void) {
        VPNController.shared.isConfigurationExisting { (exists) in
            if exists {
                // if VPN configuration exists, the system will not show an alert,
                // so we do need to warn users about it
                completion()
            } else {
                // if there is no existing VPN configuration,
                // we need to show a dialog explaining the
                // upcoming popup
                let message = """
Due to a recent iOS or Lockdown update, the Firewall needs to be refreshed to run properly.\n\nIf asked, \
tap \"Allow\" on the next dialog to automatically complete this process.
"""
                self.showPopupDialog(
                    title: "Tap \"Allow\" on the Next Popup",
                    message: message,
                    buttons: [
                        .cancel(),
                        .defaultAccept(completion: {
                            completion()
                        })
                    ]
                )
            }
        }
    }
    
    // MARK: - Email Team
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { [weak self] in
            self?.actionUponEmailComposeClosure()
        }
    }
    
    func actionUponEmailComposeClosure() {}
}

extension UIStoryboard {
    static let main = UIStoryboard(name: "Main", bundle: nil)
}
