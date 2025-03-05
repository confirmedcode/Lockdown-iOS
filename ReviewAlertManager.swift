//
//  ReviewAlertManager.swift
//  LockdowniOS
//
//  Created by George Apostu on 5/3/25.
//  Copyright © 2025 Confirmed Inc. All rights reserved.
//

import Foundation
import StoreKit

class ReviewAlertManager {
    // UserDefaults keys
    private enum Keys {
        static let alertCount = "ReviewAlertCount"
        static let lastAlertDate = "LastReviewAlertDate"
        static let firstAlertDate = "FirstReviewAlertDate"
    }
    
    private let userDefaults: UserDefaults
    
    // Initialize with optional custom UserDefaults for testing
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // Check if we should show the review alert
    func shouldShowReviewAlert() -> Bool {
        let alertCount = userDefaults.integer(forKey: Keys.alertCount)
        let lastAlertDate = userDefaults.object(forKey: Keys.lastAlertDate) as? Date
        let firstAlertDate = userDefaults.object(forKey: Keys.firstAlertDate) as? Date
        
        // Check 365-day limit from first alert
        if let firstDate = firstAlertDate,
           Date().timeIntervalSince(firstDate) >= 365 * 24 * 60 * 60 {
            return true // Allow reset after 1 year
        }
        
        // Maximum 3 alerts per year
//        if alertCount >= 3 {
//            return false
//        }
        
        // First alert (onboarding)
        if alertCount == 0 {
            return true
        }
        
        guard let lastDate = lastAlertDate else {
            return false
        }
        
        let timeSinceLastAlert = Date().timeIntervalSince(lastDate)
        let hoursSinceLastAlert = timeSinceLastAlert / 3600
        let daysSinceLastAlert = timeSinceLastAlert / (24 * 3600)
        
        switch alertCount {
        case 1: // Alert #2 - 3 hours after #1
            return hoursSinceLastAlert >= 3
            
        case 2: // Alert #3 - 2 days after #2
            return daysSinceLastAlert >= 2
            
        default:
            // For any alert after the yearly reset
            return daysSinceLastAlert >= 2
        }
    }
    
    // Show review alert and update tracking data
    func showReviewAlert(delay: TimeInterval = 0.1) {
        guard shouldShowReviewAlert() else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            guard shouldShowReviewAlert() else { return }
            guard let topController = UIApplication.getTopMostViewController(), !topController.description.localizedCaseInsensitiveContains("paywall") else { return }
            
            var alertCount = userDefaults.integer(forKey: Keys.alertCount)
            let now = Date()
            
            // Handle yearly reset
            if let firstDate = userDefaults.object(forKey: Keys.firstAlertDate) as? Date,
               now.timeIntervalSince(firstDate) >= 365 * 24 * 60 * 60 {
                alertCount = 0
                userDefaults.removeObject(forKey: Keys.firstAlertDate)
            }
            
            // Show the StoreKit review prompt
            if let windowScene = UIApplication.shared.windows.first?.windowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
            
            // Update tracking data
            alertCount += 1
            userDefaults.set(alertCount, forKey: Keys.alertCount)
            userDefaults.set(now, forKey: Keys.lastAlertDate)
            
            if alertCount == 1 {
                userDefaults.set(now, forKey: Keys.firstAlertDate)
            }
        }
    }
    
    // For testing purposes - reset all data
    func reset() {
        userDefaults.removeObject(forKey: Keys.alertCount)
        userDefaults.removeObject(forKey: Keys.lastAlertDate)
        userDefaults.removeObject(forKey: Keys.firstAlertDate)
    }
}

// Usage example:
extension ReviewAlertManager {
    static let shared = ReviewAlertManager()
    
    // Call this during onboarding
    static func showOnboardingAlert() {
        shared.showReviewAlert(delay: 0.1)
    }
    
    // Call this when app opens
    static func checkAndShowAlert() {
        shared.showReviewAlert(delay: 5.0)
    }
}
