//
//  EditDomainsCell.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 05.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class EditDomainsCell: UIView {
    
    struct Contents {
        let checkMark: UIImage?
        let icon: UIImage?
        let title: String?
        let status: String?
        
        static func userBlocked(domain: String, isUnselected: Bool) -> Contents {
            let checkMark = isUnselected ? UIImage(systemName: "circle") : UIImage(systemName: "checkmark.circle.fill")
            let image = UIImage(named: "website_icon.png")
            let status = NSLocalizedString("Blocked", comment: "")
            return Contents(checkMark: checkMark, icon: image, title: domain, status: status)
        }
    }
    
    var contents: Contents = Contents(checkMark: nil, icon: nil, title: nil, status: nil) {
        didSet {
            checkMarkView.image = contents.checkMark
            imageView.image = contents.icon
            groupNameLabel.text = contents.title
            statusLabel.text = contents.status
        }
    }
    
    private let checkMarkView = UIImageView()
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
        addSubview(checkMarkView)
        checkMarkView.anchors.size.equal(.init(width: 24, height: 24))
        checkMarkView.anchors.leading.marginsPin(inset: 8)
        checkMarkView.anchors.centerY.align()
        
        addSubview(imageView)
        do {
            imageView.anchors.size.equal(.init(width: 24, height: 24))
            imageView.anchors.leading.spacing(10, to: checkMarkView.anchors.trailing)
            imageView.anchors.centerY.align()
        }
        
        groupNameLabel.text = contents.title
        groupNameLabel.font = fontRegular14
        groupNameLabel.numberOfLines = 0
        
        addSubview(groupNameLabel)
        do {
            groupNameLabel.anchors.leading.spacing(10, to: imageView.anchors.trailing)
            groupNameLabel.anchors.top.marginsPin(inset: 8)
            groupNameLabel.anchors.bottom.marginsPin(inset: 8)
            groupNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        
        statusLabel.font = fontRegular14
        statusLabel.text = contents.status
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
