//
//  AdvancedWallViewController.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 25.04.2023.
//

import UIKit

final class VPNPaywallViewController: UIViewController {
    
    //MARK: Properties
    private var titleName = NSLocalizedString("Lockdown", comment: "")
    
    //MARK: navigation
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.rightNavButton.setTitle(NSLocalizedString("RESTORE", comment: ""), for: .normal)
        view.titleLabel.text = NSLocalizedString(titleName, comment: "")
        view.leftNavButton.setTitle(NSLocalizedString("CLOSE", comment: ""), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        view.rightNavButton.addTarget(self, action: #selector(restoreButtonClicked), for: .touchUpInside)
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
            print("tapped")
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
            print("tapped")
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
            print("tapped")
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
        return view
    }()
    
    lazy var anonymousView: AnonymousPaywallView = {
        let view = AnonymousPaywallView()
        view.isHidden = true
        return view
    }()
    
    lazy var universalView: UniversalPaywallView = {
        let view = UniversalPaywallView()
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
            attributedText.append(NSAttributedString(string: NSLocalizedString("Terms of Service", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.link: URL(string: "https://lockdownprivacy.com/terms")!]))
            attributedText.append(NSAttributedString(string: NSLocalizedString(" and ", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.smallGrey]))
            let privacyRange = NSRange(location: attributedText.length, length: NSLocalizedString("Privacy Policy", comment: "").count)
            attributedText.append(NSAttributedString(string: NSLocalizedString("Privacy Policy", comment: ""), attributes: [NSAttributedString.Key.font: fontMedium11, NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.link: URL(string: "https://lockdownprivacy.com/privacy")!]))
            
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
    
    @objc func restoreButtonClicked() {
        
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
