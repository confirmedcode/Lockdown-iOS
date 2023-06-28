//
//  NavigationLinkView.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 26.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class NavigationLinkView: UIView {
    
    var emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .semiboldLockdownFont(size: 36)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .semiboldLockdownFont(size: 16)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    var placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .regularLockdownFont(size: 16)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var chevron: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        let view = UIImageView(image: .init(systemName: "chevron.right", withConfiguration: configuration))
        view.contentMode = .center
        view.tintColor = .black
        return view
    }()
    
    var didSelect: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        backgroundColor = .tableCellBackground
        layer.cornerRadius = 8
        layer.borderWidth = 0
        
        addSubview(emojiLabel)
        emojiLabel.anchors.leading.pin(inset: 20)
        emojiLabel.anchors.centerY.equal(anchors.centerY)
        emojiLabel.anchors.size.equal(.init(width: 36, height: 24))
        
        addSubview(chevron)
        chevron.anchors.trailing.pin(inset: 18)
        chevron.anchors.centerY.equal(anchors.centerY)
        chevron.anchors.size.equal(.init(width: 16, height: 16))
        
        addSubview(titleLabel)
        titleLabel.anchors.top.pin(inset: 18)
        titleLabel.anchors.bottom.pin(inset: 18)
        titleLabel.anchors.leading.spacing(28, to: emojiLabel.anchors.trailing)
        chevron.anchors.leading.greaterThanOrEqual(titleLabel.anchors.trailing, constant: 8)
        
        addSubview(placeholderLabel)
        placeholderLabel.anchors.top.greaterThanOrEqual(anchors.top, constant: 18)
        placeholderLabel.anchors.leading.pin(inset: 18)
        anchors.bottom.greaterThanOrEqual(placeholderLabel.anchors.bottom, constant: 18)
        chevron.anchors.leading.greaterThanOrEqual(placeholderLabel.anchors.trailing, constant: 18)
        
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped))
        )
    }

    @objc private func tapped() {
        didSelect?()
    }
}
