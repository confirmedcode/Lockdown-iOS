//
//  ConfiguredNavigationView.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 1.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class ConfiguredNavigationView: UIView {
    
    private(set) var buttonCallback: () -> () = { }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontMedium17
        label.textAlignment = .center
        return label
    }()
    
    lazy var leftNavButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = fontBold13
        button.tintColor = .tunnelsBlue
        button.addTarget(self, action: #selector(buttonDidPress), for: .touchUpInside)
        return button
    }()
    
    lazy var rightNavButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = fontBold13
        button.tintColor = .tunnelsBlue
        button.addTarget(self, action: #selector(buttonDidPress), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(frame: .zero)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI() {
        addSubview(titleLabel)
        titleLabel.anchors.leading.marginsPin(inset: 20)
        titleLabel.anchors.trailing.marginsPin(inset: 20)
        titleLabel.anchors.top.pin(inset: 18)
        
        addSubview(leftNavButton)
        leftNavButton.anchors.centerY.equal(titleLabel.anchors.centerY)
        leftNavButton.anchors.leading.marginsPin(inset: 8)
        leftNavButton.anchors.bottom.marginsPin()
        
        addSubview(rightNavButton)
        rightNavButton.anchors.centerY.equal(titleLabel.anchors.centerY)
        rightNavButton.anchors.trailing.marginsPin(inset: 8)
        rightNavButton.anchors.bottom.marginsPin()
    }
    
    @objc func buttonDidPress() {
        buttonCallback()
    }
}
