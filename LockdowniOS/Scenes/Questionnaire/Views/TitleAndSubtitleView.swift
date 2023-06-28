//
//  TitleAndSubtitleView.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 22.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class TitleAndSubtitleView: UIView {

    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldLockdownFont(size: 34)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .mediumLockdownFont(size: 16)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        backgroundColor = .clear
        
        addSubview(titleLabel)
        titleLabel.anchors.leading.pin()
        titleLabel.anchors.top.pin()
        titleLabel.anchors.trailing.pin()
        
        addSubview(subtitleLabel)
        subtitleLabel.anchors.leading.pin()
        subtitleLabel.anchors.top.spacing(10, to: titleLabel.anchors.bottom)
        subtitleLabel.anchors.trailing.pin()
        subtitleLabel.anchors.bottom.pin()
    }
}
