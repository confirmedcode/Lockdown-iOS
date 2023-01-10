//
//  ChristmasPaywallViewController.swift
//  LockdowniOS
//
//  Created by Alexander Parshakov on 12/14/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import CocoaLumberjackSwift
import UIKit

protocol LTOViewControllerCloseDelegate: AnyObject {
    func didCloseLTOPaywall()
}

final class ChristmasPaywallViewController: BaseViewController {
    
    @IBOutlet private var timerContainer: UIStackView!
    @IBOutlet private var minutesCountLabel: UILabel!
    @IBOutlet private var minutesTitleLabel: UILabel!
    @IBOutlet private var secondsCountLabel: UILabel!
    @IBOutlet private var secondsTitleLabel: UILabel!
    
    @IBOutlet private var offerTitleLabel: UILabel!
    @IBOutlet private var discountMagnitudeLabel: UILabel!
    @IBOutlet private var fromPriceLabel: UILabel!
    @IBOutlet private var toPriceLabel: UILabel!
    
    @IBOutlet private var termsOfServiceButton: UIButton!
    @IBOutlet private var privacyPolicyButton: UIButton!
    
    @IBOutlet private var subscribeButton: UIButton!
    
    private let countdownDisplayService: CountdownDisplayService
    
    weak var delegate: LTOViewControllerCloseDelegate?
    
    init(countdownDisplayService: CountdownDisplayService) {
        self.countdownDisplayService = countdownDisplayService
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        countdownDisplayService.delegates.append(WeakObject(self))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        countdownDisplayService.startUpdating(hourLabel: nil, minuteLabel: minutesCountLabel, secondLabel: secondsCountLabel)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate?.didCloseLTOPaywall()
    }
    
    @IBAction private func didTapClose(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction private func didTapTermsOfService(_ sender: Any) {
        DDLogInfo("Tapped on LTO Terms of Service. Stopping timer.")
        countdownDisplayService.pauseUpdating()
        showModalWebView(title: .localized("terms_of_service"), urlString: .lockdownUrlTerms, delegate: self)
    }
    
    @IBAction private func didTapPrivacyPolicy(_ sender: Any) {
        DDLogInfo("Tapped on LTO Privacy Policy. Stopping timer.")
        countdownDisplayService.pauseUpdating()
        showModalWebView(title: .localized("Privacy Policy"), urlString: .lockdownUrlPrivacy, delegate: self)
    }
    
    @IBAction private func didTapSubscribe(_ sender: Any) {
        DDLogInfo("Tapped on LTO Subscribe. Stopping timer, sending purchase request...")
        countdownDisplayService.pauseUpdating()
        subscribeButton.showAnimatedPress(duration: 0.15, withScale: 1.05) { [weak self] in
            self?.purchaseProduct(withId: VPNSubscription.productIdAnnualProLTO) {
                self?.dismiss(animated: true) {
                    self?.countdownDisplayService.stopAndRemoveLTO()
                }
            } onFailure: {
                guard let self else { return }
                self.countdownDisplayService.startUpdating(hourLabel: nil, minuteLabel: self.minutesCountLabel, secondLabel: self.secondsCountLabel)
            }

        }
    }
    
    private func setupUI() {
        setupButtons()
        setupTexts()
        updatePrices()
    }
    
    private func setupButtons() {
        let attributedPrivacyPolicyTitle = NSAttributedString(string: .localized("Privacy Policy"),
                                                              attributes: [.font: UIFont.mediumLockdownFont(size: 12),
                                                                           .underlineStyle: NSUnderlineStyle.single.rawValue])
        privacyPolicyButton.setAttributedTitle(attributedPrivacyPolicyTitle, for: .normal)
        privacyPolicyButton.titleLabel?.textAlignment = .center
        
        let attributedTermsOfServiceTitle = NSAttributedString(string: .localized("terms_of_service"),
                                                              attributes: [.font: UIFont.mediumLockdownFont(size: 12),
                                                                           .underlineStyle: NSUnderlineStyle.single.rawValue])
        termsOfServiceButton.setAttributedTitle(attributedTermsOfServiceTitle, for: .normal)
        termsOfServiceButton.titleLabel?.textAlignment = .center
        
        subscribeButton.corners = .continuous(16)
    }
    
    private func setupTexts() {
        minutesTitleLabel.text = .localized("minutes_genitive")
        secondsTitleLabel.text = .localized("seconds_genitive")
        
        offerTitleLabel.text = .localized("lockdowns_first_christmas_sale")
        subscribeButton.setTitle(.localized("subscribe_now"), for: .normal)
    }
    
    private func updatePrices() {
        var fromPriceText = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnualPro, for: .new)
        if fromPriceText.contains("/" + .localized("year_after_slash")) {
            fromPriceText = fromPriceText.replacingOccurrences(of: "/" + .localized("year_after_slash"), with: "")
        }
        let attributedFromPriceText = NSAttributedString(
            string: fromPriceText,
            attributes: [.strikethroughStyle: NSUnderlineStyle.thick.rawValue]
        )
        fromPriceLabel.attributedText = attributedFromPriceText
        toPriceLabel.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnualProLTO, for: .new)
    }
}

extension ChristmasPaywallViewController: WebViewViewControllerDelegate {
    func webViewDidDisappear() {
        countdownDisplayService.startUpdating(hourLabel: nil, minuteLabel: minutesCountLabel, secondLabel: secondsCountLabel)
    }
}

extension ChristmasPaywallViewController: CountdownDisplayDelegate {
    func didFinishCountdown() {
        delegate = nil
        dismiss(animated: true)
    }
}

extension ChristmasPaywallViewController: ProductPurchasable {}
