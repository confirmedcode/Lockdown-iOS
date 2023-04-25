//
//  LDVpnViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 19.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class LDVpnViewController: UIViewController {
    
    // MARK: - Properties
    
    lazy var accessLevelslView: AccessLevelslView = {
        let view = AccessLevelslView()
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.anchors.height.equal(640)
        return view
    }()
    
    private lazy var firewallTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Get complete protection", comment: "")
        label.font = fontBold24
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private lazy var firewallDescriptionLabel1: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Block as many trackers as you want", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel2: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Import and export your own block lists", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel3: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Access to new curated lists of trackers", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel4: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("The only fully open source VPN", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel5: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Hide your identity around the world", comment: "")))
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(firewallTitle)
        stackView.addArrangedSubview(firewallDescriptionLabel1)
        stackView.addArrangedSubview(firewallDescriptionLabel2)
        stackView.addArrangedSubview(firewallDescriptionLabel3)
        stackView.addArrangedSubview(firewallDescriptionLabel4)
        stackView.addArrangedSubview(firewallDescriptionLabel5)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var upgradeButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setTitle(NSLocalizedString("Upgrade", comment: ""), for: .normal)
        button.titleLabel?.font = fontBold18
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        button.anchors.height.equal(56)
        button.addTarget(self, action: #selector(upgrade), for: .touchUpInside)
        return button
    }()
    
    private lazy var whitelistCard: LDCardView = {
        let view = LDCardView()
        view.title.text = "Whitelist"
        view.iconImageView.image = UIImage(named: "icn_whitelist")
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var regionCard: LDCardView = {
        let view = LDCardView()
        view.title.text = "Region"
        view.iconImageView.image = UIImage(named: "icn_globe")
        view.subTitle.text = "USA West"
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var hStack: UIStackView = {
        let stack = UIStackView()
        stack.addArrangedSubview(whitelistCard)
        stack.addArrangedSubview(regionCard)
        stack.alignment = .center
        stack.distribution = .equalCentering
        stack.spacing = 16
        return stack
    }()
    
    private let switchControl: CustomUISwitch = {
        let uiSwitch = CustomUISwitch()
        return uiSwitch
    }()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(accessLevelslView)
        accessLevelslView.anchors.top.safeAreaPin(inset: 18)
        accessLevelslView.anchors.leading.marginsPin()
        accessLevelslView.anchors.trailing.marginsPin()
        
        view.addSubview(scrollView)
        scrollView.anchors.top.spacing(18, to: accessLevelslView.anchors.bottom)
        scrollView.anchors.leading.pin()
        scrollView.anchors.trailing.pin()
        scrollView.anchors.bottom.pin()
        
        scrollView.addSubview(contentView)
        contentView.anchors.top.pin()
        contentView.anchors.centerX.align()
        contentView.anchors.width.equal(scrollView.anchors.width)
        contentView.anchors.bottom.pin()

        contentView.addSubview(stackView)
        stackView.anchors.top.marginsPin()
        stackView.anchors.leading.marginsPin()
        stackView.anchors.trailing.marginsPin()
        
        contentView.addSubview(upgradeButton)
        upgradeButton.anchors.top.spacing(18, to: stackView.anchors.bottom)
        upgradeButton.anchors.leading.marginsPin()
        upgradeButton.anchors.trailing.marginsPin()
        
        contentView.addSubview(hStack)
        hStack.anchors.top.spacing(18, to: upgradeButton.anchors.bottom)
        hStack.anchors.centerX.align()
        
        whitelistCard.anchors.width.equal(view.bounds.width / 2 - 20)
        whitelistCard.anchors.height.equal(view.bounds.width / 2 - 20)
        
        regionCard.anchors.width.equal(view.bounds.width / 2 - 20)
        regionCard.anchors.height.equal(view.bounds.width / 2 - 20)
        
        view.addSubview(switchControl)
        switchControl.anchors.bottom.safeAreaPin()
        switchControl.anchors.leading.marginsPin()
        switchControl.anchors.trailing.marginsPin()
        switchControl.anchors.height.equal(56)
    }
}

// MARK: - Private functions

private extension LDVpnViewController {
    
    @objc func upgrade() {
        
    }
}

