//
//  CustomTableHeader.swift
//  LockdownSandbox
//
//  Created by Aliaksandr Dvoineu on 24.03.23.
//

import UIKit

enum Section: Int, CaseIterable, CustomStringConvertible {
    
    case lists
    case domains
    
    var description: String {
        switch self {
        case .lists: return "Lists"
        case .domains: return "Domains"
        }
    }
}

class CustomBlockedTableHeader: UITableViewHeaderFooterView {
    static let id = "CustomBlockedTableHeader"
    
    private(set) var addButtonCallback: () -> () = { }
    private(set) var editButtonCallback: () -> () = { }
    
    lazy var listsTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        label.font = fontBold18
        return label
    }()
    
    lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold, scale: .large)
        button.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig), for: .normal)
        button.tintColor = .tunnelsBlue
        button.addTarget(self, action: #selector(addButtonDidPress), for: .touchUpInside)
        return button
    }()
    
    lazy var editButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold, scale: .large)
        button.setImage(UIImage(named: "icn_edit"), for: .normal)
        button.tintColor = .tunnelsBlue
        button.addTarget(self, action: #selector(editButtonDidPress), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    var category: Section = .lists {
        didSet {
            switch category {
            case .lists:
                listsTitleLabel.text = category.description
                
            case .domains:
                listsTitleLabel.text = category.description
            }
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    func configure() {
        contentView.addSubview(listsTitleLabel)
        contentView.addSubview(addButton)
        contentView.addSubview(editButton)
        
        listsTitleLabel.anchors.leading.pin()
        listsTitleLabel.anchors.bottom.marginsPin()
        
        addButton.anchors.trailing.pin()
        addButton.anchors.bottom.marginsPin()
        
        editButton.anchors.trailing.spacing(12, to: addButton.anchors.leading)
        editButton.anchors.bottom.marginsPin()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    func onAddButtonPressed(_ callback: @escaping () -> ()) -> Self {
        addButtonCallback = callback
        return self
    }
    
    @discardableResult
    func onEditButtonPressed(_ callback: @escaping () -> ()) -> Self {
        editButtonCallback = callback
        return self
    }
    
    @objc func addButtonDidPress() {
        addButtonCallback()
    }
    
    @objc func editButtonDidPress() {
        editButtonCallback()
    }
}
