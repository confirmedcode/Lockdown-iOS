//
//  BottomMenu.swift
//  LockdownSandbox
//
//  Created by Aliaksandr Dvoineu on 26.04.23.
//

import UIKit

final class BottomMenu: UIView {
    
    private(set) var buttonCallback: () -> () = { }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 8
    }
    
    @discardableResult
    func onButtonPressed(_ callback: @escaping () -> ()) -> Self {
        buttonCallback = callback
        return self
    }
    
    lazy var leftButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .tunnelsBlue
        button.setTitle(NSLocalizedString("Select All", comment: ""), for: .normal)
        button.titleLabel?.font = fontMedium15
        return button
    }()
    
    lazy var middleButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .tunnelsBlue
//        button.titleLabel?.textColor = .tunnelsBlue
        button.titleLabel?.font = fontMedium15
        button.setTitle(NSLocalizedString("Move to List", comment: ""), for: .normal)
        return button
    }()
    
    lazy var rightButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .red
//        button.titleLabel?.textColor = .red
        button.titleLabel?.font = fontMedium15
        button.setTitle(NSLocalizedString("Delete", comment: ""), for: .normal)
        return button
    }()
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        return view
    }()
    
    lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(leftButton)
        stackView.addArrangedSubview(middleButton)
        stackView.addArrangedSubview(rightButton)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .leading
        return stackView
    }()
    
    private func configure() {
        addSubview(backgroundView)
        backgroundView.anchors.height.equal(60)
        backgroundView.anchors.leading.pin()
        backgroundView.anchors.trailing.pin()
        backgroundView.anchors.bottom.pin()

        addSubview(stackView)
        stackView.anchors.edges.pin()
    }
}
