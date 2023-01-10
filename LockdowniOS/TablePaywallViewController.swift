//
//  TablePaywallViewController.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 8/29/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
//

import CocoaLumberjackSwift
import Foundation
import PromiseKit
import StoreKit
import UIKit

protocol PaywallViewControllerCloseDelegate: AnyObject {
    func didClosePaywall()
}

final class TablePaywallViewController: BaseViewController, Loadable {
    
    @IBOutlet private var restorePurchaseLabel: UILabel!
    
    @IBOutlet private var titleLabel: UILabel!
    
    @IBOutlet private var featureStackView: UIStackView!
    
    @IBOutlet private var chooseYourPlanLabel: UILabel!
    @IBOutlet private var segmentedControl: UISegmentedControl!
    
    @IBOutlet private var annualOfferView: UIView!
    @IBOutlet private var annualOfferTitleLabel: UILabel!
    @IBOutlet private var annualOfferSubtitleLabel: UILabel!
    @IBOutlet private var saveMoneyContainerView: UIView!
    @IBOutlet private var saveMoneyLabel: UILabel!
    
    @IBOutlet private var monthlyOfferView: UIView!
    @IBOutlet private var monthlyOfferTitleLabel: UILabel!
    @IBOutlet private var monthlyOfferSubtitleLabel: UILabel!
    
    @IBOutlet private var shadowView: UIView!
    @IBOutlet private var continueButton: UIButton!
    @IBOutlet private var privacyPolicyLabel: UILabel!
    @IBOutlet private var redeemCodeLabel: UILabel!
    @IBOutlet private var termsOfServiceLabel: UILabel!
    
    @IBOutlet private var offerStackViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    private var annualOfferGestureRecognizer: UITapGestureRecognizer?
    private var monthlyOfferGestureRecognizer: UITapGestureRecognizer?
    
    private var continueButtonGradientLayer: CAGradientLayer?
    
    private let paywallTableFeatures: [PaywallTableFeature]
    private let existingSubscription: Subscription?
    private let paywallService: PaywallService
    
    weak var delegate: PaywallViewControllerCloseDelegate?
    
    private var currentGroup: AppStoreProductGroup = .pro {
        didSet {
            updateScreenState()
        }
    }
    private var currentPeriod: SubscriptionOfferPeriodUnit = .year {
        didSet {
            updateScreenState()
        }
    }
    
    init(paywallTableFeatures: [PaywallTableFeature] = .allDefaultFeatures,
         existingSubscription: Subscription? = BaseUserService.shared.user.currentSubscription,
         paywallService: PaywallService = BasePaywallService.shared) {
        self.paywallTableFeatures = paywallTableFeatures
        self.existingSubscription = existingSubscription
        self.paywallService = paywallService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        VPNSubscription.cacheLocalizedPrices()
        
        setupUI()
        updateScreenState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        saveMoneyContainerView.corners = .continuous(saveMoneyContainerView.bounds.midY)
        
        continueButton.applyGradient(.lightBlue, corners: .continuous(continueButton.bounds.midY))
    }
    
    deinit {
        delegate?.didClosePaywall()
        
        if UserDefaults.hasSeenLTO == false {
            paywallService.context = .followUpLimitedTimeOffer
        }
    }
    
    @IBAction private func didTapClose(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction private func didSelectSegment(_ sender: Any) {
        currentGroup = segmentedControl.selectedSegmentIndex == 0 ? .firewallAndVpn : .pro
        updateScreenState()
    }
    
    @IBAction private func didTapContinue(_ sender: Any) {
        continueButton.showAnimatedPress { [weak self] in
            self?.updateChosenOffer()
            self?.purchaseProduct()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        setupTexts()
        updateFeatureStackView()
        setupSegmentedControl()
        updateOfferViews()
        setupShadowFromContinue()
        updateViewsForIpad()
        setupGestureRecognizers()
    }
    
    private func updateFeatureStackView() {
        featureStackView.spacing = isPad ? 6 : 3
        featureStackView.clear()
        
        featureStackView.addArrangedSubview(TablePaywallHeaderView.make())
        
        paywallTableFeatures.forEach {
            featureStackView.addArrangedSubview(Separator(height: isPad ? 2 : 1))
            
            let rowView = TablePaywallFeatureRowView.make(feature: $0, isHighlighted: currentGroup.hasFeature($0))
            featureStackView.addArrangedSubview(rowView)
        }
    }
    
    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = currentGroup == .firewallAndVpn ? 0 : 1
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.boldLockdownFont(size: 15)], for: .selected)
            segmentedControl.setTitleTextAttributes([.font: UIFont.mediumLockdownFont(size: 16)], for: .normal)
        } else {
            segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.boldLockdownFont(size: 13)], for: .selected)
            segmentedControl.setTitleTextAttributes([.font: UIFont.mediumLockdownFont(size: 13)], for: .normal)
        }
        
        segmentedControl.setTitle("VPN", forSegmentAt: 0)
        segmentedControl.setTitle("PRO", forSegmentAt: 1)
    }
    
    private func setupTexts() {
        restorePurchaseLabel.text = .localized("restore_purchase")
        
        titleLabel.text = .localized("start_trial_now_to_get_full_access")
        chooseYourPlanLabel.text = .localized("CHOOSE_YOUR_PLAN")
        
        annualOfferTitleLabel.text = .localized("plan_annual")
        monthlyOfferTitleLabel.text = .localized("plan_monthly")
        
        continueButton.setTitle(.localized("continue"), for: .normal)
        
        privacyPolicyLabel.text = .localized("Privacy Policy")
        if #available(iOS 14.0, *) {
            redeemCodeLabel.isHidden = false
            redeemCodeLabel.text = .localized("redeem_code")
        }
        termsOfServiceLabel.text = .localized("terms_of_service")
        
        updateSaveMoneyLabel()
    }
    
    private func updateSaveMoneyLabel() {
        saveMoneyContainerView.isHidden = false
        let localizationKey = currentGroup == .firewallAndVpn ? "save_annual_vpn_subscription" : "save_annual_pro_subscription"
        saveMoneyLabel.text = .localized(localizationKey)
    }
    
    private func updateOfferViews() {
        [annualOfferView, monthlyOfferView].forEach { $0?.recolorToDefault() }
        
        [annualOfferTitleLabel, annualOfferSubtitleLabel, monthlyOfferTitleLabel, monthlyOfferSubtitleLabel].forEach {
            $0?.textColor = .confirmedBlue
        }
        
        // Highlighting the view for currently selected period
        let currentOfferView = currentPeriod == .year ? annualOfferView : monthlyOfferView
        let currentTitleLabel = currentPeriod == .year ? annualOfferTitleLabel : monthlyOfferTitleLabel
        let currentSubtitleLabel = currentPeriod == .year ? annualOfferSubtitleLabel : monthlyOfferSubtitleLabel

        currentOfferView?.backgroundColor = .confirmedBlue
        currentTitleLabel?.textColor = .white
        currentSubtitleLabel?.textColor = .white
    }
    
    private func setupShadowFromContinue() {
        shadowView.layer.shadowColor = UIColor.systemBackground.cgColor
        shadowView.layer.masksToBounds = false
        shadowView.layer.shadowOffset = CGSize(width: 0, height : -20)
        shadowView.layer.shadowPath = UIBezierPath(rect: shadowView.bounds).cgPath
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowRadius = 25
    }
    
    private func updateViewsForIpad() {
        guard UIScreen.main.traitCollection.userInterfaceIdiom == .pad else { return }
        
        restorePurchaseLabel.font = restorePurchaseLabel.font.withSize(16)
        chooseYourPlanLabel.font = chooseYourPlanLabel.font.withSize(24)
        
        annualOfferTitleLabel.font = annualOfferTitleLabel.font.withSize(20)
        annualOfferSubtitleLabel.font = annualOfferSubtitleLabel.font.withSize(18)
        saveMoneyLabel.font = saveMoneyLabel.font.withSize(17)
        monthlyOfferTitleLabel.font = monthlyOfferTitleLabel.font.withSize(20)
        monthlyOfferSubtitleLabel.font = monthlyOfferSubtitleLabel.font.withSize(18)
        
        privacyPolicyLabel.font = privacyPolicyLabel.font.withSize(16)
        redeemCodeLabel.font = redeemCodeLabel.font.withSize(16)
        termsOfServiceLabel.font = termsOfServiceLabel.font.withSize(16)
        
        scrollViewBottomConstraint.constant = 20
        offerStackViewBottomConstraint.constant = 50
    }
    
    private func setupGestureRecognizers() {
        let restorePurchaseTap = UITapGestureRecognizer(target: self, action: #selector(restorePurchase))
        restorePurchaseLabel.isUserInteractionEnabled = true
        restorePurchaseLabel.addGestureRecognizer(restorePurchaseTap)
        
        let annualTap = UITapGestureRecognizer(target: self, action: #selector(choseAnnualOffer))
        annualOfferView.addGestureRecognizer(annualTap)
        annualOfferGestureRecognizer = annualTap
        
        let monthlyTap = UITapGestureRecognizer(target: self, action: #selector(choseMonthlyOffer))
        monthlyOfferView.addGestureRecognizer(monthlyTap)
        monthlyOfferGestureRecognizer = monthlyTap
        
        let privacyPolicyTap = UITapGestureRecognizer(target: self, action: #selector(showPrivacyPolicy))
        privacyPolicyLabel.isUserInteractionEnabled = true
        privacyPolicyLabel.addGestureRecognizer(privacyPolicyTap)
        
        let redeemCodeTap = UITapGestureRecognizer(target: self, action: #selector(showRedeemCode))
        redeemCodeLabel.isUserInteractionEnabled = true
        redeemCodeLabel.addGestureRecognizer(redeemCodeTap)
        
        let termsOfServiceTap = UITapGestureRecognizer(target: self, action: #selector(showTermsOfService))
        termsOfServiceLabel.isUserInteractionEnabled = true
        termsOfServiceLabel.addGestureRecognizer(termsOfServiceTap)
    }
    
    @objc private func choseAnnualOffer() {
        currentPeriod = .year
    }
    
    @objc private func choseMonthlyOffer() {
        currentPeriod = .month
    }
    
    @objc private func showPrivacyPolicy() {
        showModalWebView(title: .localized("Privacy Policy"), urlString: .lockdownUrlPrivacy)
    }
    
    @objc private func showRedeemCode() {
        paywallService.showRedemptionSheet()
    }
    
    @objc private func showTermsOfService() {
        showModalWebView(title: .localized("terms_of_service"), urlString: .lockdownUrlTerms)
    }
    
    private func updateScreenState() {
        // If period and group of existing subscription (plan) are selected,
        // we must force-select the period of the other plan.
        if existingSubscription?.isSubscription(in: currentGroup, of: currentPeriod) == true {
            currentPeriod = currentPeriod == .year ? .month : .year
        }
        
        updateFeatureStackView()
        updateSaveMoneyLabel()
        updateOfferViews()
        updatePriceSubtitles()
        
        annualOfferGestureRecognizer?.isEnabled = true
        monthlyOfferGestureRecognizer?.isEnabled = true
        
        guard let existingSubscription, existingSubscription.correspondingProductGroup == currentGroup else { return }
        
        let isAnnual = [.proAnnual, .annual, .proAnnualLTO].contains(existingSubscription.planType)
        
        // If existing subscription is annual, no need to show the save-label.
        saveMoneyContainerView.isHidden = isAnnual
        
        let offerView = isAnnual ? annualOfferView : monthlyOfferView
        let subtitleLabel = isAnnual ? annualOfferSubtitleLabel : monthlyOfferSubtitleLabel
        let gestureRecognizer = isAnnual ? annualOfferGestureRecognizer : monthlyOfferGestureRecognizer
        
        offerView?.layer.borderWidth = 0
        subtitleLabel?.text = .localized("current_plan")
        gestureRecognizer?.isEnabled = false
    }
    
    private func updateChosenOffer() {
        switch currentGroup {
        case .firewallAndVpn:
            if currentPeriod == .year {
                VPNSubscription.selectedProductId = VPNSubscription.productIdAnnual
            } else {
                VPNSubscription.selectedProductId = VPNSubscription.productIdMonthly
            }
        case .pro:
            if currentPeriod == .year {
                VPNSubscription.selectedProductId = VPNSubscription.productIdAnnualPro
            } else {
                VPNSubscription.selectedProductId = VPNSubscription.productIdMonthlyPro
            }
        }
    }
    
    private func updatePriceSubtitles() {
        switch currentGroup {
        case .firewallAndVpn:
            monthlyOfferSubtitleLabel.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthly, for: .new)
            annualOfferSubtitleLabel.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnual, for: .new)
        case .pro:
            monthlyOfferSubtitleLabel.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthlyPro, for: .new)
            annualOfferSubtitleLabel.text = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnualPro, for: .new)
        }
    }
}

extension TablePaywallViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        shadowView.layer.shadowColor = UIColor.systemBackground.cgColor
    }
}

// MARK: - Purchase and Restore

extension TablePaywallViewController: ProductPurchasable {
    @objc private func restorePurchase() {
        restorePurchases()
    }
}

private extension UIView {
    func recolorToDefault() {
        corners = .continuous(10)
        layer.borderWidth = 2
        layer.borderColor = UIColor.confirmedBlue.cgColor
        
        backgroundColor = .systemBackground
    }
}
