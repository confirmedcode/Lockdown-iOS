//
//  ConfirmedBaseViewController.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit
import MessageUI
import CocoaLumberjackSwift
import Alamofire
import PopupDialog

open class ConfirmedBaseViewController: UIViewController, MFMailComposeViewControllerDelegate {

    
    //use these when processing transactions
    func unblockUserInteraction() {
        let view = self.view.viewWithTag(interactionBlockViewTag)
        if view != nil {
            view?.removeFromSuperview()
        }
    }
    
    func blockUserInteraction() {
        let view = UIView.init(frame: self.view.frame)
        view.tag = interactionBlockViewTag
        view.backgroundColor = UIColor.init(white: 1.0, alpha: 0.0)
        self.view.addSubview(view)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(emailTeam))
        longPressRecognizer.minimumPressDuration = 4
        self.view.addGestureRecognizer(longPressRecognizer)

        let doubleLongPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(signoutUser))
        doubleLongPressRecognizer.minimumPressDuration = 5
        doubleLongPressRecognizer.numberOfTouchesRequired = 2
        self.view.addGestureRecognizer(doubleLongPressRecognizer)

        // Do any additional setup after loading the view.
    }

    func showPopupDialog(title : String, message : String, acceptButton : String) {
        let popup = PopupDialog(title: title.uppercased(), message: message, image: nil, transitionStyle: .zoomIn, hideStatusBar: false)
        
        let acceptButton = DefaultButton(title: "OK", dismissOnTap: true) { }
        popup.addButtons([acceptButton])
        
        self.present(popup, animated: true, completion: nil)
        
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    @objc func signoutUser() {
        let title = "CLEAR ALL DATA?"
        let message = "Would you like to clear your VPN credentials and sign out of your account?"
        
        let popup = PopupDialog(title: title, message: message, image: nil, buttonAlignment: .horizontal)
        
        
        let acceptButton = DefaultButton(title: "YES", dismissOnTap: true) {
            Auth.clearCookies()
            Auth.signoutUser()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: TunnelsSubscription.TunnelsNotSubscribed), object: nil)
        }
        let cancelButton = DefaultButton(title: "CANCEL", dismissOnTap: true) { }
        popup.addButtons([cancelButton, acceptButton])
        
        self.present(popup, animated: true, completion: nil)
        
    }
    
    @objc func emailTeam() {
        //log a few things to help debug for user
        
        DDLogInfo("")
        DDLogInfo("")
        DDLogInfo("Email: \(Global.keychain[Global.kConfirmedEmail] ?? "No Email")")
        DDLogInfo("UserId: \(Global.keychain[Global.kConfirmedID] ?? "No User ID")")
        DDLogInfo("UserReceipt: \(Global.keychain[Global.kConfirmedReceiptKey] ?? "No User Receipt")")
        DDLogInfo("Sign in Error: \(Auth.signInError)")
        
        let cstorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage
        if let cookies = cstorage?.cookies {
            for cookie in cookies {
                if cookie.domain.contains("confirmedvpn.com") {
                    
                    DDLogInfo("Has loaded cookie.")
                }
            }
        }
        DDLogInfo("")
        
        if MFMailComposeViewController.canSendMail() {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            
            // Configure the fields of the interface.
            composeVC.setToRecipients(["team@lockdownhq.com"])
            composeVC.setSubject("Lockdown Feedback (iOS)")
            composeVC.setMessageBody("Hey Lockdown team, \nI have an issue with Lockdown - ", isHTML: false)
            
            let attachmentData = NSMutableData()
            for logFileData in logFileDataArray {
                attachmentData.append(logFileData as Data)
            }
            composeVC.addAttachmentData(attachmentData as Data, mimeType: "text/plain", fileName: "ConfirmedLogs.log")
            self.present(composeVC, animated: true, completion: nil)
        } else {
            // Tell user about not able to send email directly.
            showPopupDialog(title: "Email Not Setup",
                            message: "Please make sure you have added an e-mail account to your iOS device and try again.", acceptButton: "OK")
        }
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    let interactionBlockViewTag = 84814
}
