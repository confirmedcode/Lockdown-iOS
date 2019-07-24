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
import StoreKit
import CloudKit
import Alamofire
import CocoaLumberjackSwift
import MessageUI
import PopupDialog

let fileLogger: DDFileLogger = DDFileLogger() // File Logger


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupLogging()
        application.registerForRemoteNotifications()
        Global.sharedUserDefaults().synchronize()
        Utils.chooseAPIVersion()
        Auth.processPartnerCode()
        Utils.setupLockdownDefaults()
        
        //var rules = getLockdownIPv6()
        //print("Rules \(rules)")
        /*let defaults = Global.sharedUserDefaults()
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }*/
        
        SFContentBlockerManager.reloadContentBlocker(
        withIdentifier: Global.contentBlockerBundleID) { (_ error: Error?) -> Void in
            if let err = error {
                DDLogError("Reloaded blocker with error \(err)")
            }
        }
        
        let buttonAppearance = DefaultButton.appearance()
        buttonAppearance.titleColor = UIColor.tunnelsBlueColor

        //start the subscription check
        TunnelsSubscription.isSubscribed = .Loading
        TunnelsSubscription.isSubscribed(refreshITunesIfNeeded: false, isSubscribed:{
            if Auth.signInError == 1 {
                DDLogWarn("Email Not Confirmed \(Global.keychain[Global.kConfirmedEmail] ?? "")")
                
            }
        }, isNotSubscribed:{
            if Auth.signInError == 1 {
               DDLogWarn("Email Not Confirmed \(Global.keychain[Global.kConfirmedEmail] ?? "")")
            }
        })
        TunnelsSubscription.cacheLocalizedPrice()
        
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    DDLogInfo("purchased: \(purchase)")
                }
            }
        }
        
        for transaction in SKPaymentQueue.default().transactions {
            DDLogInfo("finish transactions pending sind last load...")
            SKPaymentQueue.default().finishTransaction(transaction)
        }

        setupCloudKit()
        
        if Config.appConfiguration == .AppStore {
            UIApplication.shared.setMinimumBackgroundFetchInterval(86400) //once a day is fine
        }
        else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum) //speed up for debug
        }
        
        return true
    }
    
    func clearDatabaseForRecord(recordName : String) {
        let privateDatabase = CKContainer.init(identifier: Global.kICloudContainer).privateCloudDatabase
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
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        /*let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if manager.connection.status == .connected {
                Auth.getActiveSubscriptions { (status, didCompleteCall, error, json) in
                    if status || didCompleteCall {
                        DDLogInfo("Background check, user subscribed")
                        completionHandler(.newData)
                    }
                    else {
                        VPNController.forceVPNOff()
                        DDLogError("Background check, user not subscribed")
                        completionHandler(.newData)
                    }
                }
            }
        })*/
    }
    
    func setupCloudKitSubscription(categoryName : String) {
        let privateDatabase = CKContainer.init(identifier: Global.kICloudContainer).privateCloudDatabase
        let predicate = NSPredicate.init(value: true)
        var subscription = CKQuerySubscription(recordType: categoryName,
                                               predicate: predicate,
                                               options: .firesOnRecordCreation)
        
        var notificationInfo = CKSubscription.NotificationInfo()
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
    
    func setupCloudKit() {
        //clear the database
        DDLogInfo("Setting up CloudKit")
        clearDatabaseForRecord(recordName: Global.kOpenTunnelRecord)
        clearDatabaseForRecord(recordName: Global.kCloseTunnelRecord)
        
        
        //this is a workaround for an Apple bug where a tunnel cannot be closed from a widget
        let privateDatabase = CKContainer.init(identifier: Global.kICloudContainer).privateCloudDatabase
        
        privateDatabase.fetchAllSubscriptions(completionHandler: { subscriptions, error in
            if error == nil, let subs = subscriptions {
                var isSubscribedToOpen = false
                var isSubscribedToClose = false
                
                for subscriptionObject in subs {
                    if subscriptionObject.notificationInfo?.category == Global.kCloseTunnelRecord {
                        isSubscribedToClose = true
                    }
                    if subscriptionObject.notificationInfo?.category == Global.kOpenTunnelRecord {
                        isSubscribedToOpen = true
                    }
                }
                
                if !isSubscribedToOpen {
                    self.setupCloudKitSubscription(categoryName: Global.kOpenTunnelRecord)
                }
                if !isSubscribedToClose {
                    self.setupCloudKitSubscription(categoryName: Global.kCloseTunnelRecord)
                }
            }
            else {
                self.setupCloudKitSubscription(categoryName: Global.kCloseTunnelRecord)
                self.setupCloudKitSubscription(categoryName: Global.kOpenTunnelRecord)
            }
        })
    }
    

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DDLogInfo("Receiving remote notification")
        
        if let aps = userInfo["aps"] as? NSDictionary {
                if let message = aps["category"] as? NSString {
                    //Do stuff
                    if message.contains(Global.kCloseTunnelRecord) {
                        VPNController.shared.disconnectFromVPN()
                        //VPNController.shared.disableWhitelistingProxy()
                        clearDatabaseForRecord(recordName: Global.kOpenTunnelRecord)
                        clearDatabaseForRecord(recordName: Global.kCloseTunnelRecord)
                    }
                }
        }
        if let aps = userInfo["aps"] as? NSDictionary {
            if let message = aps["category"] as? NSString {
                //Do stuff
                if message.contains(Global.kOpenTunnelRecord) {
                    //VPNController.shared.setupWhitelistingProxy()
                    VPNController.shared.connectToVPN()
                    clearDatabaseForRecord(recordName: Global.kOpenTunnelRecord)
                    clearDatabaseForRecord(recordName: Global.kCloseTunnelRecord)
                }
            }
            
        }
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 10.0, execute: {
            completionHandler(.newData)
        })
    }
    
    
    func setupLogging() {
        DDLog.add(DDTTYLogger.sharedInstance)
        DDLog.add(DDASLLogger.sharedInstance)
        DDTTYLogger.sharedInstance.logFormatter = LogFormatter()
        DDASLLogger.sharedInstance.logFormatter = LogFormatter()
        
        fileLogger.rollingFrequency = TimeInterval(60*60*24)  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        fileLogger.logFormatter = LogFormatter()
        DDLog.add(fileLogger)
        //DDTTYLogger.sharedInstance.colorsEnabled = true
        let nsObject: String? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        let systemVersion = UIDevice.current.systemVersion
        DDLogInfo("")
        DDLogInfo("")
        DDLogInfo("")
        DDLogInfo("************************************************")
        DDLogInfo("Confirmed VPN (iOS): v" + nsObject!)
        DDLogInfo("iOS version: " + systemVersion)
        DDLogInfo("Device model: " + UIDevice.current.modelName)
        DDLogInfo("************************************************")
        
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        DDLogInfo("App is active again")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        VPNController.shared.syncVPNAndWhitelistingProxy()
        
        NotificationCenter.post(name: .appActive)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait //we should eventually support more
    }

}

