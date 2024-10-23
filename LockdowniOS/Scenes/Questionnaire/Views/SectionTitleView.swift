//
//  SectionTitleView.swift
//  Lockdown
//
//  Created by Fabian Mistoiu on 14.10.2024.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import UIKit

class SectionTitleView: UIView {

    var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .semiboldLockdownFont(size: 14)
        label.numberOfLines = 0
        label.textColor = .label
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
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

    }
}
