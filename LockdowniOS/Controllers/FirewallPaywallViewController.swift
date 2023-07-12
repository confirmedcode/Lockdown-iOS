//
//  AdvancedPaywall.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 29.04.2023.
//

import UIKit
import NetworkExtension
import PromiseKit
import CocoaLumberjackSwift
import StoreKit

protocol PaywallViewControllerCloseDelegate: AnyObject {
    func didClosePaywall()
}

final class FirewallPaywallViewController: BaseViewController, Loadable {
    
    var parentVC: UIViewController?
    
    weak var firewallVC: LDFirewallViewController?
    
    var advancedPlanUpdated: (() -> ())?
    
    enum Mode {
        case newSubscription
        case upgrade(active: [Subscription.PlanType])
    }
    
    var mode = Mode.newSubscription
    
    //MARK: Properties
    private var titleName = NSLocalizedString("Lockdown", comment: "")
    
    private lazy var navigationView: ConfiguredNavigationView =
    {
        let view = ConfiguredNavigationView()
        view.rightNavButton.setTitle(NSLocalizedString("RESTORE", comment: ""), for: .normal)
        view.rightNavButton.addTarget(self, action: #selector(restorePurchase), for: .touchUpInside)
        view.titleLabel.text = NSLocalizedString(titleName, comment: "")
        view.leftNavButton.setTitle(NSLocalizedString("CLOSE", comment: ""), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        return view
    }()
    
    private lazy var annualPlan: AdvancedPlansViews = {
        let view = AdvancedPlansViews()
        view.title.text = "Annual"
        view.detailTitle.text = "\(VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAdvancedYearly))/year"
        view.detailTitle2.text = "$2.99/month"
        view.discountImageView.image = UIImage(named: "saveDiscount")
        view.iconImageView.image = UIImage(named: "fill-1")
        view.backgroundView.layer.borderColor = UIColor.white.cgColor
        view.isUserInteractionEnabled = true
        
        view.setOnClickListener { [unowned self] in
            
            selectAdvancedYearly()
            
            annualView.isHidden = false
            monthlyView.isHidden = true
            
            view.iconImageView.image = UIImage(named: "fill-1")
            view.backgroundView.layer.borderColor = UIColor.white.cgColor
            
            monthlyPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            monthlyPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
            
            ftPriceLabel.text = "7-day free trial, then \(VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAdvancedYearly)) yearly. Cancel anytime."
        }
        return view
    }()
    
    private lazy var monthlyPlan: AdvancedPlansViews = {
        let view = AdvancedPlansViews()
        view.title.text = "Monthly"
        view.detailTitle.text = "\(VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAdvancedMonthly))/month"
        view.detailTitle2.text = "  "
        view.isUserInteractionEnabled = true
        
        view.setOnClickListener { [unowned self] in
            
            selectAdvancedMonthly()
            
            monthlyView.isHidden = false
            annualView.isHidden = true
            
            view.iconImageView.image = UIImage(named: "fill-1")
            view.backgroundView.layer.borderColor = UIColor.white.cgColor
            
            annualPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            annualPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
            
            ftPriceLabel.text = "7-day free trial, then \(VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAdvancedMonthly)) monthly. Cancel anytime."
        }
        return view
    }()
    
    private lazy var plansStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.addArrangedSubview(annualPlan)
        stack.addArrangedSubview(monthlyPlan)
        stack.alignment = .leading
        stack.distribution = .fillEqually
        stack.spacing = 16
        return stack
    }()
    
    lazy var ftPriceLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("7-day free trial, then \(VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAdvancedYearly)) yearly. Cancel anytime.", comment: "")
        label.textColor = .smallGrey
        label.font = fontMedium11
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var freeTrialButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        button.addTarget(self, action: #selector(startTrial), for: .touchUpInside)
        let titleLabel = UILabel()
        let title = NSLocalizedString("Try 7-day free trial", comment: "")
        titleLabel.font = fontSemiBold17
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        button.addSubview(titleLabel)
        titleLabel.anchors.top.pin(inset: 16)
        titleLabel.anchors.bottom.pin(inset: 16)
        titleLabel.anchors.leading.pin(inset: 24)
        titleLabel.anchors.trailing.pin(inset: 24)
        button.anchors.height.equal(56)
        return button
    }()
    
    private lazy var annualView: AnnualPlanView = {
        let view = AnnualPlanView()
        return view
    }()
    
    private lazy var monthlyView: MonthlyPlanView = {
        let view = MonthlyPlanView()
        view.isHidden = true
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
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.purplePaywall.cgColor, UIColor.purplePaywall2.cgColor]
        gradientLayer.frame = view.bounds
                
        view.layer.insertSublayer(gradientLayer, at: 0)
        configureUI()
    }
    
    //MARK: ConfigureUI
    private func configureUI() {
        view.addSubview(navigationView)
        navigationView.anchors.top.safeAreaPin(inset: 18)
        navigationView.anchors.leading.marginsPin()
        navigationView.anchors.trailing.marginsPin()
        
        view.addSubview(privacyLabel)
        privacyLabel.anchors.bottom.safeAreaPin()
        privacyLabel.anchors.leading.marginsPin()
        privacyLabel.anchors.trailing.marginsPin()
        privacyLabel.anchors.height.equal(34)
        
        view.addSubview(freeTrialButton)
        freeTrialButton.anchors.bottom.spacing(8, to: privacyLabel.anchors.top)
        freeTrialButton.anchors.leading.marginsPin()
        freeTrialButton.anchors.trailing.marginsPin()
        
        view.addSubview(ftPriceLabel)
        ftPriceLabel.anchors.bottom.spacing(8, to: freeTrialButton.anchors.top)
        ftPriceLabel.anchors.leading.marginsPin()
        ftPriceLabel.anchors.trailing.marginsPin()
        
        view.addSubview(plansStack)
        plansStack.anchors.bottom.spacing(20, to: ftPriceLabel.anchors.top)
        plansStack.anchors.leading.pin(inset: 16)
        plansStack.anchors.trailing.pin(inset: 16)
        
        view.addSubview(annualView)
        annualView.anchors.top.spacing(24, to: navigationView.anchors.bottom)
        annualView.anchors.leading.pin()
        annualView.anchors.trailing.pin()
        annualView.anchors.bottom.spacing(8, to: plansStack.anchors.top)
        
        view.addSubview(monthlyView)
        monthlyView.anchors.top.spacing(24, to: navigationView.anchors.bottom)
        monthlyView.anchors.leading.pin()
        monthlyView.anchors.trailing.pin()
        monthlyView.anchors.bottom.spacing(8, to: plansStack.anchors.top)
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

extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
    guard let attributedText = label.attributedText else { return false }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: attributedText)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.size = label.bounds.size
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (label.bounds.width - textBoundingBox.width) * 0.5 - textBoundingBox.minX,
                                           y: (label.bounds.height - textBoundingBox.height) * 0.5 - textBoundingBox.minY)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                      y: locationOfTouchInLabel.y - textContainerOffset.y)
        let index = layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                  in: textContainer,
                                                  fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(index, targetRange)
    }
}

extension FirewallPaywallViewController: ProductPurchasable {
    @objc private func restorePurchase() {
        //toggleRestorePurchasesButton(false)
        firstly {
            try Client.signIn(forceRefresh: true)
        }
        .then { (signin: SignIn) -> Promise<GetKey> in
            try Client.getKey()
        }
        .done { (getKey: GetKey) in
            // we were able to get key, so subscription is valid -- follow pathway from HomeViewController to associate this with the email account if there is one
            let presentingViewController = self.presentingViewController as? HomeViewController
            self.dismiss(animated: true, completion: {
                if presentingViewController != nil {
                    presentingViewController?.toggleVPN("me")
                }
                else {
                    VPNController.shared.setEnabled(true)
                }
            })
        }
        .catch { error in
//            self.toggleRestorePurchasesButton(true)
            DDLogError("Restore Failed: \(error)")
            if let apiError = error as? ApiError {
                switch apiError.code {
                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                    // now try email if it exists
                    if let apiCredentials = getAPICredentials(), getAPICredentialsConfirmed() == true {
                        DDLogInfo("restore: have confirmed API credentials, using them")
//                        self.toggleRestorePurchasesButton(false)
                        firstly {
                            try Client.signInWithEmail(email: apiCredentials.email, password: apiCredentials.password)
                        }
                        .then { (signin: SignIn) -> Promise<GetKey> in
                            DDLogInfo("restore: signin result: \(signin)")
                            return try Client.getKey()
                        }
                        .done { (getKey: GetKey) in
//                            self.toggleRestorePurchasesButton(true)
                            try setVPNCredentials(id: getKey.id, keyBase64: getKey.b64)
                            DDLogInfo("restore: setting VPN creds with ID and Dismissing: \(getKey.id)")
                            let presentingViewController = self.presentingViewController as? LDFirewallViewController
                            self.dismiss(animated: true, completion: {
                                if presentingViewController != nil {
                                    presentingViewController?.toggleFirewall()
                                }
                                else {
                                    VPNController.shared.setEnabled(true)
                                }
                            })
                        }
                        .catch { error in
//                            self.toggleRestorePurchasesButton(true)
                            DDLogError("restore: Error doing restore with email-login: \(error)")
                            if (self.popupErrorAsNSURLError(error)) {
                                return
                            }
                            else if let apiError = error as? ApiError {
                                switch apiError.code {
                                case kApiCodeNoSubscriptionInReceipt, kApiCodeNoActiveSubscription:
                                    self.showPopupDialog(title: NSLocalizedString("No Active Subscription", comment: ""),
                                                    message: NSLocalizedString("Please ensure that you have an active subscription. If you're attempting to share a subscription from the same account, you'll need to sign in with the same email address. Otherwise, start your free trial or e-mail team@lockdownprivacy.com", comment: ""),
                                                    acceptButton: NSLocalizedString("OK", comment: ""))
                                default:
                                    _ = self.popupErrorAsApiError(error)
                                }
                            }
                        }
                    }
                    else {
                        self.showPopupDialog(title: NSLocalizedString("No Active Subscription", comment: ""),
                                        message: NSLocalizedString("Please ensure that you have an active subscription. If you're attempting to share a subscription from the same account, you'll need to sign in with the same email address. Otherwise, start your free trial or e-mail team@lockdownprivacy.com", comment: ""),
                                        acceptButton: NSLocalizedString("OK", comment: ""))
                    }
                default:
                    self.showPopupDialog(title: NSLocalizedString("Error Restoring Subscription", comment: ""),
                                         message: NSLocalizedString("Please email team@lockdownprivacy.com with the following Error Code ", comment: "") + "\(apiError.code) : \(apiError.message)",
                                         acceptButton: NSLocalizedString("OK", comment: ""))
                }
            }
            else {
                self.showPopupDialog(title: NSLocalizedString("Error Restoring Subscription", comment: ""),
                                     message: NSLocalizedString("Please make sure your Internet connection is active. If this error persists, email team@lockdownprivacy.com with the following error message: ", comment: "") + "\(error)",
                    acceptButton: NSLocalizedString("OK", comment: ""))
            }
        }
    }
    
    func selectAdvancedYearly() {
        VPNSubscription.selectedProductId = VPNSubscription.productIdAdvancedYearly
        updatePricingSubtitle()
    }
    
    func selectAdvancedMonthly() {
        VPNSubscription.selectedProductId = VPNSubscription.productIdAdvancedMonthly
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
        
        if monthlyPlan.isSelected {
            let priceLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAdvancedMonthly, for: context)
            ftPriceLabel.text = "7-day free trial, then \(priceLabel). Cancel anytime."
        } else if annualPlan.isSelected {
            let priceLabel = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAdvancedYearly, for: context)
            ftPriceLabel.text = "7-day free trial, then \(priceLabel). Cancel anytime."
        }
    }
    
    @objc func startTrial() {
        showLoadingView()
        VPNSubscription.purchase(
            succeeded: {
                self.dismiss(animated: true, completion: { [self] in
                    if let presentingViewController = self.parentVC as? LDFirewallViewController {
                        
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
    
    private func showPaywallIfNoSubscription() {
        guard BaseUserService.shared.user.currentSubscription == nil else { return }
        guard BasePaywallService.shared.context == .normal else { return }
        
        BasePaywallService.shared.showPaywall(on: self)
        
        UserDefaults.hasSeenPaywallOnHomeScreen = true
    }
}
