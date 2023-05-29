//
//  UIAppearance+Ext.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 1/13/23
//  Copyright © 2023 Confirmed Inc. All rights reserved.
// 

import PopupDialog
import UIKit

final class LockdownAppearance {
    
    static func configure() {
        configurePopupDialog()
        configureTabBar()
    }
    
    private static func configurePopupDialog() {
        let dialogAppearance = PopupDialogDefaultView.appearance()
        dialogAppearance.backgroundColor = .systemBackground
        dialogAppearance.titleColor = .label
        dialogAppearance.messageColor = .label
        dialogAppearance.titleFont            = .boldLockdownFont(size: 15)
        dialogAppearance.titleTextAlignment   = .center
        dialogAppearance.messageFont          = .mediumLockdownFont(size: 15)
        dialogAppearance.messageTextAlignment = .center
        
        [DefaultButton.appearance(),
         DynamicButton.appearance(),
         CancelButton.appearance()].forEach { appearance in
            appearance.buttonColor = .systemBackground
            appearance.separatorColor = UIColor(white: 0.2, alpha: 1)
            appearance.titleFont      = .semiboldLockdownFont(size: 17)
            appearance.titleColor     = .tunnelsBlue
        }
        
        CancelButton.appearance().titleColor = .lightGray
    }
    
    private static func configureTabBar() {
        let textAttributes = [NSAttributedString.Key.font: UIFont.semiboldLockdownFont(size: 11)]
        
        UITabBarItem.appearance().setTitleTextAttributes(textAttributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(textAttributes, for: .selected)
        
        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.normal.titleTextAttributes = textAttributes
        tabBarItemAppearance.selected.titleTextAttributes = textAttributes
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        tabBarAppearance.shadowImage = nil
        tabBarAppearance.shadowColor = nil
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
    }
}
