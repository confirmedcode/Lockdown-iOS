//
//  String+Attributed.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/29/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

extension UILabel {
    
    func highlight(_ strings: String...,
                   with color: UIColor? = nil,
                   font: UIFont? = nil,
                   lineSpacing: CGFloat? = nil,
                   characterSpacing: UInt? = nil) {
        guard let text else { return }
        let attributedString = NSMutableAttributedString(string: text)
        
        for string in strings {
            let range = (text as NSString).range(of: string)
            if let color {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
            }
            if let font {
                attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: range)
            }
        }
        
        if let lineSpacing {
            let paragraphStyle = NSMutableParagraphStyle()
            
            paragraphStyle.lineSpacing = lineSpacing
            paragraphStyle.alignment = textAlignment

            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        }
        
        attributedText = attributedString

        guard let characterSpacing else { return }

        attributedString.addAttribute(NSAttributedString.Key.kern, value: characterSpacing, range: NSRange(location: 0, length: attributedString.length))
        attributedText = attributedString
    }
}
