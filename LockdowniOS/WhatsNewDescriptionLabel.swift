//
//  WhatsNewDescriptionLabel.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 30.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

struct WhatsNewDescriptionLabelViewModel {
    let text: String
}

final class WhatsNewDescriptionLabel: UIView {
    
    // MARK: - Properties
    
    private lazy var checkmarkImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "icn_checkmark")
        image.contentMode = .left
        image.layer.masksToBounds = true
        image.isHidden = true
        return image
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontMedium15
        label.textAlignment = .left
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(checkmarkImage)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        stackView.spacing = 12
        return stackView
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    private func configureUI() {
        
        addSubview(stackView)
        stackView.anchors.top.pin()
        stackView.anchors.bottom.pin()
        stackView.anchors.leading.pin()
        stackView.anchors.trailing.pin()
    }
    
    func configure(with model: WhatsNewDescriptionLabelViewModel) {
        descriptionLabel.text = model.text
    }
}

