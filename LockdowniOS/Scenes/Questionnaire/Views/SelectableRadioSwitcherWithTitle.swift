//
//  SelectableRadioSwitcherWithTitle.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 22.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class SelectableRadioSwitcherWithTitle: UIView {
    
    var isSelected = false {
        didSet {
            updateView()
        }
    }
    var didSelect: ((Bool) -> Void)?
    
    var unselectedBackgroundColor = UIColor.tableCellBackground
    var selectedBackgroundColor = UIColor.tableCellSelectedBackground
    var selectedBorderColor = UIColor.tunnelsBlue
    
    private lazy var switcher: RadioSwitcher = {
        let view = RadioSwitcher()
        view.didSelect = { [weak self] _ in self?.tapped() }
        return view
    }()
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .semiboldLockdownFont(size: 16)
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
        backgroundColor = unselectedBackgroundColor
        layer.cornerRadius = 8
        layer.borderWidth = 0
        
        addSubview(switcher)
        switcher.anchors.leading.pin(inset: 18)
        switcher.anchors.size.equal(.init(width: 20, height: 20))
        
        addSubview(titleLabel)
        switcher.anchors.centerY.equal(titleLabel.anchors.centerY)
        titleLabel.anchors.leading.spacing(22, to: switcher.anchors.trailing)
        titleLabel.anchors.top.pin(inset: 18)
        titleLabel.anchors.bottom.pin(inset: 18)
        titleLabel.anchors.trailing.pin(inset: 18)
        
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped))
        )
    }
    
    private func updateView() {
        switcher.isSelected = isSelected
        backgroundColor = isSelected ? selectedBackgroundColor : unselectedBackgroundColor
        layer.borderColor = (isSelected ? selectedBorderColor : .clear).cgColor
        layer.borderWidth = isSelected ? 1 : 0
    }
    
    @objc private func tapped() {
        didSelect?(!isSelected)
    }

}
