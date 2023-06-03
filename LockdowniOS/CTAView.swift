//
//  CTAView.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 2.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class CTAView: UIView {

    // MARK: - Properties
    
    private lazy var bkgView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 15
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "icn_close_filled"), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var mainTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Get Advanced protection", comment: "")
        label.font = fontBold24
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private lazy var descriptionLabel1: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Block as many trackers as you want", comment: "")))
        return label
    }()
    
    private lazy var descriptionLabel2: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Import and export your own block lists", comment: "")))
        return label
    }()
    
    private lazy var descriptionLabel3: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Access to new curated lists of trackers", comment: "")))
        return label
    }()
    
    private lazy var upgradeButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setTitle(NSLocalizedString("Upgrade", comment: ""), for: .normal)
        button.titleLabel?.font = fontBold18
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        button.anchors.height.equal(56)
//        button.addTarget(self, action: #selector(upgrade), for: .touchUpInside)
        return button
    }()
    
//    private lazy var close: UIImageView = {
//        let image = UIImageView()
//        image.image = UIImage(named: "icn_close_filled")
//        image.contentMode = .scaleAspectFit
//        image.layer.masksToBounds = true
//        return image
//    }()
    
    private lazy var hStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(mainTitle)
        stackView.addArrangedSubview(closeButton)
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 30
        return stackView
    }()
    
    private lazy var vStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(hStackView)
        stackView.addArrangedSubview(descriptionLabel1)
        stackView.addArrangedSubview(descriptionLabel2)
        stackView.addArrangedSubview(descriptionLabel3)
        stackView.addArrangedSubview(upgradeButton)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 4
        return stackView
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Configure UI
    
    func configure() {
        
        vStackView.layer.cornerRadius = 15
        vStackView.backgroundColor = .lightGray
        
        addSubview(vStackView)
        vStackView.anchors.top.pin()
        vStackView.anchors.bottom.pin()
        vStackView.anchors.leading.pin()
        vStackView.anchors.trailing.pin()
    }
    
    @objc func closeButtonTapped() {
        
    }
    
//    @objc func upgrade() {
//        let vc = VPNPaywallViewController()
//        present(vc, animated: true)
//    }

}
