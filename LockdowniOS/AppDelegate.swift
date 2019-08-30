//
//  AppDelegate.swift
//  ConfirmediOS
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import SwiftyStoreKit
import KeychainAccess
import SafariServices
import SwiftMessages
import StoreKit
import CloudKit
import CocoaLumberjackSwift
import PopupDialog
import PromiseKit

let fileLogger: DDFileLogger = DDFileLogger()

let kHasShownTitlePage: String = "kHasShownTitlePage"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let noInternetMessageView = MessageView.viewFromNib(layout: .statusLine)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Clear local data for testing
//        for d in defaults.dictionaryRepresentation() {
//            defaults.removeObject(forKey: d.key)
//        }
        
        // Set up basic logging
        setupLocalLogger()
        
        // Set up PopupDialog
        let dialogAppearance = PopupDialogDefaultView.appearance()
        dialogAppearance.backgroundColor      = .white
        dialogAppearance.titleFont            = UIFont(name: "Montserrat-Bold", size: 15)!
        dialogAppearance.titleColor           = .darkGray
        dialogAppearance.titleTextAlignment   = .center
        dialogAppearance.messageFont          = UIFont(name: "Montserrat-Medium", size: 15)!
        dialogAppearance.messageColor         = .darkGray
        dialogAppearance.messageTextAlignment = .center
        let buttonAppearance = DefaultButton.appearance()
        buttonAppearance.titleFont      = UIFont(name: "Montserrat-SemiBold", size: 17)!
        buttonAppearance.titleColor     = UIColor.tunnelsBlue
        buttonAppearance.buttonColor    = .clear
        buttonAppearance.separatorColor = UIColor(white: 0.9, alpha: 1)
        let cancelButtonAppearance = CancelButton.appearance()
        cancelButtonAppearance.titleFont      = UIFont(name: "Montserrat-SemiBold", size: 17)!
        cancelButtonAppearance.titleColor     = UIColor.lightGray
        cancelButtonAppearance.buttonColor    = .clear
        cancelButtonAppearance.separatorColor = UIColor(white: 0.9, alpha: 1)

        // Lockdown default lists
        setupFirewallDefaultBlockLists()
        
        // Whitelist default domains
        setupLockdownWhitelistedDomains()
        
        // Show indicator at top when internet not reachable
        reachability?.whenReachable = { reachability in
            SwiftMessages.hide()
        }
        reachability?.whenUnreachable = { _ in
            DDLogInfo("Internet not reachable")
            self.noInternetMessageView.backgroundView.backgroundColor = UIColor.orange
            self.noInternetMessageView.bodyLabel?.textColor = UIColor.white
            self.noInternetMessageView.configureContent(body: "No Internet Connection")
            var noInternetMessageViewConfig = SwiftMessages.defaultConfig
            noInternetMessageViewConfig.presentationContext = .window(windowLevel: UIWindow.Level(rawValue: 0))
            noInternetMessageViewConfig.preferredStatusBarStyle = .lightContent
            noInternetMessageViewConfig.duration = .forever
            SwiftMessages.show(config: noInternetMessageViewConfig, view: self.noInternetMessageView)
        }
        do {
            try reachability?.startNotifier()
        } catch {
            DDLogError("Unable to start reachability notifier")
        }
        
        // Content Blocker
        SFContentBlockerManager.reloadContentBlocker( withIdentifier: "com.confirmed.lockdown.Confirmed-Blocker") { (_ error: Error?) -> Void in
            if error != nil {
                DDLogError("Error loading Content Blocker: \(String(describing: error))")
            }
        }
        
        // Prepare IAP
        VPNSubscription.cacheLocalizedPrices()
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                DDLogInfo("LAUNCH: Processing Purchase\n\(purchase)");
                if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {
                    if purchase.needsFinishTransaction {
                        DDLogInfo("Finishing transaction for purchase: \(purchase)")
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                }
            }
        }
        
        // Periodically check if the firewall is functioning correctly
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        // WORKAROUND: allows the widget to toggle VPN
        application.registerForRemoteNotifications()
        setupWidgetToggleWorkaround()
        
        // If not yet agreed to privacy policy, set initial view controller to TitleViewController
        if (defaults.bool(forKey: kHasShownTitlePage) == false) {
            // don't show onboarding page for anyone who installed before Aug 16th
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            let tutorialCutoffDate = formatter.date(from: "2019/08/16 00:00")!.timeIntervalSince1970;
            if let appInstall = appInstallDate, appInstall.timeIntervalSince1970 < tutorialCutoffDate {
                DDLogInfo("Not showing onboarding page, installation epoch \(appInstall.timeIntervalSince1970)")
            }
            else {
                DDLogInfo("Showing onboarding page")
                self.window = UIWindow(frame: UIScreen.main.bounds)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let viewController = storyboard.instantiateViewController(withIdentifier: "titleViewController") as! TitleViewController
                self.window?.rootViewController = viewController
                self.window?.makeKeyAndVisible()
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if getUserWantsFirewallEnabled() && FirewallController.shared.status() == .connected {
            DDLogInfo("user wants firewall enabled and connected, testing blocking with background fetch")
            _ = Client.getBlockedDomainTest(connectionSuccessHandler: {
                DDLogError("Background Fetch Test: Connected to \(testFirewallDomain) even though it's supposed to be blocked, restart the Firewall")
                FirewallController.shared.restart(completion: {
                    error in
                    if error != nil {
                        DDLogError("Error restarting firewall on background fetch: \(error!)")
                    }
                    completionHandler(.newData)
                })
            }, connectionFailedHandler: {
                error in
                if error != nil {
                    let nsError = error! as NSError
                    if nsError.domain == NSURLErrorDomain {
                        DDLogInfo("Background Fetch Test: Successful blocking of \(testFirewallDomain) with NSURLErrorDomain error: \(nsError)")
                    }
                    else {
                        DDLogInfo("Background Fetch Test: Successful blocking of \(testFirewallDomain), but seeing non-NSURLErrorDomain error: \(error!)")
                    }
                }
                completionHandler(.newData)
            })
        }
        else {
            completionHandler(.newData)
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - WIDGET TOGGLE WORKAROUND
    func setupWidgetToggleWorkaround() {
        DDLogInfo("Setting up CloudKit Workaround")
        clearDatabaseForRecord(recordName: kOpenFirewallTunnelRecord)
        clearDatabaseForRecord(recordName: kCloseFirewallTunnelRecord)
        clearDatabaseForRecord(recordName: kRestartFirewallTunnelRecord)
        let privateDatabase = CKContainer(identifier: kICloudContainer).privateCloudDatabase
        privateDatabase.fetchAllSubscriptions(completionHandler: { subscriptions, error in
            if error == nil, let subs = subscriptions {
                var isSubscribedToOpen = false
                var isSubscribedToClose = false
                var isSubscribedToRestart = false
                for subscriptionObject in subs {
                    if subscriptionObject.notificationInfo?.category == kCloseFirewallTunnelRecord {
                        isSubscribedToClose = true
                    }
                    if subscriptionObject.notificationInfo?.category == kOpenFirewallTunnelRecord {
                        isSubscribedToOpen = true
                    }
                    if subscriptionObject.notificationInfo?.category == kRestartFirewallTunnelRecord {
                        isSubscribedToRestart = true
                    }
                }
                if !isSubscribedToOpen {
                    self.setupCloudKitSubscription(categoryName: kOpenFirewallTunnelRecord)
                }
                if !isSubscribedToClose {
                    self.setupCloudKitSubscription(categoryName: kCloseFirewallTunnelRecord)
                }
                if !isSubscribedToRestart {
                    self.setupCloudKitSubscription(categoryName: kRestartFirewallTunnelRecord)
                }
            }
            else {
                self.setupCloudKitSubscription(categoryName: kCloseFirewallTunnelRecord)
                self.setupCloudKitSubscription(categoryName: kOpenFirewallTunnelRecord)
                self.setupCloudKitSubscription(categoryName: kRestartFirewallTunnelRecord)
            }
        })
    }
    
    func setupCloudKitSubscription(categoryName : String) {
        let privateDatabase = CKContainer(identifier: kICloudContainer).privateCloudDatabase
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: categoryName,
                                               predicate: predicate,
                                               options: .firesOnRecordCreation)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = ""
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = false
        notificationInfo.category = categoryName
        
        subscription.notificationInfo = notificationInfo
        
        privateDatabase.save(subscription,
                             completionHandler: ({returnRecord, error in
                                if let err = error {
                                    DDLogInfo("Could not save CloudKit subscription (signed in?) \(err)")
                                } else {
                                    DispatchQueue.main.async() {
                                        DDLogInfo("Successfully saved CloudKit subscription")
                                    }
                                }
                             }))
    }
    
    func clearDatabaseForRecord(recordName: String) {
        let privateDatabase = CKContainer(identifier: kICloudContainer).privateCloudDatabase
        let predicate = NSPredicate.init(value: true)
        let query = CKQuery.init(recordType: recordName, predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (record, error) in
            for aRecord in record! {
                privateDatabase.delete(withRecordID: aRecord.recordID, completionHandler: { (recordID, error) in
                    DDLogInfo("Deleting record \(aRecord.recordID)")
                })
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DDLogInfo("Receiving remote notification")
        if let aps = userInfo["aps"] as? NSDictionary {
            if let message = aps["category"] as? NSString {
                if message.contains(kCloseFirewallTunnelRecord) {
                    FirewallController.shared.setEnabled(false, isUserExplicitToggle: true, completion: { _ in })
                }
                else if message.contains(kOpenFirewallTunnelRecord) {
                    FirewallController.shared.setEnabled(true, isUserExplicitToggle: true, completion: { _ in })
                }
                else if message.contains(kRestartFirewallTunnelRecord) {
                    FirewallController.shared.restart(completion: {
                        error in
                        if error != nil {
                            DDLogError("Error restarting firewall on RemoteNotification: \(error!)")
                        }
                    })
                }
                clearDatabaseForRecord(recordName: kOpenFirewallTunnelRecord)
                clearDatabaseForRecord(recordName: kCloseFirewallTunnelRecord)
                clearDatabaseForRecord(recordName: kRestartFirewallTunnelRecord)
            }
        }
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 10.0, execute: {
            completionHandler(.newData)
        })
    }

}

