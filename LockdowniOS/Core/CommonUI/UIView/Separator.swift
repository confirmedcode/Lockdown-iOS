//
//  Separator.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/5/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

final class Separator: UIView {
    
    var height: CGFloat {
        didSet {
            heightConstraint?.constant = height
        }
    }
    
    private var heightConstraint: NSLayoutConstraint?
    
    init(height: CGFloat = 1) {
        self.height = height
        
        super.init(frame: .zero)
        
        backgroundColor = .lightGray.withAlphaComponent(0.3)
        
        heightConstraint = heightAnchor.constraint(equalToConstant: height)
        heightConstraint?.isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
