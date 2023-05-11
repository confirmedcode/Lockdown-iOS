//
//  AdvancedWallViewController.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 25.04.2023.
//

import UIKit
import SwiftyStoreKit
import NetworkExtension
import PromiseKit
import CocoaLumberjackSwift
import StoreKit

final class VPNPaywallViewController: BaseViewController, Loadable {
    
    var parentVC: UIViewController?
    
    enum Mode {
        case newSubscription
        case upgrade(active: [Subscription.PlanType])
    }
    
    var mode = Mode.newSubscription
    
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
        view.iconImageView.image = UIImage(named: "fill-1")
        view.backgroundView.layer.borderColor = UIColor.borderBlue.cgColor
        view.isUserInteractionEnabled = true
        
        
        view.setOnClickListener { [unowned self] in
            advancedView.isHidden = false
            anonymousView.isHidden = true
            universalView.isHidden = true
            
            view.iconImageView.image = UIImage(named: "fill-1")
            view.backgroundView.layer.borderColor = UIColor.borderBlue.cgColor
            
            anonymousPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            anonymousPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
            
            universalPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            universalPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
        }
        return view
    }()
    
    private lazy var anonymousPlan: PlanView = {
        let view = PlanView()
        view.title.text = "Anonymous"
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [unowned self] in
            anonymousView.isHidden = false
            advancedView.isHidden = true
            universalView.isHidden = true
            
            view.iconImageView.image = UIImage(named: "fill-1")
            view.backgroundView.layer.borderColor = UIColor.borderBlue.cgColor
            
            advancedPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            advancedPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
            
            universalPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            universalPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
        }
        return view
    }()
    
    private lazy var universalPlan: PlanView = {
        let view = PlanView()
        view.title.text = "Universal"
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [unowned self] in
            universalView.isHidden = false
            anonymousView.isHidden = true
            advancedView.isHidden = true
            
            view.iconImageView.image = UIImage(named: "fill-1")
            view.backgroundView.layer.borderColor = UIColor.borderBlue.cgColor
            
            advancedPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            advancedPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
            
            anonymousPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            anonymousPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
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
//            ftPriceLabel.text = "7-day free trial, then \(priceLabel). Cancel anytime."
        } else if anonymousView.isSelected {
            let monthlyPlanLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthly, for: context)
            let annualPlanLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnual, for: context)
//            ftPriceLabel.text = "7-day free trial, then \(priceLabel). Cancel anytime."
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
                    if let presentingViewController = self.parentVC as? LDVpnViewController {
                        // TODO: change view of LDFirewallViewController
                        
                    }
                    // force refresh receipt, and sync with email if it exists, activate VPNte
                    if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
                        DDLogInfo("purchase complete: syncing with confirmed email")
                        firstly {
                            try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                        }
                        .then { (signin: SignIn) -> Promise<SubscriptionEvent> in
                            DDLogInfo("purchase complete: signin result: \(signin)")
                            return try Client.subscriptionEvent(forceRefresh: true)
                        }
                        .then { (result: SubscriptionEvent) -> Promise<GetKey> in
                            DDLogInfo("purchase complete: subscriptionevent result: \(result)")
                            return try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
                            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                            DDLogInfo("purchase complete: setting VPN creds with ID: \(getKey.id)")
                            VPNController.shared.setEnabled(true)
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
                            try Client.signIn(forceRefresh: true) // this will fetch and set latest receipt, then submit to API to get cookie
                        }
                        .then { _ in
                            // TODO: don't always do this -- if we already have a key, then only do it once per day max
                            try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
                            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                            VPNController.shared.setEnabled(true)
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
                DDLogError("Start Trial Failed: \(error)")
                self.hideLoadingView()
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
                } else if self.popupErrorAsNSURLError(error) {
                    return
                } else if self.popupErrorAsApiError(error) {
                    return
                } else {
                    self.showPopupDialog(
                        title: .localized("Error Starting Trial"),
                        message: .localized("Please contact team@lockdownprivacy.com.\n\nError details:\n") + "\(error)",
                        acceptButton: .localizedOkay)
                }
        })
    }
}
