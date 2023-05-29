//
//  UIStackView+Ext.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/5/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

extension UIStackView {
    
    func clear() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
