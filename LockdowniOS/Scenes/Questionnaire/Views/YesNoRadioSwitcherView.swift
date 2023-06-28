//
//  YesNoRadioSwitcherView.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 26.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class YesNoRadioSwitcherView: UIView {

    var isSelected: Bool? {
        didSet {
            updateView()
            didSelect?(isSelected)
        }
    }
    var didSelect: ((Bool?) -> Void)?

    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .semiboldLockdownFont(size: 16)
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()
    
    private lazy var yesSwitcher: RadioSwitcher = {
        let view = RadioSwitcher()
        view.didSelect = { [weak self] in self?.isSelected = $0 ? true : nil }
        return view
    }()
    
    private lazy var yesLabel: UILabel = {
        let label = UILabel()
        label.font = .regularLockdownFont(size: 16)
        label.textColor = .black
        label.text = NSLocalizedString("Yes", comment: "")
        return label
    }()
    
    private lazy var noSwitcher: RadioSwitcher = {
        let view = RadioSwitcher()
        view.didSelect = { [weak self] in self?.isSelected = $0 ? false : nil }
        return view
    }()
    
    private lazy var noLabel: UILabel = {
        let label = UILabel()
        label.font = .regularLockdownFont(size: 16)
        label.textColor = .black
        label.text = NSLocalizedString("No", comment: "")
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
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .leading
        addSubview(stackView)
        stackView.anchors.top.spacing(15, to: titleLabel.anchors.bottom)
        stackView.anchors.leading.pin()
        stackView.anchors.trailing.pin()
        stackView.anchors.bottom.pin()
        stackView.anchors.height.equal(20)
        
        stackView.addArrangedSubview(view(for: yesSwitcher, andLabel: yesLabel))
        stackView.addArrangedSubview(view(for: noSwitcher, andLabel: noLabel))
    }
    
    private func view(for switcher: RadioSwitcher, andLabel label: UILabel) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        view.addSubview(switcher)
        switcher.anchors.leading.pin()
        switcher.anchors.centerY.equal(view.anchors.centerY)
        switcher.anchors.size.equal(.init(width: 25, height: 25))
        
        view.addSubview(label)
        label.anchors.top.pin()
        label.anchors.leading.spacing(10, to: switcher.anchors.trailing)
        label.anchors.trailing.pin()
        label.anchors.bottom.pin()
        
        return view
    }
    
    private func updateView() {
        yesSwitcher.isSelected = isSelected ?? false
        noSwitcher.isSelected = !(isSelected ?? true)
    }
}
