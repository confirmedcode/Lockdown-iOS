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
        label.font = .regularLockdownFont(size: 14)
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
        addSubview(switcher)
        switcher.anchors.leading.pin(inset: 26)
        switcher.anchors.size.equal(.init(width: 13, height: 13))

        addSubview(titleLabel)
        switcher.anchors.centerY.equal(titleLabel.anchors.centerY)
        titleLabel.anchors.leading.spacing(9, to: switcher.anchors.trailing)
        titleLabel.anchors.top.pin(inset: 8)
        titleLabel.anchors.bottom.pin(inset: 8)
        titleLabel.anchors.trailing.pin(inset: 18)
        
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped))
        )
    }
    
    private func updateView() {
        switcher.isSelected = isSelected
    }
    
    @objc private func tapped() {
        didSelect?(!isSelected)
    }

}
