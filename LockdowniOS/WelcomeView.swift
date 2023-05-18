//
//  WelcomeView.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 08.05.2023.
//

import UIKit

final class WelcomeView: UIView {
    
    //MARK: Properties
    private lazy var titleLable: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Welcome to Lockdown 2.0!", comment: "")
        label.textColor = .white
        label.font = fontBold26
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "welcome-image")
        imageView.contentMode = .scaleAspectFit
        return imageView
        }()
    
    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLable)
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.spacing = 16
        stackView.anchors.height.equal(64)
        return stackView
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("You will notice your Lockdown app looks a bit different. We’ve been working hard on creating a more powerful, usable and informative privacy tool. We are fully open source and open audited (Feb 2023).", comment: "")
        label.textColor = .white
        label.font = fontMedium15
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var subTitleLable: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("With the new Lockdown:", comment: "")
        label.textColor = .white
        label.font = fontSemiBold22
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var bulletView1: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Your blocking engine is faster and more robust"))
        view.titleLabel.numberOfLines = 0
        view.titleLabel.font = fontMedium15
        view.stackView.anchors.height.equal(40)
        return view
    }()
    
    private lazy var bulletView2: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "You can import + export lists"))
        view.titleLabel.font = fontMedium15
        return view
    }()
    
    private lazy var bulletView3: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "You can create your own groups"))
        view.titleLabel.font = fontMedium15
        return view
    }()
    
    private lazy var bulletView4: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "You can select app specific lists"))
        view.titleLabel.font = fontMedium15
        return view
    }()
    
    private lazy var bulletView5: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "You can monitor what’s not being blocked"))
        view.titleLabel.numberOfLines = 0
        view.titleLabel.font = fontMedium15
        view.stackView.anchors.height.equal(40)
        return view
    }()
    
    private lazy var bulletsStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(bulletView1)
        stackView.addArrangedSubview(bulletView2)
        stackView.addArrangedSubview(bulletView3)
        stackView.addArrangedSubview(bulletView4)
        stackView.addArrangedSubview(bulletView5)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var descriptionLabel2: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("You can access these new firewall features by starting a trial for our new “Advanced” subscription plan. We are hard at work improving these features and fixing any bugs that arise. Please give it a try and reach out with any feedback to team@lockdownhq.com.", comment: "")
        label.textColor = .white
        label.font = fontMedium15
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
//        button.addTarget(self, action: #selector(continueButtonClicked), for: .touchUpInside)
        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("Continue", comment: "")
        titleLabel.font = fontSemiBold17
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
    
    //MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        configureBackgroundColor()
    }
    
    //MARK: Functions
    private func configureUI() {
        addSubview(titleStackView)
        titleStackView.anchors.top.safeAreaPin(inset: 24)
        titleStackView.anchors.leading.marginsPin()
        titleStackView.anchors.trailing.marginsPin()
        
        addSubview(descriptionLabel)
        descriptionLabel.anchors.top.spacing(24, to: titleStackView.anchors.bottom)
        descriptionLabel.anchors.trailing.marginsPin()
        descriptionLabel.anchors.leading.marginsPin()
        
        addSubview(subTitleLable)
        subTitleLable.anchors.top.spacing(16, to: descriptionLabel.anchors.bottom)
        subTitleLable.anchors.trailing.marginsPin()
        subTitleLable.anchors.leading.marginsPin()
        
        addSubview(bulletsStackView)
        bulletsStackView.anchors.top.spacing(8, to: subTitleLable.anchors.bottom)
        bulletsStackView.anchors.trailing.marginsPin()
        bulletsStackView.anchors.leading.marginsPin()
        
        addSubview(descriptionLabel2)
        descriptionLabel2.anchors.top.spacing(16, to: bulletsStackView.anchors.bottom)
        descriptionLabel2.anchors.trailing.marginsPin()
        descriptionLabel2.anchors.leading.marginsPin()
        
        addSubview(continueButton)
        continueButton.anchors.bottom.safeAreaPin(inset: 24)
        continueButton.anchors.top.spacing(24, to: descriptionLabel2.anchors.bottom)
        continueButton.anchors.leading.marginsPin()
        continueButton.anchors.trailing.marginsPin()
    }
    
    private func configureBackgroundColor() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.gradientPink1.cgColor, UIColor.gradientPink2.cgColor]
        gradientLayer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    @objc func continueButtonClicked() {
//        dismiss(animated: false) {
//            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
//            
//            keyWindow?.rootViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "MainTabBarController")
//            keyWindow?.makeKeyAndVisible()
//        }
    }
}
