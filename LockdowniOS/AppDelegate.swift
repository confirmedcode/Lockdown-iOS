//
//  AppDelegate.swift
//  ConfirmediOS
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import BackgroundTasks
import CloudKit
import CocoaLumberjackSwift
import NetworkExtension
import PopupDialog
import SafariServices
import SwiftMessages
import SwiftyStoreKit
import PromiseKit
import WidgetKit

let fileLogger: DDFileLogger = DDFileLogger()

let kHasShownTitlePage: String = "kHasShownTitlePage"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private let connectivityService = ConnectivityService()
    private let paywallService = BasePaywallService.shared
    private let userService = BaseUserService.shared
    
    let noInternetMessageView = MessageView.viewFromNib(layout: .statusLine)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Clear local data for testing
//         try? keychain.removeAll()
//        for d in defaults.dictionaryRepresentation() {
//            defaults.removeObject(forKey: d.key)
//        }
//        return true

        // Set up basic logging
        setupLocalLogger()
        
        DDLogInfo("Creating protectionAccess.check file...")
        ProtectedFileAccess.createProtectionAccessCheckFile()
        
        UNUserNotificationCenter.current().delegate = self
        
        // Lockdown default lists
        setupFirewallDefaultBlockLists()
        
        // Whitelist default domains
        setupLockdownWhitelistedDomains()
        
        connectivityService.startObservingConnectivity()
        
        // Content Blocker
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: LockdownStorageIdentifier.contentBlockerId) { error in
            if error != nil {
                DDLogError("Error loading Content Blocker: \(String(describing: error))")
            }
        }
        
        // Prepare IAP
        VPNSubscription.cacheLocalizedPrices()
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                DDLogInfo("LAUNCH: Processing Purchase\n\(purchase)")
                if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {
                    if purchase.needsFinishTransaction {
                        DDLogInfo("Finishing transaction for purchase: \(purchase)")
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                }
            }
        }
        
        // Set up PopupDialog
        let dialogAppearance = PopupDialogDefaultView.appearance()
        if #available(iOS 13.0, *) {
            dialogAppearance.backgroundColor = .systemBackground
            dialogAppearance.titleColor = .label
            dialogAppearance.messageColor = .label
        } else {
            dialogAppearance.backgroundColor = .white
            dialogAppearance.titleColor = .black
            dialogAppearance.messageColor = .darkGray
        }
        dialogAppearance.titleFont            = fontBold15
        dialogAppearance.titleTextAlignment   = .center
        dialogAppearance.messageFont          = fontMedium15
        dialogAppearance.messageTextAlignment = .center
        let buttonAppearance = DefaultButton.appearance()
        if #available(iOS 13.0, *) {
            buttonAppearance.buttonColor = .systemBackground
            buttonAppearance.separatorColor = UIColor(white: 0.2, alpha: 1)
        }
        else {
            buttonAppearance.buttonColor    = .clear
            buttonAppearance.separatorColor = UIColor(white: 0.9, alpha: 1)
        }
        buttonAppearance.titleFont      = fontSemiBold17
        buttonAppearance.titleColor     = UIColor.tunnelsBlue
        let dynamicButtonAppearance = DynamicButton.appearance()
        if #available(iOS 13.0, *) {
            dynamicButtonAppearance.buttonColor = .systemBackground
            dynamicButtonAppearance.separatorColor = UIColor(white: 0.2, alpha: 1)
        }
        else {
            dynamicButtonAppearance.buttonColor    = .clear
            dynamicButtonAppearance.separatorColor = UIColor(white: 0.9, alpha: 1)
        }
        dynamicButtonAppearance.titleFont      = fontSemiBold17
        dynamicButtonAppearance.titleColor     = UIColor.tunnelsBlue
        let cancelButtonAppearance = CancelButton.appearance()
        if #available(iOS 13.0, *) {
            cancelButtonAppearance.buttonColor = .systemBackground
            cancelButtonAppearance.separatorColor = UIColor(white: 0.2, alpha: 1)
        }
        else {
            cancelButtonAppearance.buttonColor    = .clear
            cancelButtonAppearance.separatorColor = UIColor(white: 0.9, alpha: 1)
        }
        cancelButtonAppearance.titleFont      = fontSemiBold17
        cancelButtonAppearance.titleColor     = UIColor.lightGray
        
        // Periodically check if the firewall is functioning correctly - every 2.5 hours
        DDLogInfo("BGTask: Registering BGTask id \(FirewallRepair.identifier)")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: FirewallRepair.identifier, using: nil) { task in
            DDLogInfo("BGTask: Task starting")
            FirewallRepair.handleAppRefresh(task)
        }

        // WORKAROUND: allows the widget to toggle VPN
        application.registerForRemoteNotifications()
        setupWidgetToggleWorkaround()
        setupObservingSubscritionChanges()
        
        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.rootViewController = BlockListContainerViewController()
        window?.rootViewController = SplashscreenViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        DDLogInfo("applicationDidEnterBackground")
        FirewallRepair.reschedule()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        DDLogInfo("applicationDidBecomeActive")
        PacketTunnelProviderLogs.flush()
        flushBlockLog(log: { _ in })
        updateMetrics(.resetIfNeeded, rescheduleNotifications: .always)
        
        FirewallRepair.run(context: .homeScreenDidLoad)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        DDLogError("Successfully registered for remote notification: \(deviceToken)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DDLogError("Error registering for remote notification: \(error)")
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Deprecated, uses BackgroundTasks after iOS 13+
        DDLogInfo("BGF called, running Repair")
        FirewallRepair.run(context: .backgroundRefresh) { (result) in
            switch result {
            case .failed:
                DDLogInfo("BGF: failed")
                completionHandler(.failed)
            case .repairAttempted:
                DDLogInfo("BGF: attempted")
                completionHandler(.newData)
            case .noAction:
                DDLogInfo("BGF: no action")
                completionHandler(.noData)
            }
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
            // always set up cloudkit subscriptions - no downside to doing it
//            if error == nil, let subs = subscriptions {
////                for sub in subs {
////                    print("deleting sub: \(sub.subscriptionID)")
////                    privateDatabase.delete(withSubscriptionID: sub.subscriptionID, completionHandler: {
////                        result, error in
////                        print("result: \(result)")
////                    })
////                }
////                return
//                var isSubscribedToOpen = false
//                var isSubscribedToClose = false
//                var isSubscribedToRestart = false
//                for subscriptionObject in subs {
//                    if subscriptionObject.notificationInfo?.category == kCloseFirewallTunnelRecord {
//                        isSubscribedToClose = true
//                    }
//                    if subscriptionObject.notificationInfo?.category == kOpenFirewallTunnelRecord {
//                        isSubscribedToOpen = true
//                    }
//                    if subscriptionObject.notificationInfo?.category == kRestartFirewallTunnelRecord {
//                        isSubscribedToRestart = true
//                    }
//                }
//                if !isSubscribedToOpen {
//                    self.setupCloudKitSubscription(categoryName: kOpenFirewallTunnelRecord)
//                }
//                if !isSubscribedToClose {
//                    self.setupCloudKitSubscription(categoryName: kCloseFirewallTunnelRecord)
//                }
//                if !isSubscribedToRestart {
//                    self.setupCloudKitSubscription(categoryName: kRestartFirewallTunnelRecord)
//                }
//            }
//            else {
                self.setupCloudKitSubscription(categoryName: kCloseFirewallTunnelRecord)
                self.setupCloudKitSubscription(categoryName: kOpenFirewallTunnelRecord)
                self.setupCloudKitSubscription(categoryName: kRestartFirewallTunnelRecord)
//            }
        })
    }
    
    func setupCloudKitSubscription(categoryName: String) {
        let privateDatabase = CKContainer(identifier: kICloudContainer).privateCloudDatabase
        let subscription = CKQuerySubscription(recordType: categoryName,
                                               predicate: NSPredicate(value: true),
                                               options: .firesOnRecordCreation)
        let notificationInfo = CKSubscription.NotificationInfo()
        //notificationInfo.alertBody = "" // iOS 13 doesn't like this - fails to trigger notification
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = false
        notificationInfo.category = categoryName
        subscription.notificationInfo = notificationInfo
        privateDatabase.save(subscription) { _, error in
            if let err = error {
                DDLogInfo("Could not save CloudKit subscription (not signed in?) \(err)")
            } else {
                DispatchQueue.main.async {
                    DDLogInfo("Successfully saved CloudKit subscription")
                }
            }
        }
    }
    
    func clearDatabaseForRecord(recordName: String) {
        let privateDatabase = CKContainer(identifier: kICloudContainer).privateCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordName, predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (record, error) in
            if let err = error {
                DDLogError("Error querying for CKRecordType: \(recordName) - \(err)")
            }
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
                } else if message.contains(kOpenFirewallTunnelRecord) {
                    FirewallController.shared.setEnabled(true, isUserExplicitToggle: true, completion: { _ in })
                } else if message.contains(kRestartFirewallTunnelRecord) {
                    FirewallController.shared.restart(completion: { error in
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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let host = components.host else {
                print("Invalid URL")
                return false
        }
        
        if (host == "resetsuccessful") {
            let popup = PopupDialog(title: "Password Reset Successfully",
                                    message: "Please Sign In With Your New Password",
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
                    if let hvc = self.getCurrentViewController() as? HomeViewController {
                        AccountUI.presentSignInToAccount(on: hvc)
                    }
                }
            ])
            self.getCurrentViewController()?.present(popup, animated: true, completion: nil)
            return true
        }
        
        else if (host == "changeVPNregion") {
            if let home = self.getCurrentViewController() as? HomeViewController {
                home.showSetRegion(self)
            }
        }
        
        else if (host == "showMetrics") {
            if let home = self.getCurrentViewController() as? HomeViewController {
                home.showBlockLog(self)
            }
        }
        
        else if (host == "toggleFirewall") {
            if let home = self.getCurrentViewController() as? LDFirewallViewController {
                home.toggleFirewall()
            }
        }
        
        else if (host == "toggleVPN") {
            if let home = self.getCurrentViewController() as? LDVpnViewController {
                home.toggleVPN()
            }
        }
        
        else if (host == "emailconfirmed") {
            // test the stored login
            guard let apiCredentials = getAPICredentials() else {
                let popup = PopupDialog(title: "Error",
                                        message: NSLocalizedString("No stored API credentials found. Please contact team@lockdownprivacy.com about this error.", comment: ""),
                                        image: nil,
                                        buttonAlignment: .horizontal,
                                        transitionStyle: .bounceDown,
                                        preferredWidth: 270,
                                        tapGestureDismissal: true,
                                        panGestureDismissal: false,
                                        hideStatusBar: false,
                                        completion: nil)
                popup.addButtons([
                   DefaultButton(title: NSLocalizedString("Okay", comment: ""), dismissOnTap: true) {}
                ])
                getCurrentViewController()?.present(popup, animated: true, completion: nil)
                return true
            }
            firstly {
                try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
            }
            .done { (signin: SignIn) in
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
                   DefaultButton(title: NSLocalizedString("Okay", comment: ""), dismissOnTap: true) {}
                ])
                self.getCurrentViewController()?.present(popup, animated: true, completion: nil)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: AccountUI.accountStateDidChange, object: self)
                }
            }
            .catch { error in
                var errorMessage = error.localizedDescription
                DDLogError("AppDelegate error: \(errorMessage)")
                if let apiError = error as? ApiError {
                    errorMessage = apiError.message
                }
                
                let popup = PopupDialog(title: "Error Confirming Account",
                                        message: "\(NSLocalizedString("Error while trying to confirm your account:", comment: "")) \(errorMessage). \(NSLocalizedString("If this persists, please contact team@lockdownprivacy.com.", comment: ""))",
                                        image: nil,
                                        buttonAlignment: .horizontal,
                                        transitionStyle: .bounceDown,
                                        preferredWidth: 270,
                                        tapGestureDismissal: true,
                                        panGestureDismissal: false,
                                        hideStatusBar: false,
                                        completion: nil)
                popup.addButtons([
                   DefaultButton(title: NSLocalizedString("Okay", comment: ""), dismissOnTap: true) {}
                ])
                self.getCurrentViewController()?.present(popup, animated: true, completion: nil)
            }
        }
        
        return true
    }
    
    // MARK: - Utilities
    // Returns the most recently presented UIViewController (visible)
    func getCurrentViewController() -> UIViewController? {
        return getCurrentViewController(in: UIApplication.shared.keyWindow?.rootViewController)
    }
    
    private func getCurrentViewController(in root: UIViewController?) -> UIViewController? {
        // If the root view is a navigation controller, we can just return the visible ViewController
        if let navigationController = getNavigationController(in: root) {
            return navigationController.visibleViewController
        }
        if let tabBarVC = root as? UITabBarController {
            if let nvc = getNavigationController(in: tabBarVC.selectedViewController) {
                return nvc.visibleViewController
            } else if let selected = tabBarVC.selectedViewController {
                return selected
            }
        }
        // Otherwise, we must get the root UIViewController and iterate through presented views
        if let rootController = root {
            var currentController: UIViewController! = rootController
            // Each ViewController keeps track of the view it has presented, so we
            // can move from the head to the tail, which will always be the current view
            while( currentController.presentedViewController != nil ) {
                currentController = currentController.presentedViewController
            }
            return currentController
        }
        return nil
    }

    // Returns the navigation controller if it exists
    func getNavigationController(in root: UIViewController?) -> UINavigationController? {
        if let navigationController = root {
            return navigationController as? UINavigationController
        }
        return nil
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = PushNotifications.Identifier(rawValue: response.notification.request.identifier)
        if identifier.isWeeklyUpdate {
            showUpdateBlockListsFlow()
        } else if identifier == .onboarding {
            highlightBlockLogOnHomeVC()
        }
        completionHandler()
    }
    
    private func highlightBlockLogOnHomeVC() {
        if let hvc = self.getCurrentViewController() as? HomeViewController {
            hvc.highlightBlockLog()
        }
    }
    
    private func showUpdateBlockListsFlow() {
        // the actual update happens in `appHasJustBeenUpgradedOrIsNewInstall`,
        // these are supporting visuals
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.showUpdatingBlockListsLoader()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
                self.hideUpdatingBlockListsLoader()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.showBlockListsUpdatedPopup()
                }
            }
        }
    }
    
    private func showUpdatingBlockListsLoader() {
        let activity = ActivityData(
            message: .localized("Updating Block Lists"),
            messageFont: UIFont(name: "Montserrat-Bold", size: 18),
            type: .ballSpinFadeLoader,
            backgroundColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        )
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activity, NVActivityIndicatorView.DEFAULT_FADE_IN_ANIMATION)
    }
    
    private func hideUpdatingBlockListsLoader() {
        NVActivityIndicatorPresenter.sharedInstance.stopAnimating(NVActivityIndicatorView.DEFAULT_FADE_OUT_ANIMATION)
    }
    
    private func showBlockListsUpdatedPopup() {
        let popup = PopupDialog(
            title: NSLocalizedString("Update Success", comment: ""),
            message: "You're now protected against the latest trackers. 🎉"
        )
        popup.addButton(DefaultButton(title: .localizedOkay, dismissOnTap: true, action: nil))
        self.getCurrentViewController()?.present(popup, animated: true, completion: nil)
    }
    
    // MARK: - subscription
    
    private func setupObservingSubscritionChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSplashScreen),
            name: AccountUI.subscritionTypeChanged,
            object: nil
        )
    }
    
    @objc
    private func openSplashScreen() {
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        let vc = SplashscreenViewController()
        let navigation = UINavigationController(rootViewController: vc)
        keyWindow?.rootViewController = navigation
    }
}

extension PacketTunnelProviderLogs {
    static func flush() {
        guard !PacketTunnelProviderLogs.allEntries.isEmpty else {
            DDLogInfo("Packet Tunnel Provider Logs: EMPTY")
            return
        }
        
        DDLogInfo("Packet Tunnel Provider Logs: START")
        for logEntry in PacketTunnelProviderLogs.allEntries {
            DDLogError(logEntry)
        }
        DDLogInfo("Packet Tunnel Provider Logs: END")
        PacketTunnelProviderLogs.clear()
    }
}
