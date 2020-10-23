//
//  PushNotifications.swift
//  LockdowniOS
//
//  Created by Oleg Dreyman on 26.05.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation
import UserNotifications
import CocoaLumberjackSwift

final class PushNotifications {
    
    private let serialQueue = DispatchQueue(label: "PushNotifications-ScheduleQueue")
    private let energySaving = PushNotifications.EnergySaving()
    
    enum Category: String {
        case weeklyUpdate = "WeeklyUpdate"
    }
    
    static let shared = PushNotifications()
    
    struct RescheduleOptions: OptionSet {
        let rawValue: Int
        
        static let energySaving = RescheduleOptions(rawValue: 1 << 0)
    }
    
    func rescheduleWeeklyUpdate(options: RescheduleOptions) {
        serialQueue.async {
            self.energySaving.rescheduleRequestDidArrive()
            if options.contains(.energySaving) {
                if self.energySaving.isAllowedToReschedule() {
                    self.energySaving.willScheduleNotification()
                    self.scheduleWeeklyUpdate(options: options)
                }
            } else {
                self.energySaving.willScheduleNotification()
                self.scheduleWeeklyUpdate(options: options)
            }
        }
    }
    
    func scheduleOnboardingNotification(options: RescheduleOptions) {
        serialQueue.async {
            self.scheduleOnboardingPush(options: options)
        }
    }
    
    func userDidAuthorizeWeeklyUpdate() {
        SchedulingHelper.calculateAndSaveNotificationsAllowedAfterDate()
        serialQueue.asyncAfter(deadline: .now() + 1.0) {
            self.energySaving.willScheduleNotification()
            self.scheduleWeeklyUpdate(options: [])
        }
    }
    
    func removeAllPendingNotifications() {
        serialQueue.async {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    private func scheduleOnboardingPush(options: RescheduleOptions) {
        
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(serialQueue))
        #endif

        guard Authorization.getUserWantsNotificationsEnabledForAnyCategory() else {
            if options.contains(.energySaving) == false {
                DDLogWarn("Notifications are not approved by user, not scheduling onboarding")
            }
            return
        }
        
        let totalMetrics = getTotalMetrics()
        
        guard totalMetrics >= 100 else {
            if options.contains(.energySaving) == false {
                DDLogError("Error: asked to schedule onboarding notification when total metrics are below 100")
            }
            return
        }
        
        let content = ContentMaker.makeNotificationContentForOnboarding()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        let identifier = Identifier.onboarding
        let request = UNNotificationRequest(identifier: identifier.rawValue, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if options.contains(.energySaving) {
                return
            }
            
            if let error = error {
                DDLogError("Error scheduling notification: \(error)")
            } else {
                DDLogInfo("Succesfully scheduled onboarding notification")
            }
        }
    }
    
    private func scheduleWeeklyUpdate(options: RescheduleOptions) {
        
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(serialQueue))
        #endif
        
        guard Authorization.getUserWantsNotificationsEnabled(forCategory: .weeklyUpdate) else {
            if options.contains(.energySaving) == false {
                DDLogWarn("Notifications are not approved by user for weekly updates, not scheduling")
            }
            return
        }
        
        guard let upcomingWeeklyUpdateDateComponents = SchedulingHelper.upcomingWeeklyUpdateDateComponents() else {
            return
        }
        
        let weeklyMetrics: Int
        if let weekOfYear = upcomingWeeklyUpdateDateComponents.weekOfYear {
            if weekOfYear != defaults.integer(forKey: kActiveWeek) {
                weeklyMetrics = 0
            } else {
                weeklyMetrics = getWeekMetrics()
            }
        } else {
            weeklyMetrics = getWeekMetrics()
        }
        
        let content = ContentMaker.makeNotificationContent(weeklyMetrics: weeklyMetrics)
        let trigger = UNCalendarNotificationTrigger(dateMatching: upcomingWeeklyUpdateDateComponents, repeats: false)
        let identifier = Identifier.weeklyUpdate(dateComponents: upcomingWeeklyUpdateDateComponents)
        let request = UNNotificationRequest(identifier: identifier.rawValue, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if options.contains(.energySaving) {
                return
            }
            
            if let error = error {
                DDLogError("Error scheduling notification: \(error)")
            } else {
                self.logScheduledNotification(request: request, triggerDate: trigger.nextTriggerDate() ?? .distantPast, weeklyMetrics: weeklyMetrics)
            }
        }
    }
    
    private func logScheduledNotification(request: UNNotificationRequest, triggerDate: Date, weeklyMetrics: Int) {
        DDLogInfo("Scheduled notification with id \(request.identifier) for metrics: \(weeklyMetrics), \(triggerDate)")
    }
}

extension PushNotifications {
    struct Identifier: RawRepresentable {
        var rawValue: String
        
        init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        static func weeklyUpdate(dateComponents: DateComponents) -> Identifier {
            guard let year = dateComponents.year, let month = dateComponents.month, let day = dateComponents.day else {
                DDLogError("Wrong dateComponents: \(dateComponents)")
                return Identifier(rawValue: "weekly-update-invalid")
            }
            
            return Identifier(rawValue: "weekly-update-\(year)-\(month)-\(day)")
        }
        
        static let onboarding = Identifier(rawValue: "onboarding")
        
        var isWeeklyUpdate: Bool {
            return rawValue.starts(with: "weekly-update")
        }
    }
}

extension PushNotifications {
    enum ContentMaker {
        static func makeNotificationContent(weeklyMetrics: Int) -> UNMutableNotificationContent {
            if weeklyMetrics > 0 {
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("Blocked Trackers Summary", comment: "")
                content.body = "\(NSLocalizedString("You blocked", comment: "Used in the sentence: You blocked 500 tracking attempts this week.")) \(weeklyMetrics) \(NSLocalizedString("tracking attempts this week. Tap to update to the newest block lists.", comment: "Used in the sentence: You blocked 500 tracking attempts this week. Tap to update to the newsst block lists."))"
                content.sound = .default
                return content
            } else {
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("Stay Protected", comment: "")
                content.body = NSLocalizedString("Tap to activate Lockdown Firewall and update to the newest block lists.", comment: "")
                content.sound = .default
                return content
            }
        }
        
        static func makeNotificationContentForOnboarding() -> UNMutableNotificationContent {
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("You've just blocked 100 tracking attempts!", comment: "")
            content.body = NSLocalizedString("Tap to see what they are.", comment: "Used in the paragraph: You've just blocked 100 tracking attempts! Tap to see what they are.")
            // No sound because the user will likely be using their phone
            // when they see this notification
            content.sound = .none
            return content
        }
    }
}

extension PushNotifications {
    
    enum SchedulingHelper {
        
        static let kAllowNotificationsAfterDate = "LockdownAllowNotificationsAfter"
        
        static func calculateAndSaveNotificationsAllowedAfterDate() {
            let now = Date()
            if isFridayOrSaturday(date: now) {
                let sunday = firstSunday(after: now)
                DDLogInfo("User allowed notifications on Friday/Saturday, so we will start scheduling notifications only on Sunday: \(sunday ?? .distantPast)")
                defaults.set(sunday, forKey: kAllowNotificationsAfterDate)
            } else {
                DDLogInfo("User allowed notifications on Sunday-Thursday, we will start scheduling notifications immediately")
                defaults.set(now, forKey: kAllowNotificationsAfterDate)
            }
        }
        
        static func upcomingWeeklyUpdateDateComponents() -> DateComponents? {
            guard let notificationsAllowedAfter = self.notificationsAllowedAfter() else {
                // notifications are likely not authorized
                DDLogError("No 'notifications allowed after date' is stored. It likely means that the user did not authorize the use of notifications")
                return nil
            }
            
            let now = Date()
            
            guard now > notificationsAllowedAfter else {
                // weekly updates did not go into action yet, so not counting this
                DDLogInfo("Not scheduling because notifications are not allowed yet (probably will be allowed on Sunday)")
                return nil
            }
            
            if let saturday = firstSaturday(after: now) {
                return dateComponents(from: saturday)
            } else {
                return nil
            }
        }
        
        static private func notificationsAllowedAfter() -> Date? {
            return defaults.object(forKey: kAllowNotificationsAfterDate) as? Date
        }
        
        static private func isFridayOrSaturday(date: Date) -> Bool {
            let gregorian = Calendar(identifier: .gregorian)
            let weekday = gregorian.component(.weekday, from: date)
            return weekday == 6 || weekday == 7
        }
        
        static private func firstSaturday(after date: Date) -> Date? {
            let gregorian = Calendar(identifier: .gregorian)
            
            var saturday3Pm = DateComponents()
            saturday3Pm.weekday = 7
            saturday3Pm.hour = 15
            saturday3Pm.minute = 0
            saturday3Pm.second = 0
            
            guard let date = gregorian.nextDate(after: date, matching: saturday3Pm, matchingPolicy: .nextTime) else {
                return nil
            }
            
            return date
        }
        
        static private func firstSunday(after date: Date) -> Date? {
            let gregorian = Calendar(identifier: .gregorian)
            
            var sunday3Am = DateComponents()
            sunday3Am.weekday = 1
            sunday3Am.hour = 3
            sunday3Am.minute = 0
            sunday3Am.second = 0
            
            guard let date = gregorian.nextDate(after: date, matching: sunday3Am, matchingPolicy: .nextTime) else {
                return nil
            }
            
            return date
        }
        
        static private func dateComponents(from date: Date) -> DateComponents {
            return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .weekOfYear], from: date)
        }
    }
}

extension PushNotifications {
    
    final class EnergySaving {
        
        private var requestCounter: Int {
            get {
                return defaults.integer(forKey: "LockdownNotificationsEnergySavingCounter")
            }
            set {
                defaults.set(newValue, forKey: "LockdownNotificationsEnergySavingCounter")
            }
        }
        
        func rescheduleRequestDidArrive() {
            requestCounter += 1
        }
        
        func willScheduleNotification() {
            requestCounter = 0
        }
        
        func isAllowedToReschedule() -> Bool {
            if requestCounter >= 40 {
                return true
            }
            return false
        }
    }
    
}
