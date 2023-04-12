//
//  ListBlockedTableViewCell.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 28.03.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class ListBlockedTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    static let identifier = "ListBlockedTableViewCell"
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = fontRegular14
        label.textColor = .label
        label.numberOfLines = 1
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
    
    private func confugureUI() {
        
        contentView.addSubview(label)
        label.anchors.top.marginsPin()
        label.anchors.leading.marginsPin()
        label.anchors.bottom.marginsPin()
        
        contentView.clipsToBounds = true
        accessoryType = .disclosureIndicator
    }
    
    func configure(with model: ListSettingsOption) {
        label.text = model.title
    }
}
