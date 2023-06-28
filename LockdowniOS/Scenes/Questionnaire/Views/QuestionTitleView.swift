//
//  QuestionTitleView.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 26.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class QuestionTitleView: UIView {
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .semiboldLockdownFont(size: 16)
        label.numberOfLines = 0
        label.textColor = .black
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
        titleLabel.anchors.top.pin()
        titleLabel.anchors.trailing.pin()
        titleLabel.anchors.leading.pin()
        titleLabel.anchors.bottom.pin()
    }

}
