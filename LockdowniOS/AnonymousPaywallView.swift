//
//  AnonymousWallView.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 29.04.2023.
//

import UIKit

final class AnonymousPaywallView: UIView {
    
    //MARK: Properties
    
    var isSelected: Bool = false
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        return view
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.anchors.height.equal(500)
        return view
    }()
    
    lazy var headlineLabel: PaywallDescriptionLabel = {
        let label = PaywallDescriptionLabel()
        label.titleLabel.text = NSLocalizedString("Secure Tunnel VPN + Advanced Firewall", comment:"")
        label.subtitleLabel.text = NSLocalizedString("Private Browsing with Hidden IP and Global Region Switching", comment: "")
        return label
    }()
    
    lazy var bulletView1: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Anonymized browsing"))
        return view
    }()
    
    lazy var bulletView2: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Change your IP address to another region"))
        return view
    }()
    
    lazy var bulletView3: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Maximum security with VPN and firewall"))
        return view
    }()
    
    lazy var bulletView4: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Location and IP address hidden"))
        return view
    }()
    
    lazy var bulletView5: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Custom block lists to block specific websites or domains"))
        return view
    }()
    
    lazy var bulletView6: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Advanced malware and ads blocking"))
        return view
    }()
    
    lazy var bulletView7: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Unlimited bandwidth and data usage"))
        return view
    }()
    
    lazy var bulletView8: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Import/Export block lists for more tailored protection"))
        return view
    }()
    
    
    private lazy var bulletsStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(headlineLabel)
        stackView.addArrangedSubview(bulletView1)
        stackView.addArrangedSubview(bulletView2)
        stackView.addArrangedSubview(bulletView3)
        stackView.addArrangedSubview(bulletView4)
        stackView.addArrangedSubview(bulletView5)
        stackView.addArrangedSubview(bulletView6)
        stackView.addArrangedSubview(bulletView7)
        stackView.addArrangedSubview(bulletView8)
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    lazy var buyButton1: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        
        let imageView = UIImageView(image: UIImage(named: "discount"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(imageView)
        NSLayoutConstraint.activate([
                imageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 0),
                imageView.topAnchor.constraint(equalTo: button.topAnchor, constant: 0)
            ])
        
        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("7-Day FREE TRIAL", comment: "")
        titleLabel.font = fontBold15
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(titleLabel)
        titleLabel.anchors.top.pin(inset: 16)
        titleLabel.anchors.leading.pin(inset: 24)
        
        var descriptionLabel = UILabel()
        descriptionLabel.font = fontMedium11
        descriptionLabel.textColor = .white
        descriptionLabel.textAlignment = .left
        
        let descriptionLabelPrice1 = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnual)
        descriptionLabel.text = "then \(descriptionLabelPrice1) per year"
        descriptionLabel.highlight(descriptionLabelPrice1, font: UIFont.boldLockdownFont(size: 15))
        
        button.addSubview(descriptionLabel)
        descriptionLabel.anchors.top.spacing(4, to: titleLabel.anchors.bottom)
        descriptionLabel.anchors.leading.pin(inset: 24)
        
        let descriptionLabel2 = UILabel()
        descriptionLabel2.font = fontMedium11
        descriptionLabel2.textColor = .white
        
        let descriptionLabelPrice2 = VPNSubscription.getProductIdPriceMonthly(productId: VPNSubscription.productIdAnnual)
        descriptionLabel2.text = "only \(descriptionLabelPrice2) per month"
        descriptionLabel2.highlight(descriptionLabelPrice2, font: UIFont.boldLockdownFont(size: 15))
        
        button.addSubview(descriptionLabel2)
        descriptionLabel2.anchors.top.spacing(14, to: imageView.anchors.bottom)
        descriptionLabel2.anchors.trailing.pin(inset: 24)

        button.anchors.height.equal(66)
        button.addTarget(self, action: #selector(buy), for: .touchUpInside)
        return button
    }()
    
    lazy var button1TitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("7-Day FREE TRIAL", comment: "")
        label.font = fontBold15
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        buyButton1.addSubview(button1TitleLabel)
        label.anchors.top.pin(inset: 16)
        label.anchors.leading.pin(inset: 24)
        return label
    }()
    
    lazy var button1DescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = fontMedium11
        label.textColor = .white
        label.textAlignment = .left
        
        let descriptionLabelPrice2 = VPNSubscription.getProductIdPriceMonthly(productId: VPNSubscription.productIdAnnual)
        label.text = "only \(descriptionLabelPrice2) per month"
        label.highlight(descriptionLabelPrice2, font: UIFont.boldLockdownFont(size: 15))
        label.text = "then \(VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdAnnual)) per year"
        
        buyButton1.addSubview(button1DescriptionLabel)
        label.anchors.top.spacing(4, to: button1TitleLabel.anchors.bottom)
        label.anchors.leading.pin(inset: 24)
        
        return label
    }()
    
    lazy var buyButton2: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        button.addTarget(self, action: #selector(buy), for: .touchUpInside)
        
        let title = NSLocalizedString("7-Day FREE TRIAL", comment: "")
        let titleLabel = UILabel()
        titleLabel.font = fontBold15
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.textAlignment = .left
        
        let descriptionLabel = UILabel()
        descriptionLabel.font = fontMedium11
        descriptionLabel.textColor = .white
        descriptionLabel.textAlignment = .left
        
        let descriptionLabelPrice = VPNSubscription.getProductIdPrice(productId: VPNSubscription.productIdMonthly)
        descriptionLabel.text = "\(descriptionLabelPrice)/month"
        descriptionLabel.highlight(descriptionLabelPrice, font: UIFont.boldLockdownFont(size: 15))
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
        
        button.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.anchors.centerY.align()
        stackView.anchors.leading.pin(inset: 24)
        
        button.anchors.height.equal(66)
        
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
    
    //MARK: ConfigureUI
    private func configureUI() {
        
        addSubview(buyButton2)
        buyButton2.anchors.bottom.pin()
        buyButton2.anchors.leading.marginsPin()
        buyButton2.anchors.trailing.marginsPin()
        
        addSubview(buyButton1)
        buyButton1.anchors.bottom.spacing(16, to: buyButton2.anchors.top)
        buyButton1.anchors.leading.marginsPin()
        buyButton1.anchors.trailing.marginsPin()
        
        addSubview(scrollView)
        scrollView.anchors.top.pin()
        scrollView.anchors.leading.pin(inset: 16)
        scrollView.anchors.trailing.pin()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.anchors.bottom.spacing(8, to: buyButton1.anchors.top)
        
        scrollView.addSubview(contentView)
        contentView.anchors.top.pin()
        contentView.anchors.centerX.align()
        contentView.anchors.width.equal(scrollView.anchors.width)
        contentView.anchors.bottom.pin()
        
        contentView.addSubview(bulletsStackView)
        bulletsStackView.anchors.top.marginsPin()
        bulletsStackView.anchors.leading.marginsPin()
        bulletsStackView.anchors.trailing.marginsPin()
    }
    
    //MARK: Functions
    @objc func buy() {
        
    }
}
