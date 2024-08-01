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
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
//        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(emailTeam))
//        longPressRecognizer.minimumPressDuration = 4
//        self.view.addGestureRecognizer(longPressRecognizer)
        
        //        let doubleLongPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(signoutUser))
        //        doubleLongPressRecognizer.minimumPressDuration = 5
        //        doubleLongPressRecognizer.numberOfTouchesRequired = 2
        //        self.view.addGestureRecognizer(doubleLongPressRecognizer)
    }
    
    // MARK: - AwesomeSpotlight Helper
    
    func getRectForView(_ v: UIView) -> CGRect {
        if let sv = v.superview {
            return sv.convert(v.frame, to: self.view)
        }
        return CGRect.zero;
    }
    
    // MARK: - Handle NSURLError and APIErrors
    
    func popupErrorAsNSURLError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            self.showPopupDialog(title: NSLocalizedString("Network Error", comment: ""), message: NSLocalizedString("Please check your internet connection. If this persists, please contact team@lockdownprivacy.com.\n\nError Description\n", comment: "") + nsError.localizedDescription, acceptButton: NSLocalizedString("Okay", comment: ""))
            return true
        }
        else {
            return false
        }
    }
    
    func popupErrorAsApiError(_ error: Error) -> Bool {
        if let e = error as? ApiError {
            self.showPopupDialog(title: NSLocalizedString("Error Code ", comment: "") + "\(e.code)", message: "\(e.message)" + NSLocalizedString("\n\n If this persists, please contact team@lockdownprivacy.com.", comment: ""), acceptButton: NSLocalizedString("Okay", comment: ""))
            return true
        }
        else {
            return false
        }
    }
    
    func showWhyTrustPopup() {
        let popup = PopupDialog(
            title: NSLocalizedString("Why Trust Lockdown?", comment: ""),
            message: NSLocalizedString("Lockdown is open source and fully transparent, which means anyone can see exactly what it's doing. Also, Lockdown Firewall has a simple, strict Privacy Policy, while Lockdown VPN is fully audited by security experts.", comment: ""),
            image: UIImage(named: "whyTrustImage")!,
            buttonAlignment: .vertical,
            transitionStyle: .bounceDown,
            preferredWidth: 300.0,
            tapGestureDismissal: true,
            panGestureDismissal: false,
            hideStatusBar: true,
            completion: nil)
        
        let privacyPolicyButton = DefaultButton(title: NSLocalizedString("Privacy Policy", comment: ""), dismissOnTap: true) {
            self.showPrivacyPolicyModal()
        }
        
        let auditReportsButton = DefaultButton(title: NSLocalizedString("Audit Reports", comment: ""), dismissOnTap: true) {
            self.showAuditModal()
        }
        
        let pressButton = DefaultButton(title: NSLocalizedString("Press & Media", comment: ""), dismissOnTap: true) {
            self.showWebsitePressModal()
        }
        
        let okayButton = CancelButton(title: NSLocalizedString("Done", comment: ""), dismissOnTap: true) {  }
        popup.addButtons([privacyPolicyButton, auditReportsButton, pressButton, okayButton])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    func showVPNDetails() {
        self.showModalWebView(title: NSLocalizedString("Secure Tunnel VPN", comment: ""), urlString: "https://lockdownprivacy.com/secure-tunnel")
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
    
    func showWhatsNewModal() {
        let vc = WhatsNewViewController()
        present(vc, animated: true)
    }
    
    func showPrivacyPolicyModal() {
        self.showModalWebView(title: NSLocalizedString("Privacy Policy", comment: ""), urlString: "https://lockdownprivacy.com/privacy")
    }
    
    func showTermsModal() {
        self.showModalWebView(title: NSLocalizedString("Terms", comment: ""), urlString: "https://lockdownprivacy.com/terms")
    }
    
    func showFAQsModal() {
        self.showModalWebView(title: NSLocalizedString("FAQs", comment: ""), urlString: "https://lockdownprivacy.com/faq")
    }
    
    func showWebsiteModal() {
        self.showModalWebView(title: NSLocalizedString("Website", comment: ""), urlString: "https://lockdownprivacy.com")
    }
    
    func showWebsitePressModal() {
        self.showModalWebView(title: NSLocalizedString("Press & Media", comment: ""), urlString: "https://lockdownprivacy.com/#press")
    }
    
    func showAuditModal() {
        self.showModalWebView(title: NSLocalizedString("Audit Reports", comment: ""), urlString: "https://openaudit.com/lockdownprivacy")
    }
    
    func showModalWebView(title: String, urlString: String) {
        if let url = URL(string: urlString) {
            let storyboardToUse = storyboard != nil ? storyboard! : UIStoryboard(name: "Main", bundle: nil)
            if let webViewVC = storyboardToUse.instantiateViewController(withIdentifier: "webview") as? WebViewViewController {
                webViewVC.titleLabelText = title
                webViewVC.url = url
                self.present(webViewVC, animated: true, completion: nil)
            }
            else {
                DDLogError("Unable to instantiate webview VC")
            }
        }
        else {
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
    
    func showPopupDialog(title: String, message: String, acceptButton: String, completionHandler: @escaping () -> () = {}) {
        let popup = PopupDialog(title: title.uppercased(), message: message, image: nil, transitionStyle: .bounceDown, hideStatusBar: false)
        
        let acceptButton = DefaultButton(title: NSLocalizedString("OK", comment: ""), dismissOnTap: true) { completionHandler() }
        popup.addButtons([acceptButton])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    enum PopupButton {
        case custom(PopupDialogButton)
        case defaultAccept(completion: () -> ())
        
        static func custom(title: String, titleColor: UIColor? = nil, completion: @escaping () -> ()) -> PopupButton {
            let button = DefaultButton(title: title, dismissOnTap: true, action: completion)
            if let color = titleColor {
                button.titleColor = color
            }
            return .custom(button)
        }
        
        static func destructive(title: String, completion: @escaping () -> ()) -> PopupButton {
            return .custom(title: title, titleColor: UIColor.systemRed, completion: completion)
        }
        
        static func cancel(completion: @escaping () -> () = { }) -> PopupButton {
            return .custom(CancelButton(title: NSLocalizedString("Cancel", comment: ""), dismissOnTap: true, action: completion))
        }
        
        static func preferredCancel(completion: @escaping () -> () = { }) -> PopupButton {
            return .custom(title: NSLocalizedString("Cancel", comment: ""), titleColor: nil, completion: completion)
        }
        
        fileprivate func makeButton() -> PopupDialogButton {
            switch self {
            case .custom(let button):
                return button
            case .defaultAccept(completion: let completion):
                let acceptButton = DefaultButton(title: NSLocalizedString("OK", comment: ""), dismissOnTap: true) { completion() }
                return acceptButton
            }
        }
    }
    
    func showPopupDialog(title: String?, message: String?, buttons: [PopupButton]) {
        let popup = PopupDialog(title: title?.uppercased(), message: message, image: nil, transitionStyle: .bounceDown, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: false)

        for action in buttons {
            let button = action.makeButton()
            popup.addButton(button)
        }
        
        self.present(popup, animated: true, completion: nil)
    }
    
    func showFixFirewallConnectionDialog(completion: @escaping () -> ()) {
        VPNController.shared.isConfigurationExisting { (exists) in
            if exists {
                // if VPN configuration exists, the system will not show an alert,
                // so we do need to warn users about it
                completion()
            } else {
                // if there is no existing VPN configuration,
                // we need to show a dialog explaining the
                // upcoming popup
                self.showPopupDialog(
                    title: "Tap \"Allow\" on the Next Popup",
                    message: "Due to a recent iOS or Lockdown update, the Firewall needs to be refreshed to run properly.\n\nIf asked, tap \"Allow\" on the next dialog to automatically complete this process.",
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
    
//    func showPopupDialogSubmitError(title : String = "Sorry, An Error Occurred", message : String, error: Error?) {
//        let popup = PopupDialog(title: title, message: message, image: nil, transitionStyle: .zoomIn, hideStatusBar: false)
//        let acceptButton = DefaultButton(title: "Don't Submit", dismissOnTap: true) { }
//        let submitButton = DefaultButton(title: "Submit", dismissOnTap: true) {
//            self.emailTeam(messageBody: "Hey Lockdown Team, \nI encountered a bug while using Lockdown, and I'm reporting it here. \n (To the user: just tap Send at the top right to submit the bug report -- no need to do anything else and we'll get back to you ASAP.", messageErrorBody: error ? error! || "")
//        }
//        popup.addButtons([acceptButton, submitButton])
//        self.present(popup, animated: true, completion: nil)
//    }
    
    @objc func emailTeam(messageBody: String = NSLocalizedString("Hi, my question or feedback for Lockdown is: ", comment: ""), messageErrorBody: String = "") {
        DDLogInfo("")
        DDLogInfo("UserId: \(keychain[kVPNCredentialsId] ?? "No User ID")")
        DDLogInfo("UserReceipt: \(keychain[kVPNCredentialsKeyBase64] ?? "No User Receipt")")
        
        if (Client.hasValidCookie()) {
            DDLogInfo("Has loaded cookie.")
        }
        DDLogInfo("")
        PacketTunnelProviderLogs.flush()
        DDLogInfo("")
        
        var appendString = ""
        if (getUserWantsVPNEnabled()) {
            appendString = appendString + " - S"
        }
        let subject = "Lockdown Question or Feedback (iOS \(Bundle.main.versionString))" + appendString
        
        var message = messageBody
        if messageErrorBody != "" {
            message = messageBody + "\n\nError Details: " + messageErrorBody
        }
        message += "\n\n\n"
        
        sendMessage(message, subject: subject)
    }
    
    func sendMessage(_ message: String, subject: String) {
        let recipient = "team@lockdownprivacy.com" // TODO: change email
        if MFMailComposeViewController.canSendMail() {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            composeVC.setToRecipients([recipient])
            composeVC.setSubject(subject)
            composeVC.setMessageBody(message, isHTML: false)
            let attachmentData = NSMutableData()
            for logFileData in logFileDataArray {
                attachmentData.append(logFileData as Data)
            }
            composeVC.addAttachmentData(attachmentData as Data, mimeType: "text/plain", fileName: "diagnostics.txt")
            self.present(composeVC, animated: true, completion: nil)
        } else {
            
            guard let mailtoURL = Mailto.generateURL(recipient: recipient, subject: subject, body: message) else {
                DDLogError("Failed to generate mailto url")
                return
            }
            
            UIApplication.shared.open(mailtoURL, options: [:]) { (success) in
                if !success {
                    self.showPopupDialog(
                        title: NSLocalizedString("Couldn't Find Your Email Client", comment: ""),
                        message: NSLocalizedString("Please make sure you have added an e-mail account to your iOS device and try again.", comment: ""),
                        acceptButton: NSLocalizedString("OK", comment: "")
                    )
                }
            }
        }
    }
    
    //    @objc func signoutUser() {
    //        // TODO: complete this debug functionality
    //        let title = "CLEAR RECEIPT DATA?"
    //        let message = "Would you like to clear your local receipts?"
    //
    //        let popup = PopupDialog(title: title, message: message, image: nil, buttonAlignment: .horizontal)
    //
    //        let acceptButton = DefaultButton(title: "YES", dismissOnTap: true) {
    //           // Auth.clearCookies()
    //           // Auth.signoutUser()
    //        }
    //        let cancelButton = DefaultButton(title: "CANCEL", dismissOnTap: true) { }
    //        popup.addButtons([cancelButton, acceptButton])
    //
    //        self.present(popup, animated: true, completion: nil)
    //    }
    
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
