//
//  DomainsBlockedTableViewCell.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 28.03.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class DomainsBlockedTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    static let identifier = "DomainsBlockedTableViewCell"
    
    var isBlocked = true
    
    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.tintColor = .gray
        view.contentMode = .scaleAspectFit
        view.image = UIImage(systemName: "globe")
        return view
    }()
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = fontRegular14
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = fontRegular14
        label.text = isBlocked ? "Blocked" : "Not Blocked"
        label.textColor = .gray
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        confugureUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        iconImageView.image = nil
        label.text = nil
//        statusLabel.text = nil
    }
    
    private func confugureUI() {
        contentView.addSubview(iconImageView)
        iconImageView.anchors.top.marginsPin()
        iconImageView.anchors.bottom.marginsPin()
        iconImageView.anchors.leading.pin(inset: 8)
        
        contentView.addSubview(label)
        label.anchors.top.marginsPin()
        label.anchors.leading.spacing(8, to: iconImageView.anchors.trailing)
        label.anchors.bottom.marginsPin()
        
        contentView.addSubview(statusLabel)
        statusLabel.anchors.top.marginsPin()
        statusLabel.anchors.trailing.marginsPin()
        statusLabel.anchors.bottom.marginsPin()
        
        contentView.clipsToBounds = true
        accessoryType = .none
    }
}
