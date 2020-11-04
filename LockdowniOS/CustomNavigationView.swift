//
//  CustomNavigationView.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 23.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import UIKit

final class CustomNavigationView: UIView {
    
    var title: String = "" {
        didSet {
            titleView.text = title
        }
    }
    
    var buttonTitle: String = NSLocalizedString("SAVE", comment: "") {
        didSet {
            button.setTitle(buttonTitle, for: .normal)
        }
    }
    
    private(set) var buttonCallback: () -> () = { }
    
    @discardableResult
    func onButtonPressed(_ callback: @escaping () -> ()) -> CustomNavigationView {
        buttonCallback = callback
        return self
    }
    
    private let titleView = UILabel()
    private let button = UIButton(type: .system)
    
    init() {
        super.init(frame: .zero)
        didLoad()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didLoad() {
        addSubview(titleView)
        titleView.textAlignment = .left
        titleView.text = title
        titleView.font = fontMedium17
        
        titleView.anchors.leading.marginsPin(inset: 20)
        titleView.anchors.width.greaterThanOrEqual(220)
        titleView.anchors.height.equal(24)
        titleView.anchors.top.pin(inset: 18)
        
        addSubview(button)
        button.titleLabel?.font = fontBold13
        button.contentHorizontalAlignment = .trailing
        button.tintColor = .confirmedBlue
        button.setTitle(buttonTitle, for: .normal)
        
        button.anchors.centerY.equal(titleView.anchors.centerY)
        button.anchors.trailing.marginsPin(inset: 8)
        button.anchors.bottom.marginsPin()
        button.anchors.height.equal(39)
        button.anchors.width.greaterThanOrEqual(60)
        
        button.addTarget(self, action: #selector(buttonDidPress), for: .touchUpInside)
    }
    
    @objc
    func buttonDidPress() {
        buttonCallback()
    }
}
