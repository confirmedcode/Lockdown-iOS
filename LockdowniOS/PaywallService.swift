//
//  PaywallService.swift
//  LockdowniOS
//
//  Created by Alexander Parshakov on 12/16/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
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
        
        // We show special offer only if all these conditions work:
        // 1. We closed the main paywall just now OR want to force-show the special offer,
        // 2. Today's date is within special offer period by optionally initializing it.
        if context == .followUpLimitedTimeOffer || forceSpecialOffer, let specialOffer = LimitedTimeOffer() {
            DDLogInfo("Preparing to show special offer named: \(specialOffer)")
            switch specialOffer {
            case .xmas:
                let christmasPaywallViewController = ChristmasPaywallViewController(countdownDisplayService: countdownDisplayService)
                if let delegate = vc as? LTOViewControllerCloseDelegate {
                    christmasPaywallViewController.delegate = delegate
                }
                christmasPaywallViewController.modalPresentationStyle = .overFullScreen
                vc.present(christmasPaywallViewController, animated: true)
                DDLogInfo("Showing LTO screen from: \(String(describing: type(of: vc)))")
            default:
                break
            }
            countdownDisplayService.delegates.append(WeakObject(self))
        } else {
            let paywall = TablePaywallViewController()
            paywall.modalPresentationStyle = vc.isPad ? .pageSheet : .overFullScreen
            
            if let delegate = vc as? PaywallViewControllerCloseDelegate {
                paywall.delegate = delegate
            }
            
            vc.definesPresentationContext = true
            vc.present(paywall, animated: true) {
                vc.definesPresentationContext = false
            }
        }
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

enum LimitedTimeOffer {
    case halloween, thanksgiving, xmas
    
    init?(for date: Date = Date()) {
        let currentDate = Date.from(year: Calendar.current.component(.year, from: Date()),
                                   month: Calendar.current.component(.month, from: Date()),
                                   day: Calendar.current.component(.day, from: Date()))
        if (.xmasStart ... .xmasEnd).contains(currentDate) {
            self = .xmas
        } else if (.halloweenStart ... .halloweenEnd).contains(currentDate) {
            self = .halloween
        } else if (.thanksgivingStart ... .thanksgivingEnd).contains(currentDate) {
            self = .thanksgiving
        } else {
            return nil
        }
    }
}
