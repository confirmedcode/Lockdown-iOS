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
    
    lazy var trialDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = fontRegular12
        label.textColor = .white
        label.textAlignment = .center
        let anualPrice = VPNSubscription.getProductIdPrice(productId: model.annualProductId)
        let monthlyPrice = VPNSubscription.getProductIdPriceMonthly(productId: model.annualProductId)
        let trialDuation = VPNSubscription.trialDuration(productId: model.annualProductId) ?? ""
        let title = trialDuation + " " + NSLocalizedString("free trial", comment: "") + "," + " then \(anualPrice) (\(monthlyPrice)/mo)"
        label.text = title
        return label
    }()
    
    lazy var bottomProduct: ProductButton = {
        let descriptionLabelPrice1 = VPNSubscription.getProductIdPrice(productId: model.mounthProductId)
        let trialDuation = VPNSubscription.trialDuration(productId: model.annualProductId) ?? ""
        let title = trialDuation + " " + NSLocalizedString("trial", comment: "")
        
        var descriptionTitle = trialDuation.isEmpty ? "" : NSLocalizedString("then", comment: "") + " "
        descriptionTitle += descriptionLabelPrice1 + NSLocalizedString("/year", comment: "")
        
        let button = ProductButton(title: "Monthly", subtitle: descriptionLabelPrice1, toHighlight: descriptionLabelPrice1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var topProduct: ProductButton = {
        let annyalPrice = VPNSubscription.getProductIdPrice(productId: model.annualProductId)
        let monthlyPrice = VPNSubscription.getProductIdPriceMonthly(productId: model.annualProductId)
        var descriptionTitle = "\(annyalPrice)" + " (\(monthlyPrice)/mo)"
        let button = ProductButton(title: "Yearly", subtitle: descriptionTitle, toHighlight: annyalPrice, isSelected: true)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    func updateCTATitle() {
        let hasTrial = (VPNSubscription.trialDuration(productId: model.annualProductId) != nil) || (VPNSubscription.trialDuration(productId: model.mounthProductId) != nil)
        let title = hasTrial ? "Start for Free" : "Continue"
        actionButton.setTitle(title, for: .normal)
    }
    
    lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        let title = "Start for Free"
        button.titleLabel?.font = fontSemiBold17
        button.setTitle(title, for: .normal)
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
        
        addSubview(actionButton)
        actionButton.anchors.bottom.pin()
        actionButton.anchors.leading.marginsPin()
        actionButton.anchors.trailing.marginsPin()
        actionButton.anchors.height.equal(58)
        
        addSubview(trialDescriptionLabel)
        trialDescriptionLabel.anchors.leading.marginsPin()
        trialDescriptionLabel.anchors.trailing.marginsPin()
        trialDescriptionLabel.anchors.bottom.spacing(10, to: actionButton.anchors.top)
        
        addSubview(bottomProduct)
        bottomProduct.anchors.bottom.spacing(35, to: actionButton.anchors.top)
        bottomProduct.anchors.leading.marginsPin()
        bottomProduct.anchors.trailing.marginsPin()
        bottomProduct.anchors.height.equal(60)
        
        addSubview(topProduct)
        topProduct.anchors.bottom.spacing(16, to: bottomProduct.anchors.top)
        topProduct.anchors.leading.marginsPin()
        topProduct.anchors.trailing.marginsPin()
        topProduct.anchors.height.equal(60)
        
        addSubview(scrollView)
        scrollView.anchors.top.pin()
        scrollView.anchors.leading.pin(inset: 16)
        scrollView.anchors.trailing.pin()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.anchors.bottom.spacing(8, to: topProduct.anchors.top)
        
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
}
