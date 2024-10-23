//
//  ImageBannerWithTitleView.swift
//  Lockdown
//
//  Created by Fabian Mistoiu on 14.10.2024.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import UIKit

class ImageBannerWithTitleView: UIView {
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldLockdownFont(size: 32)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()

    var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .mediumLockdownFont(size: 14)
        label.textAlignment = .center
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

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 207),
            imageView.heightAnchor.constraint(equalToConstant: 178),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: -25),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -4),

            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
