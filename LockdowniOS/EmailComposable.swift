//
//  EmailComposable.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/2/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import CocoaLumberjackSwift
import Foundation
import MessageUI

protocol EmailComposable: MFMailComposeViewControllerDelegate {
    func composeEmail(_ email: Email, to recipient: String, errorBody: String?, attachments: [EmailAttachment])
}

extension EmailComposable where Self: BaseViewController {
    
    func composeEmail(_ email: Email,
                      to recipient: String = EmailAddress.team,
                      errorBody: String? = nil,
                      attachments: [EmailAttachment] = []) {
        writeUserLogs()
        
        var message = email.body
        if let errorBody = errorBody {
            message += "\n\nError Details: " + errorBody
        }
        message += email.needsFurtherUserInput ? "\n\n\n" : ""
        
        if MFMailComposeViewController.canSendMail() {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            composeVC.setToRecipients([recipient])
            composeVC.setSubject(email.subject)
            composeVC.setMessageBody(message, isHTML: false)
            
            attachments.forEach {
                composeVC.addAttachmentData($0.data, mimeType: $0.mimeType, fileName: $0.fileName)
            }
            present(composeVC, animated: true)
        } else {
            guard let mailtoURL = Mailto.generateURL(recipient: recipient, subject: email.subject, body: message) else {
                DDLogError("Failed to generate mailto url")
                return
            }
            
            UIApplication.shared.open(mailtoURL, options: [:]) { (success) in
                guard !success else { return }
                self.showPopupDialog(
                    title: .localized("Couldn't Find Your Email Client"),
                    message: .localized("Please make sure you have added an e-mail account to your iOS device and try again."),
                    acceptButton: .localizedOK)
            }
        }
    }
    
    private func writeUserLogs() {
        DDLogInfo("")
        DDLogInfo("UserId: \(keychain[kVPNCredentialsId] ?? "No User ID")")
        DDLogInfo("UserReceipt: \(keychain[kVPNCredentialsKeyBase64] ?? "No User Receipt")")
        
        if Client.hasValidCookie() {
            DDLogInfo("Has loaded cookie.")
        }
        DDLogInfo("")
        PacketTunnelProviderLogs.flush()
        DDLogInfo("")
    }
}

enum Email {
    case helpOrFeedback
    case deleteAccount(email: String, userId: String)
    case termsAndPrivacyPolicy
    case blockingImprovementIdeas
    case custom(subject: String, body: String)
    
    var subject: String {
        var appendString = ""
        if getUserWantsVPNEnabled() {
            appendString += " - S"
        }
        switch self {
        case .helpOrFeedback:
            return "Lockdown Question or Feedback (iOS \(Bundle.main.versionString))" + appendString
        case .deleteAccount:
            return "Delete Account"
        case .termsAndPrivacyPolicy:
            return "Lockdown Privacy Policy Question or Feedback (iOS \(Bundle.main.versionString))" + appendString
        case .blockingImprovementIdeas:
            return "Lockdown Blocking Improvement Ideas (iOS \(Bundle.main.versionString))"
        case .custom(let subject, _):
            return subject
        }
    }
    
    var body: String {
        switch self {
        case .helpOrFeedback:
            return "Hi, my question or feedback for Lockdown is: "
        case .deleteAccount(let email, let userId):
            return "Please, delete my entire account record, along with associated personal data.\n\nDeletion credentials: \n\(email)\n\(userId)"
        case .termsAndPrivacyPolicy:
            return "Hi, my question or feedback for Lockdown Privacy Policy is: "
        case .blockingImprovementIdeas:
            return "Hi, my blocking improvement ideas for Lockdown Privacy are: "
        case .custom(_, let body):
            return body
        }
    }
    
    /// Defines whether the e-mail form expects user to type some additional info below the email body.
    /// If yes, 3 new lines will be inserted.
    var needsFurtherUserInput: Bool {
        switch self {
        case .helpOrFeedback, .termsAndPrivacyPolicy, .blockingImprovementIdeas, .custom:
            return true
        case .deleteAccount:
            return false
        }
    }
}

enum EmailAttachment {
    case diagnostics
    
    var data: Data {
        switch self {
        case .diagnostics:
            let attachmentData = NSMutableData()
            for logFileData in logFileDataArray {
                attachmentData.append(logFileData as Data)
            }
            return attachmentData as Data
        }
    }
    
    var mimeType: String {
        switch self {
        case .diagnostics:
            return "text/plain"
        }
    }
    
    var fileName: String {
        switch self {
        case .diagnostics:
            return "diagnostics.txt"
        }
    }
}
