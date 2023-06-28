//
//  CountryView.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 27.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class CountryView: UIView {
    
    var didSelect: (() -> Void)?
    
    var emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .semiboldLockdownFont(size: 36)
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .semiboldLockdownFont(size: 16)
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()
    
    var checkMark: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let imageView = UIImageView(
            image: .init(
                systemName: "checkmark",
                withConfiguration: configuration
            )
        )
        imageView.tintColor = .tunnelsBlue
        imageView.contentMode = .center
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        backgroundColor = .extraLightGray
        layer.cornerRadius = 8
        layer.borderWidth = 0
        
        addSubview(emojiLabel)
        emojiLabel.anchors.leading.pin(inset: 20)
        emojiLabel.anchors.centerY.equal(anchors.centerY)
        emojiLabel.anchors.size.equal(.init(width: 36, height: 24))
        
        addSubview(checkMark)
        checkMark.anchors.trailing.pin(inset: 22)
        checkMark.anchors.centerY.equal(anchors.centerY)
        checkMark.anchors.size.equal(.init(width: 15, height: 10))
        
        addSubview(titleLabel)
        titleLabel.anchors.top.pin(inset: 18)
        titleLabel.anchors.bottom.pin(inset: 18)
        titleLabel.anchors.leading.spacing(28, to: emojiLabel.anchors.trailing)
        checkMark.anchors.leading.greaterThanOrEqual(titleLabel.anchors.trailing, constant: 8)
        
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped))
        )
    }
    
    @objc private func tapped() {
        didSelect?()
    }
}
