//
//  PaywallService.swift
//  LockdowniOS
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import CocoaLumberjackSwift
import StoreKit
import UIKit

protocol PaywallService: AnyObject {
    var context: PaywallContext { get set }
    
    func showPaywall(on vc: UIViewController, forceSpecialOffer: Bool)
    
    func showRedemptionSheet()
}

final class BasePaywallService: PaywallService {
    
    var context: PaywallContext = .normal
    
    var countdownDisplayService: CountdownDisplayService = BaseCountdownDisplayService.shared
    
    static let shared = BasePaywallService()
    
    private init() {}
    
    func showPaywall(on vc: UIViewController, forceSpecialOffer: Bool = false) {
        defer {
            UserDefaults.lastPaywallDisplayDate = Date()
        }
//            let paywall = TablePaywallViewController()
//            paywall.modalPresentationStyle = .formSheet
            
//            if let delegate = vc as? PaywallViewControllerCloseDelegate {
//                paywall.delegate = delegate
//            }
//            
//            vc.definesPresentationContext = true
//            vc.present(paywall, animated: true) {
//                vc.definesPresentationContext = false
//            }
        
    }
    
    func showRedemptionSheet() {
        guard #available(iOS 14.0, *) else { return }
        SKPaymentQueue.default().presentCodeRedemptionSheet()
        context = .redeemOfferCode
        DDLogInfo("Showing redemption sheet, changing context to \(context)")
    }
}

extension BasePaywallService: CountdownDisplayDelegate {
    func didFinishCountdown() {
        countdownDisplayService.pauseUpdating()
        context = .normal
    }
}

extension BasePaywallService: Keychainable {}

enum PaywallContext {
    /// The context that shows a normal paywall without LTO discounts.
    case normal
    
    /// The context that shows an LTO paywall with a holiday discount
    /// Only after an ordinary paywall has been closed.
    case followUpLimitedTimeOffer
    
    /// When user is in the process of code redemption after calling presentCodeRedemptionSheet() method.
    case redeemOfferCode
}

