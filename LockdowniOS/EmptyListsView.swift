//
//  NothingBlockedView.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 21.03.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class EmptyListsView: UIView {
    
    var descriptionText: String = "" {
        didSet {
            descriptionLabel.text = descriptionText
        }
    }
    
    var buttonTitle: String = "" {
        didSet {
            addButton.setTitle(buttonTitle, for: .normal)
        }
    }
    
    private(set) var buttonCallback: () -> () = { }
    
    @discardableResult
    func onButtonPressed(_ callback: @escaping () -> ()) -> Self {
        buttonCallback = callback
        return self
    }
    
    // MARK: - Properties
    
    lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(addButton)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 4
        return stackView
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.textAlignment = .center
        label.font = fontBold13
        label.textAlignment = .center
        return label
    }()
    
    lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .tunnelsBlue
        button.backgroundColor = .tunnelsLightBlue
        button.titleLabel?.font = fontBold13
        button.layer.cornerRadius = 8
        button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
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
        addSubview(addButton)
        addButton.anchors.width.greaterThanOrEqual(120)
        
        addSubview(stackView)
        stackView.anchors.top.marginsPin()
        stackView.anchors.bottom.marginsPin()
        stackView.anchors.leading.marginsPin()
        stackView.anchors.trailing.marginsPin()
    }
    
    // - MARK: Functions
    
    @objc func buttonDidPress() {
        buttonCallback()
    }
}
