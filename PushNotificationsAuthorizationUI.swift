//
//  PushNotificationsAuthorizationUI.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 28.05.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import UIKit
import UserNotifications
import PopupDialog
import PromiseKit
import CocoaLumberjackSwift

extension PushNotifications.Authorization {
    
    static func requestWeeklyUpdateAuthorization(presentingDialogOn vc: UIViewController) -> Promise<Status> {
        
        guard getUserWantsNotificationsEnabled(forCategory: .weeklyUpdate) == false else {
            // if user already approved, just check the system status and don't show the dialog
            DDLogWarn("Requesting authorization but it is already approved by the user, requesting with the system to ensure")
            return authorizeWithSystemAfterUserApproval().then({ (systemStatus) -> Promise<Status> in
                switch systemStatus {
                case .deniedPreviously:
                    return Promise<Status> { resolver in
                        self.setUserWantsNotificationsEnabled(false, forCategory: .weeklyUpdate)
                        self.showGoToSettingsPopup(on: vc) {
                            resolver.fulfill(.notAuthorized)
                        }
                    }
                case .success:
                    return Promise.value(.authorized)
                case .deniedNow, .undetermined:
                    return Promise.value(.notAuthorized)
                }
            })
        }
        
        return Promise { resolver in
            
            let popup = PopupDialog(
                title: NSLocalizedString("Stay Protected", comment: ""),
                message: NSLocalizedString("Enable notifications to get a once-a-week summary and the latest block list updates. You can disable this anytime.", comment: ""),
                image: UIImage(named: "notification_example"),
                buttonAlignment: .horizontal,
                transitionStyle: .bounceDown,
                preferredWidth: 270,
                tapGestureDismissal: false,
                panGestureDismissal: false,
                hideStatusBar: false,
                completion: nil
            )
            
            let no = CancelButton(title: NSLocalizedString("No", comment: ""), dismissOnTap: true) {
                DDLogInfo("User did not allow notifications")
                self.setUserWantsNotificationsEnabled(false, forCategory: .weeklyUpdate)
                resolver.fulfill(.notAuthorized)
            }
            let yes = DefaultButton(title: NSLocalizedString("Enable", comment: ""), dismissOnTap: true) {
                self.setUserWantsNotificationsEnabled(true, forCategory: .weeklyUpdate)
                DDLogInfo("User allowed notifications, authorizing with the system now...")
                self.authorizeWithSystemAfterUserApproval().done { systemStatus in
                    switch systemStatus {
                    case .success:
                        resolver.fulfill(.authorized)
                    case .deniedNow, .undetermined:
                        resolver.fulfill(.notAuthorized)
                    case .deniedPreviously:
                        self.setUserWantsNotificationsEnabled(false, forCategory: .weeklyUpdate)
                        self.showGoToSettingsPopup(on: vc) {
                            resolver.fulfill(.notAuthorized)
                        }
                    }
                }.catch { error in
                    resolver.reject(error)
                }
            }
            yes.buttonColor = UIColor.tunnelsBlue
            yes.titleColor = UIColor.white
            
            popup.addButtons([no, yes])
            
            vc.present(popup, animated: true, completion: nil)
        }
    }
    
    static func showGoToSettingsPopup(on vc: UIViewController, completion: @escaping () -> ()) {
        let popup = PopupDialog(
            title: NSLocalizedString("Please first go to your iOS Settings > Notifications > Lockdown to enable notifications", comment: ""),
            message: nil,
            image: nil,
            buttonAlignment: .vertical,
            transitionStyle: .bounceDown,
            preferredWidth: 270,
            tapGestureDismissal: true,
            panGestureDismissal: false,
            hideStatusBar: false
        ) {
            completion()
        }
        
        let okayButton = DefaultButton(title: NSLocalizedString("Okay", comment: ""), dismissOnTap: true, action: nil)
        popup.addButton(okayButton)
        
        vc.present(popup, animated: true, completion: nil)
    }
    
    enum SystemAuthenticationStatus {
        case success
        case deniedPreviously
        case deniedNow
        case undetermined
    }
    
    static private func authorizeWithSystemAfterUserApproval() -> Promise<SystemAuthenticationStatus> {
        return Promise { resolver in
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                switch settings.authorizationStatus {
                case .authorized, .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (isSuccess, error) in
                        if let error = error {
                            resolver.reject(error)
                        } else {
                            resolver.fulfill(isSuccess ? .success : .deniedNow)
                        }
                    }
                case .denied:
                    resolver.fulfill(.deniedPreviously)
                default:
                    resolver.fulfill(.undetermined)
                }
            }
        }
    }
}
