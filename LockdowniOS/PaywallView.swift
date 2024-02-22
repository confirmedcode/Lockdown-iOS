//
//  AdvancedWallView.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 28.04.2023.
//

import UIKit
import Foundation

final class PaywallView: UIView {
    
    //MARK: Properties
    private let model: PaywallViewModel
    var isSelected: Bool = false
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        return view
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.anchors.height.equal(400)
        return view
    }()
    
    lazy var headlineLabel: PaywallDescriptionLabel = {
        let label = PaywallDescriptionLabel()
        label.titleLabel.text = model.title
        label.subtitleLabel.text = model.subtitle
        return label
    }()
    
    private lazy var bulletsStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(headlineLabel)
        model.bulletPoints.forEach {
            stackView.addArrangedSubview(bulletView(forTitle: $0))
        }
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
        
        titleLabel.highlight()
        
        let descriptionLabel = UILabel()
        descriptionLabel.font = fontMedium11
        descriptionLabel.textColor = .white
        descriptionLabel.textAlignment = .left
        let descriptionLabelPrice1 = VPNSubscription.getProductIdPrice(productId: model.annualProductId)
        descriptionLabel.text = "then \(descriptionLabelPrice1) per year"
        descriptionLabel.highlight(descriptionLabelPrice1, font: UIFont.boldLockdownFont(size: 15))
        
        button.addSubview(descriptionLabel)
        descriptionLabel.anchors.top.spacing(4, to: titleLabel.anchors.bottom)
        descriptionLabel.anchors.leading.pin(inset: 24)
        
        let descriptionLabel2 = UILabel()
        descriptionLabel2.font = fontMedium11
        descriptionLabel2.textColor = .white
        
        let descriptionLabelPrice2 = VPNSubscription.getProductIdPriceMonthly(productId: model.annualProductId)
        descriptionLabel2.text = "only \(descriptionLabelPrice2) per month"
        descriptionLabel2.highlight(descriptionLabelPrice2, font: UIFont.boldLockdownFont(size: 15))
        
        button.addSubview(descriptionLabel2)
        descriptionLabel2.anchors.top.spacing(14, to: imageView.anchors.bottom)
        descriptionLabel2.anchors.trailing.pin(inset: 24)
        
        button.anchors.height.equal(66)
        button.addTarget(self, action: #selector(buyButton1Clicked), for: .touchUpInside)
        return button
    }()
    
    lazy var buyButton2: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        button.addTarget(self, action: #selector(buyButton2Clicked), for: .touchUpInside)
        
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
        
        let descriptionLabelPrice = VPNSubscription.getProductIdPrice(productId: model.mounthProductId)
        descriptionLabel.text = "\(descriptionLabelPrice)/month"
        descriptionLabel.highlight(descriptionLabelPrice, font: UIFont.boldLockdownFont(size: 15))
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
        
        button.addSubview(stackView)
        stackView.anchors.centerY.align()
        stackView.anchors.leading.pin(inset: 24)
        
        button.anchors.height.equal(66)
        return button
    }()
    
    //MARK: Initialization
    
    init(model: PaywallViewModel) {
        self.model = model
        super.init(frame: .zero)
        configureUI()
    }
    
    override init(frame: CGRect) {
        model = .empty()
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
    
    private func bulletView(forTitle title: String) -> BulletView {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: title))
        return view
    }
    
    //MARK: Functions
    @objc func buyButton1Clicked() {
        
    }
    
    @objc func buyButton2Clicked() {
        
    }

}
