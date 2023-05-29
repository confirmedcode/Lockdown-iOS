//
//  UIViewController+Ext.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/4/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

extension UIViewController {
    
    // MARK: - Common Animation
    func transition(with view: UIView,
                    duration: CGFloat = 0.4,
                    options: UIView.AnimationOptions = [.transitionCrossDissolve],
                    completion: @escaping () -> Void) {
        UIView.transition(with: view, duration: duration, options: options) {
            completion()
        }
    }
    
    // MARK: - Dark Mode
    
    var isDarkMode: Bool { traitCollection.userInterfaceStyle == .dark }
    
    // MARK: - Idiom
    
    var isPad: Bool { traitCollection.userInterfaceIdiom == .pad }
}
