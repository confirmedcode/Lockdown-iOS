//
//  AdvancedDescriptionLabel.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 27.04.2023.
//

import UIKit

final class PaywallDescriptionLabel: UIView {
    
    //MARK: Properties
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = fontBold26
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = fontSemiBold15
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        stackView.spacing = 8
        return stackView
    }()
    
    //MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Functions
    private func configureUI() {
        addSubview(stackView)
        stackView.anchors.top.pin()
        stackView.anchors.bottom.marginsPin()
        stackView.anchors.leading.pin()
        stackView.anchors.trailing.pin()
    }
}
