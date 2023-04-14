//
//  SwitchBlockingView.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 28.03.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class SwitchBlockingView: UIView {
    
    private(set) var buttonCallback: () -> () = { }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .left
        label.font = fontMedium14
        return label
    }()
    
    lazy var switchView: UISwitch = {
        let view = UISwitch()
        view.onTintColor = .tunnelsBlue
        view.isOn = true
        return view
    }()
    
    func configure() {
        backgroundColor = .systemBackground
        
        addSubview(titleLabel)
        titleLabel.anchors.leading.marginsPin()
        titleLabel.anchors.top.marginsPin()
        titleLabel.anchors.bottom.marginsPin()
        
        addSubview(switchView)
        switchView.anchors.trailing.marginsPin()
        switchView.anchors.centerY.equal(titleLabel.anchors.centerY)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 8
    }
    
    @objc func buttonDidPress() {
        buttonCallback()
    }
}
