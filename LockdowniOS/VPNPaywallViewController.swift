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
    
    lazy var advancedView: AdvancedPaywallView = {
        let view = AdvancedPaywallView()
        if isDisabledPlan(.advancedMonthly) {
            disable(button: view.buyButton2)
        }
        if isDisabledPlan(.advancedAnnual) {
            disable(button: view.buyButton1)
        }
        view.buyButton1.setOnClickListener { [unowned self] in
            selectAdvancedYearly()
            startTrial()
        }
        view.buyButton2.setOnClickListener { [unowned self] in
            selectAdvancedMonthly()
            startTrial()
        }
        return view
    }()
    
    lazy var anonymousView: AnonymousPaywallView = {
        let view = AnonymousPaywallView()
        view.isHidden = true
        if isDisabledPlan(.anonymousMonthly) {
            disable(button: view.buyButton2)
        }
        if isDisabledPlan(.anonymousAnnual) {
            disable(button: view.buyButton1)
        }
        view.buyButton1.setOnClickListener { [unowned self] in
            selectAnonymousYearly()
            startTrial()
        }
        view.buyButton2.setOnClickListener { [unowned self] in
            selectAnonymousMonthly()
            startTrial()
        }
        return view
    }()
    
    lazy var universalView: UniversalPaywallView = {
        let view = UniversalPaywallView()
        view.isHidden = true
        if isDisabledPlan(.universalMonthly) {
            disable(button: view.buyButton2)
        }
        if isDisabledPlan(.universalAnnual) {
            disable(button: view.buyButton1)
        }
        view.buyButton1.setOnClickListener { [unowned self] in
            selectUniversalYearly()
            startTrial()
        }
        view.buyButton2.setOnClickListener { [unowned self] in
            selectUniversalMonthly()
            startTrial()
        }
        return view
    }()
    
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
        attributedText.append(NSAttributedString(string: NSLocalizedString("Privacy Policy", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.white]))

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
        
        if advancedView.isSelected {
            let monthlyPlanLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAdvancedMonthly, for: context)
            let annualPlanLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAdvancedMonthly, for: context)
        } else if anonymousView.isSelected {
            let monthlyPlanLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthly, for: context)
            let annualPlanLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnual, for: context)
        } else if universalView.isSelected {
            let monthlyPlanLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthlyPro, for: context)
            let annualPlanLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnualPro, for: context)
        }
    }
    
    @objc func startTrial() {
        showLoadingView()
        VPNSubscription.purchase(
            succeeded: {
                self.dismiss(animated: true, completion: {
                    
                    let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
                    let vc = SplashscreenViewController()
                    let navigation = UINavigationController(rootViewController: vc)
                    keyWindow?.rootViewController = navigation
                    
                    // force refresh receipt, and sync with email if it exists
                    if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
                        DDLogInfo("purchase complete: syncing with confirmed email")
                        firstly {
                            try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                        }
                        .then { (signin: SignIn) -> Promise<SubscriptionEvent> in
                            DDLogInfo("purchase complete: signin result: \(signin)")
                            return try Client.subscriptionEvent(forceRefresh: true)
                        }
                        .then { (result: SubscriptionEvent) -> Promise<[Subscription]> in
                            DDLogInfo("plan status: subscriptionevent result: \(result)")
                            return try Client.activeSubscriptions()
                        }
                        .done { subscriptions in
                            DDLogInfo("active-subs (start trial): \(subscriptions)")
                            NotificationCenter.default.post(name: AccountUI.accountStateDidChange, object: self)
                            
                            self.shared.user.updateSubscription(to: subscriptions.first)
                        }
                        .catch { error in
                            DDLogError("purchase complete: Error: \(error)")
                            if self.popupErrorAsNSURLError("Error activating Secure Tunnel: \(error)") {
                                return
                            } else if let apiError = error as? ApiError {
                                switch apiError.code {
                                default:
                                    _ = self.popupErrorAsApiError("API Error activating Secure Tunnel: \(error)")
                                }
                            }
                        }
                    } else {
                        firstly {
                            try Client.signIn()
                        }.then { _ in
                            try Client.activeSubscriptions()
                        }.done { subscriptions in
                            DDLogInfo("active-subs (start trial): \(subscriptions)")
                            NotificationCenter.default.post(name: AccountUI.accountStateDidChange, object: self)
                            
                            self.shared.user.updateSubscription(to: subscriptions.first)
                        }
                        .catch { error in
                            DDLogError("purchase complete - no email: Error: \(error)")
                            if self.popupErrorAsNSURLError("Error activating Secure Tunnel: \(error)") {
                                return
                            } else if let apiError = error as? ApiError {
                                switch apiError.code {
                                default:
                                    _ = self.popupErrorAsApiError("API Error activating Secure Tunnel: \(error)")
                                }
                            }
                        }
                    }
                })
            },
            errored: { error in
                self.hideLoadingView()
                let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
                let vc = SplashscreenViewController()
                let navigation = UINavigationController(rootViewController: vc)
                keyWindow?.rootViewController = navigation
                DDLogError("Start Trial Failed: \(error)")
                
                if let skError = error as? SKError {
                    var errorText = ""
                    switch skError.code {
                    case .unknown:
                        errorText = .localized("Unknown error. Please contact support at team@lockdownprivacy.com.")
                    case .clientInvalid:
                        errorText = .localized("Not allowed to make the payment")
                    case .paymentCancelled:
                        errorText = .localized("Payment was cancelled")
                    case .paymentInvalid:
                        errorText = .localized("The purchase identifier was invalid")
                    case .paymentNotAllowed:
                        errorText = .localized("""
Payment not allowed.\nEither this device is not allowed to make purchases, or In-App Purchases have been disabled. \
Please allow them in Settings App -> Screen Time -> Restrictions -> App Store -> In-app Purchases. Then try again.
""")
                    case .storeProductNotAvailable:
                        errorText = .localized("The product is not available in the current storefront")
                    case .cloudServicePermissionDenied:
                        errorText = .localized("Access to cloud service information is not allowed")
                    case .cloudServiceNetworkConnectionFailed:
                        errorText = .localized("Could not connect to the network")
                    case .cloudServiceRevoked:
                        errorText = .localized("User has revoked permission to use this cloud service")
                    default:
                        errorText = skError.localizedDescription
                    }
                    
                    self.showPopupDialog(title: .localized("Error Starting Trial"), message: errorText, acceptButton: .localizedOkay)
                }
                else if self.popupErrorAsNSURLError(error) {
                    return
                }
                else if self.popupErrorAsApiError(error) {
                    return
                }
                else {
                    self.showPopupDialog(
                        title: .localized("Error Starting Trial"),
                        message: .localized("Please contact team@lockdownprivacy.com.\n\nError details:\n") + "\(error)",
                        acceptButton: .localizedOkay)
                }
        })
    }
}
