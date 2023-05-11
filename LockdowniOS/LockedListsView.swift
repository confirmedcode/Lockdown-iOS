//
//  LockedListsView.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 10.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class LockedListsView: UIView {
    
    // MARK: - Properties
    
    private lazy var image: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "icn_lock")
        image.contentMode = .scaleAspectFit
        image.layer.masksToBounds = true
        return image
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Upgrade to unlock lists"
        label.textColor = .lightGray
        label.textAlignment = .center
        label.font = fontBold13
        label.textAlignment = .center
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(image)
        stackView.addArrangedSubview(descriptionLabel)
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
        
        addSubview(stackView)
        stackView.anchors.top.marginsPin()
        stackView.anchors.bottom.marginsPin()
        stackView.anchors.leading.marginsPin()
        stackView.anchors.trailing.marginsPin()
    }
}

