//
//  UIView+Ext.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/6/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation
import UIKit

extension UIView {
    
    // MARK: - Gradient
    
    @discardableResult
    func applyGradient(_ gradient: LockdownGradient, corners: Corners = .continuous(0)) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradient.colors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        gradientLayer.frame = bounds
        gradientLayer.corners = corners
        
        self.corners = corners
        
        layer.sublayers?.first(where: { $0 is CAGradientLayer })?.removeFromSuperlayer()
        layer.insertSublayer(gradientLayer, at: 0)
        
        return gradientLayer
    }
    
    // MARK: - Animation
    
    func showAnimatedPress(duration: Double = 0.1, withScale scale: CGFloat = 0.95, completion: (() -> Void)? = nil) {
        isUserInteractionEnabled = false
        UIView.animate(withDuration: duration, animations: {
            self.transformToScale(scale)
        }) { (_) in
            UIView.animate(withDuration: duration, animations: {
                self.transformToIdentity()
            }) { (_) in
                self.isUserInteractionEnabled = true
                completion?()
            }
        }
    }
    
    func transformToIdentity() {
        self.transform = CGAffineTransform.identity
    }
    
    private func transformToScale(_ scale: CGFloat) {
        transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    
    func fadeIn(duration: CGFloat, completion: (() -> Void)? = nil) {
        self.alpha = 0
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
        }, completion: { isContinued in
            guard isContinued else { return }
            completion?()
        })
    }
    
    func fadeOut(duration: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
        }, completion: { isContinued in
            guard isContinued else { return }
            completion?()
        })
    }
    
    func fadeOutAsDiminished(duration: CGFloat, delay: CGFloat = 0, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: delay, animations: {
            self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.alpha = 0
        }, completion: { isContinued in
            guard isContinued else { return }
            completion?()
        })
    }
    
    func animateBorderWidth(toValue: CGFloat, duration: Double = 0.4, color: UIColor = .fromHex("#00ADE7")) {
        let animation = CABasicAnimation(keyPath: "borderWidth")
        animation.fromValue = layer.borderWidth
        animation.toValue = toValue
        animation.duration = duration
        layer.borderColor = color.cgColor
        layer.add(animation, forKey: "Width")
        layer.borderWidth = toValue
    }
    
    // MARK: - Shadow
    
    func dropShadow() {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = layer.cornerRadius
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
}

extension UIColor {
    
    static func fromHex(_ hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if (cString.count) != 6 {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
