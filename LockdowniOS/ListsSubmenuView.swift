//
//  ListsSubmenuView.swift
//  LockdownSandbox
//
//  Created by Aliaksandr Dvoineu on 23.03.23.
//

import UIKit

final class ListsSubmenuView: UIView {
    
    private(set) var buttonCallback: () -> () = { }
    
    @discardableResult
    func onButtonPressed(_ callback: @escaping () -> ()) -> Self {
        buttonCallback = callback
        return self
    }
    
    // MARK: - Properties
    
    lazy var topButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .tunnelsBlue
        button.setTitle("Create New List...", for: .normal)
        button.setImage(UIImage(named: "icn_create_list"), for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        return button
    }()
    
    lazy var bottomButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .tunnelsBlue
        button.setTitle("Import Block List...", for: .normal)
        button.setImage(UIImage(named: "icn_import_list"), for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        return button
    }()
    
    lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(topButton)
        stackView.addArrangedSubview(bottomButton)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .leading
        stackView.spacing = 12
        return stackView
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    func configure() {
        backgroundColor = .systemBackground
        
        addSubview(stackView)
        stackView.anchors.top.marginsPin()
        stackView.anchors.bottom.marginsPin()
        stackView.anchors.leading.marginsPin(inset: 10)
        stackView.anchors.trailing.marginsPin(inset: 16)
    }
     
    @objc func buttonDidPress() {
        buttonCallback()
    }
}
