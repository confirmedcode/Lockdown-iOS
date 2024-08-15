//
//  AdvancedWallViewController.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 25.04.2023.
//

import UIKit
import NetworkExtension
import PromiseKit
import CocoaLumberjackSwift
import StoreKit

protocol VPNPaywallViewControllerCloseDelegate: AnyObject {
    func didClosePaywall()
}

final class VPNPaywallViewController: BaseViewController, Loadable {
    private enum Tab {
        case advanced
        case anonymous
        case universal
    }
    
    let shared: UserService = BaseUserService.shared
        
    var parentVC: UIViewController?
    
    enum Mode {
        case newSubscription
        case upgrade(active: [Subscription.PlanType])
    }
    
    var mode = Mode.newSubscription
    
    weak var delegate: VPNPaywallViewControllerCloseDelegate?
    var purchaseSuccessful: (()->Void)?
    var purchaseFailed: ((Error)->Void)?
    
    private var selectedTab = Tab.advanced {
        didSet {
            updateTabs()
        }
    }

    private var needScrolToUniversal = false
    
    //MARK: Properties
    private var titleName = NSLocalizedString("Lockdown", comment: "")
    
    //MARK: navigation
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.rightNavButton.setTitle(NSLocalizedString("RESTORE", comment: ""), for: .normal)
        view.titleLabel.text = NSLocalizedString(titleName, comment: "")
        view.leftNavButton.setTitle(NSLocalizedString("CLOSE", comment: ""), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        view.rightNavButton.addTarget(self, action: #selector(restorePurchase), for: .touchUpInside)
        return view
    }()
    
    //MARK: horizontal scroll menu
    private lazy var hScrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        return view
    }()
    
    private lazy var advancedPlan: PlanView = {
        let view = PlanView()
        view.title.text = "Advanced"
        view.isUserInteractionEnabled = true
        
        view.setOnClickListener { [unowned self] in
            self.selectedTab = .advanced
        }
        return view
    }()
    
    private lazy var anonymousPlan: PlanView = {
        let view = PlanView()
        view.title.text = "Anonymous"
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [unowned self] in
            selectedTab = .anonymous
        }
        return view
    }()
    
    private lazy var universalPlan: PlanView = {
        let view = PlanView()
        view.title.text = "Universal"
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [unowned self] in
            selectedTab = .universal
        }
        return view
    }()
    
    private lazy var plansStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.addArrangedSubview(advancedPlan)
        stack.addArrangedSubview(anonymousPlan)
        stack.addArrangedSubview(universalPlan)
        stack.alignment = .leading
        stack.distribution = .equalSpacing
        stack.spacing = 16
        return stack
    }()
    
    lazy var advancedView: PaywallView = {
        let view = PaywallView(model: .advancedDetails())
        view.topProduct.setOnClickListener { [unowned self] in
            selectAdvancedYearly()
            selectYearlyProduct(view, model: .advancedDetails())
        }
        view.bottomProduct.setOnClickListener { [unowned self] in
            selectAdvancedMonthly()
            selectMontlyProduct(view, model: .advancedDetails())
        }

        view.actionButton.setOnClickListener { [unowned self] in
            startTrial()
        }
        return view
    }()
    

    
    lazy var anonymousView: PaywallView = {
        let view = PaywallView(model: .anonymousDetails())
        view.isHidden = true
        view.topProduct.setOnClickListener { [unowned self] in
            selectAnonymousYearly()
            selectYearlyProduct(view, model: .anonymousDetails())
        }
        view.bottomProduct.setOnClickListener { [unowned self] in
            selectAnonymousMonthly()
            selectMontlyProduct(view, model: .anonymousDetails())
        }
        view.actionButton.setOnClickListener { [unowned self] in
            startTrial()
        }
        return view
    }()
    
    lazy var universalView: PaywallView = {
        let view = PaywallView(model: .universalDetails())
        view.isHidden = true
        view.topProduct.setOnClickListener { [unowned self] in
            selectUniversalYearly()
            selectYearlyProduct(view, model: .universalDetails())
        }
        view.bottomProduct.setOnClickListener { [unowned self] in
            selectUniversalMonthly()
            selectMontlyProduct(view, model: .universalDetails())
        }

        view.actionButton.setOnClickListener { [unowned self] in
            startTrial()
        }
        
        return view
    }()
    
    private func selectYearlyProduct(_ view: PaywallView, model: PaywallViewModel) {
        view.topProduct.setSelected(true)
        view.bottomProduct.setSelected(false)
        let anualPrice = VPNSubscription.getProductIdPrice(productId: model.annualProductId)
        let monthlyPrice = VPNSubscription.getProductIdPriceMonthly(productId: model.annualProductId)
        let trialDuation = VPNSubscription.trialDuration(productId: model.annualProductId) ?? ""
        let title = trialDuation + " " + NSLocalizedString("free trial", comment: "") + "," + " then \(anualPrice) (\(monthlyPrice)/mo)"
        view.trialDescriptionLabel.text = title
        view.trialDescriptionLabel.isHidden = VPNSubscription.trialDuration(productId: model.annualProductId) == nil
        view.updateCTATitle(for: model.annualProductId)
    }
    
    private func selectMontlyProduct(_ view: PaywallView, model: PaywallViewModel) {
        view.bottomProduct.setSelected(true)
        view.topProduct.setSelected(false)
        let monthlyPrice = VPNSubscription.getProductIdPrice(productId: model.mounthProductId)
        let trialDuation = VPNSubscription.trialDuration(productId: model.annualProductId) ?? ""
        let title = trialDuation + " " + NSLocalizedString("free trial", comment: "") + "," + " then \(monthlyPrice)/mo"
        view.trialDescriptionLabel.text = title
        view.trialDescriptionLabel.isHidden = VPNSubscription.trialDuration(productId: model.mounthProductId) == nil
        view.updateCTATitle(for: model.mounthProductId)
    }
    
    private lazy var privacyLabel: UILabel = {
        let label = UILabel()
          label.font = fontMedium11
          label.textAlignment = .center
          label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: NSLocalizedString("By continuing you agree with our ", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.smallGrey])
        let termsRange = NSRange(location: attributedText.length, length: NSLocalizedString("Terms of Service", comment: "").count)
        attributedText.append(NSAttributedString(string: NSLocalizedString("Terms of Service", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.white]))
        attributedText.append(NSAttributedString(string: NSLocalizedString(" and ", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.smallGrey]))
        let privacyRange = NSRange(location: attributedText.length, length: NSLocalizedString("Privacy Policy", comment: "").count)
        attributedText.append(NSAttributedString(string: NSLocalizedString("\nPrivacy Policy", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.white]))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedText.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: attributedText.length))
        label.attributedText = attributedText
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(sender:)))
        label.addGestureRecognizer(tapGesture)
        return label
      }()

    //MARK: Lificycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .paywallNew
        configureUI()
        updateCurrentSelectedTab()
        updateTabs()
        updateVisibleTabs()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if needScrolToUniversal {
            scrollToRightTabs()
            needScrolToUniversal = false
        }
    }
    
    //MARK: ConfigureUI
    private func configureUI() {
        view.addSubview(navigationView)
        navigationView.anchors.top.safeAreaPin(inset: 18)
        navigationView.anchors.leading.marginsPin()
        navigationView.anchors.trailing.marginsPin()
        
        view.addSubview(hScrollView)
        hScrollView.anchors.top.spacing(24, to: navigationView.anchors.bottom)
        hScrollView.anchors.leading.pin(inset: 16)
        hScrollView.anchors.trailing.pin()
        hScrollView.anchors.height.equal(60)
        hScrollView.showsHorizontalScrollIndicator = false
        
        hScrollView.addSubview(plansStack)
        plansStack.anchors.top.marginsPin()
        plansStack.anchors.leading.equal(hScrollView.anchors.leading)
        plansStack.anchors.trailing.equal(hScrollView.anchors.trailing)
        plansStack.anchors.height.equal(hScrollView.anchors.height)
        
        view.addSubview(privacyLabel)
        privacyLabel.anchors.bottom.safeAreaPin()
        privacyLabel.anchors.leading.marginsPin()
        privacyLabel.anchors.trailing.marginsPin()
        privacyLabel.anchors.height.equal(36)
        
        view.addSubview(advancedView)
        advancedView.anchors.top.spacing(24, to: hScrollView.anchors.bottom)
        advancedView.anchors.leading.pin()
        advancedView.anchors.trailing.pin()
        advancedView.anchors.bottom.spacing(8, to: privacyLabel.anchors.top)
        
        view.addSubview(anonymousView)
        anonymousView.anchors.top.spacing(24, to: hScrollView.anchors.bottom)
        anonymousView.anchors.leading.pin()
        anonymousView.anchors.trailing.pin()
        anonymousView.anchors.bottom.spacing(8, to: privacyLabel.anchors.top)
        
        view.addSubview(universalView)
        universalView.anchors.top.spacing(24, to: hScrollView.anchors.bottom)
        universalView.anchors.leading.pin()
        universalView.anchors.trailing.pin()
        universalView.anchors.bottom.spacing(8, to: privacyLabel.anchors.top)
    }
    
    //MARK: Functions
    @objc func closeButtonClicked() {
        dismiss(animated: true)
    }
    
    @objc private func labelTapped(sender: UITapGestureRecognizer) {
        let termsRange = NSRange(location: privacyLabel.attributedText!.length - NSLocalizedString("Terms of Service", comment: "").count - 18, length: NSLocalizedString("Terms of Service", comment: "").count)
        let privacyRange = NSRange(location: privacyLabel.attributedText!.length - NSLocalizedString("Privacy Policy", comment: "").count, length: NSLocalizedString("Privacy Policy", comment: "").count)
        
        if sender.didTapAttributedTextInLabel(label: privacyLabel, inRange: privacyRange),
            let url = URL(string: "https://lockdownprivacy.com/privacy") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if sender.didTapAttributedTextInLabel(label: privacyLabel, inRange: termsRange),
            let url = URL(string: "https://lockdownprivacy.com/terms") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func disable(button: UIButton) {
        button.isEnabled = false
        button.backgroundColor = .lightGray
    }
    
    private func isDisabledPlan(_ plan: Subscription.PlanType) -> Bool {
        guard let subscription = shared.user.currentSubscription else {
            return false
        }
        let planOrder: [Subscription.PlanType] = [
            .advancedMonthly,
            .advancedAnnual,
            .anonymousMonthly,
            .anonymousAnnual,
            .universalMonthly,
            .universalAnnual
        ]
        guard let index = planOrder.firstIndex(of: plan),
            let currentIndex = planOrder.firstIndex(of: subscription.planType) else {
            return false
        }
        return index <= currentIndex
    }
    
    private func update(_ planView: PlanView, isSelected: Bool) {
        if isSelected {
            planView.iconImageView.image = UIImage(named: "fill-1")
            planView.backgroundView.layer.borderColor = UIColor.borderBlue.cgColor
        } else {
            planView.iconImageView.image = UIImage(named: "grey-ellipse-1")
            planView.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
        }
    }
    
    private func updateCurrentSelectedTab () {
        guard let plan = shared.user.currentSubscription?.planType else {
            selectedTab = .universal
            needScrolToUniversal = true
            return
        }
        if plan.isAdvanced {
            selectedTab = .advanced
        }
        if plan.isAnonymous {
            selectedTab = .anonymous
        }
        if plan.isUniversal {
            selectedTab = .universal
        }
    }
    
    private func scrollToRightTabs() {
        DispatchQueue.main.async {
            let offset = self.hScrollView.contentSize.width - self.hScrollView.frame.size.width
            self.hScrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        }
    }
    
    private func updateTabs() {
        switch selectedTab {
        case .advanced:
            selectAdvancedYearly()
        case .anonymous:
            selectAnonymousYearly()
        case .universal:
            selectUniversalYearly()
        }
        
        advancedView.isHidden = selectedTab != .advanced
        anonymousView.isHidden = selectedTab != .anonymous
        universalView.isHidden = selectedTab != .universal
        
        update(advancedPlan, isSelected: selectedTab == .advanced)
        update(anonymousPlan, isSelected: selectedTab == .anonymous)
        update(universalPlan, isSelected: selectedTab == .universal)
    }
    
    private func updateVisibleTabs() {
        guard let plan = shared.user.currentSubscription?.planType else {
            advancedPlan.isHidden = false
            anonymousPlan.isHidden = false
            universalPlan.isHidden = false
            return
        }
        if plan.isAdvanced {
            advancedPlan.isHidden = false
            anonymousPlan.isHidden = false
            universalPlan.isHidden = false
        }
        if plan.isAnonymous {
            advancedPlan.isHidden = true
        }
        if plan.isUniversal {
            advancedPlan.isHidden = true
            anonymousPlan.isHidden = true
        }
    }
}

extension VPNPaywallViewController: ProductPurchasable {
    
    @objc private func restorePurchase() {
        restorePurchases()
    }
    
    func selectAdvancedYearly() {
        VPNSubscription.selectedProductId = VPNSubscription.productIdAdvancedYearly
        updatePricingSubtitle()
    }
    
    func selectAdvancedMonthly() {
        VPNSubscription.selectedProductId = VPNSubscription.productIdAdvancedMonthly
        updatePricingSubtitle()
    }
    
    func selectAnonymousYearly() {
        VPNSubscription.selectedProductId = VPNSubscription.productIdAnnual
        updatePricingSubtitle()
    }
    
    func selectAnonymousMonthly() {
        VPNSubscription.selectedProductId = VPNSubscription.productIdMonthly
        updatePricingSubtitle()
    }
    
    func selectUniversalYearly() {
        VPNSubscription.selectedProductId = VPNSubscription.productIdAnnualPro
        updatePricingSubtitle()
    }
    
    func selectUniversalMonthly() {
        VPNSubscription.selectedProductId = VPNSubscription.productIdMonthlyPro
        updatePricingSubtitle()
    }
    
    func updatePricingSubtitle() {
        let context: VPNSubscription.SubscriptionContext = {
            switch mode {
            case .newSubscription:
                return .new
            case .upgrade:
                return .upgrade
            }
        }()
    }
    
    @objc func startTrial() {
        showLoadingView()
        VPNSubscription.purchase(
            succeeded: {
                self.dismiss(animated: true, completion: {
                    self.purchaseSuccessful?()
                })
            },
            errored: { error in
                self.hideLoadingView()
                self.purchaseFailed?(error)
        })
    }
}
