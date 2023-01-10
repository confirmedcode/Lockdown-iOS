//
//  BlocklistCell.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class BlockListView: UIView {
    
    struct Contents {
        let image: UIImage?
        let title: String?
        let status: String?
        
        static func lockdownGroup(_ lockdownGroup: LockdownGroup) -> Contents {
            let image = UIImage(named: lockdownGroup.iconURL) ?? UIImage(named: "website_icon.png")
            let status: String = lockdownGroup.enabled ? .localized("Blocked") : .localized("Not Blocked")
            return Contents(image: image, title: lockdownGroup.name, status: status)
        }
        
        static func userBlocked(domain: String, isEnabled: Bool) -> Contents {
            let image = UIImage(named: "website_icon.png")
            let status: String = isEnabled ? .localized("Blocked", comment: "") : .localized("Not Blocked")
            return Contents(image: image, title: domain, status: status)
        }
    }
    
    var contents: Contents = Contents(image: nil, title: nil, status: nil) {
        didSet {
            imageView.image = contents.image
            groupNameLabel.text = contents.title
            statusLabel.text = contents.status
        }
    }
    
    private let imageView = UIImageView()
    private let groupNameLabel = UILabel()
    private let statusLabel = UILabel()
    
    init() {
        super.init(frame: .zero)
        self.didLoad()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didLoad() {
        addSubview(imageView)
        do {
            imageView.anchors.size.equal(.init(width: 24, height: 24))
            imageView.anchors.leading.marginsPin(inset: 8)
            imageView.anchors.centerY.align()
        }
        
        groupNameLabel.text = contents.title
        groupNameLabel.font = .regularLockdownFont(size: 14)
        groupNameLabel.numberOfLines = 0
        addSubview(groupNameLabel)
        do {
            groupNameLabel.anchors.leading.spacing(10, to: imageView.anchors.trailing)
            groupNameLabel.anchors.top.marginsPin(inset: 8)
            groupNameLabel.anchors.bottom.marginsPin(inset: 8)
            groupNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        
        statusLabel.font = .regularLockdownFont(size: 14)
        statusLabel.text = contents.status
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.textAlignment = .right
        addSubview(statusLabel)
        do {
            statusLabel.anchors.trailing.marginsPin(inset: 4)
            statusLabel.anchors.width.equal(110)
            statusLabel.anchors.leading.spacing(0, to: groupNameLabel.anchors.trailing)
            statusLabel.anchors.centerY.equal(groupNameLabel.anchors.centerY)
            statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        }
    }
}
