//
//  AdvancedPaywall.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 29.04.2023.
//

import UIKit

final class FirewallPaywallViewController: UIViewController {
    
    //MARK: Properties
    private var titleName = NSLocalizedString("Lockdown", comment: "")
    
    private lazy var navigationView: ConfiguredNavigationView =
    {
        let view = ConfiguredNavigationView()
        view.rightNavButton.setTitle(NSLocalizedString("RESTORE", comment: ""), for: .normal)
        view.titleLabel.text = NSLocalizedString(titleName, comment: "")
        view.leftNavButton.setTitle(NSLocalizedString("CLOSE", comment: ""), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        view.rightNavButton.addTarget(self, action: #selector(restoreButtonClicked), for: .touchUpInside)
        
        return view
    }()
    
    private lazy var annualPlan: AdvancedPlansViews = {
        let view = AdvancedPlansViews()
        view.title.text = "Annual"
        view.detailTitle.text = "$29.99/year"
        view.detailTitle2.text = "$2.49/month"
        view.discountImageView.image = UIImage(named: "saveDiscount")
        view.iconImageView.image = UIImage(named: "fill-1")
        view.backgroundView.layer.borderColor = UIColor.white.cgColor
        view.isUserInteractionEnabled = true
        
        view.setOnClickListener { [unowned self] in
            annualView.isHidden = false
            monthlyView.isHidden = true
            
            view.iconImageView.image = UIImage(named: "fill-1")
            view.backgroundView.layer.borderColor = UIColor.white.cgColor
            
            monthlyPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            monthlyPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
            
            ftPriceLabel.text = "7-day free trial, then $29.99 yearly. Cancel anytime."
        }
        return view
    }()
    
    private lazy var monthlyPlan: AdvancedPlansViews = {
        let view = AdvancedPlansViews()
        view.title.text = "Monthly"
        view.detailTitle.text = "$4.99/month"
        view.detailTitle2.text = "  "
        view.isUserInteractionEnabled = true
        
        view.setOnClickListener { [unowned self] in
            monthlyView.isHidden = false
            annualView.isHidden = true
            
            view.iconImageView.image = UIImage(named: "fill-1")
            view.backgroundView.layer.borderColor = UIColor.white.cgColor
            
            annualPlan.iconImageView.image = UIImage(named: "grey-ellipse-1")
            annualPlan.backgroundView.layer.borderColor = UIColor.borderGray.cgColor
            
            ftPriceLabel.text = "7-day free trial, then $4.99 monthly. Cancel anytime."
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
        label.text = NSLocalizedString("7-day free trial, then $29.99 yearly. Cancel anytime.", comment: "")
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
        button.addTarget(self, action: #selector(tryButtonClicked), for: .touchUpInside)
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
           attributedText.append(NSAttributedString(string: NSLocalizedString("Terms of Service", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.link: URL(string: "https://www.apple.com")!]))
           attributedText.append(NSAttributedString(string: NSLocalizedString(" and ", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.smallGrey]))
           attributedText.append(NSAttributedString(string: NSLocalizedString("Privacy Policy", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.link: URL(string: "https://www.apple.com")!]))
           
           let paragraphStyle = NSMutableParagraphStyle()
           paragraphStyle.alignment = .center
           attributedText.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
           label.attributedText = attributedText
        
           label.isUserInteractionEnabled = true
           
           let tapGesture = UITapGestureRecognizer(target: self, action: #selector(privacyLabelTapped))
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
    
    @objc func restoreButtonClicked() {
        
    }
    
    @objc func tryButtonClicked() {
        
    }
    
    @objc func privacyLabelTapped() {
        guard let privacyPolicyURL = URL(string: "https://www.apple.com") else { return }
        guard let termsOfServiceURL = URL(string: "https://developer.apple.com") else { return }
            
        let attributedString = privacyLabel.attributedText as NSAttributedString?
        let location = privacyLabel.text?.count ?? 0
            
        if let attributedString = attributedString {
                let selectedRange = NSRange(location: location - 20, length: 20)
                
            if selectedRange.location >= 0 {
                let string = attributedString.attributedSubstring(from: selectedRange).string
                    
                if string == "Privacy Policy" {
                    UIApplication.shared.open(privacyPolicyURL, options: [:], completionHandler: nil)
                    } else if string == "Terms of Service" {
                        UIApplication.shared.open(termsOfServiceURL, options: [:], completionHandler: nil)
                }
            }
        }
    }
}
