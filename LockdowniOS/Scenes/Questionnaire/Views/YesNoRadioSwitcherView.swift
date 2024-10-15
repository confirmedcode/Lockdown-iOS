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
        label.font = .semiboldLockdownFont(size: 14)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private lazy var yesSwitcher: RadioSwitcher = {
        let view = RadioSwitcher()
        view.didSelect = { [weak self] in self?.isSelected = $0 ? true : nil }
        return view
    }()
    
    private lazy var yesLabel: UILabel = {
        let label = UILabel()
        label.font = .regularLockdownFont(size: 14)
        label.textColor = .label
        label.text = NSLocalizedString("Yes", comment: "")
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var noSwitcher: RadioSwitcher = {
        let view = RadioSwitcher()
        view.didSelect = { [weak self] in self?.isSelected = $0 ? false : nil }
        return view
    }()
    
    private lazy var noLabel: UILabel = {
        let label = UILabel()
        label.font = .regularLockdownFont(size: 14)
        label.textColor = .label
        label.text = NSLocalizedString("No", comment: "")
        label.isUserInteractionEnabled = true
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
        stackView.alignment = .fill
        addSubview(stackView)
        stackView.anchors.top.spacing(12, to: titleLabel.anchors.bottom)
        stackView.anchors.leading.pin(inset: 23)
        stackView.anchors.trailing.pin()
        stackView.anchors.bottom.pin()
        stackView.anchors.height.equal(23)

        let yesView = view(for: yesSwitcher, andLabel: yesLabel)
        yesView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedYes)))
        stackView.addArrangedSubview(yesView)

        let noView = view(for: noSwitcher, andLabel: noLabel)
        noView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedNo)))
        stackView.addArrangedSubview(noView)
    }
    
    private func view(for switcher: RadioSwitcher, andLabel label: UILabel) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        view.addSubview(switcher)
        switcher.anchors.leading.pin()
        switcher.anchors.centerY.equal(view.anchors.centerY)
        switcher.anchors.size.equal(.init(width: 13, height: 13))

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

    @objc private func tappedYes() {
        yesSwitcher.toggle()
    }

    @objc private func tappedNo() {
        noSwitcher.toggle()
    }
}
