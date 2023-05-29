//
//  Font+Ext.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/23/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

extension UIFont {
    
    static func regularLockdownFont(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Regular", size: size) ?? .systemFont(ofSize: size, weight: .regular)
    }
    
    static func mediumLockdownFont(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Medium", size: size) ?? .systemFont(ofSize: size, weight: .medium)
    }
    
    static func semiboldLockdownFont(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-SemiBold", size: size) ?? .systemFont(ofSize: size, weight: .semibold)
    }
    
    static func boldLockdownFont(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Bold", size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
}
