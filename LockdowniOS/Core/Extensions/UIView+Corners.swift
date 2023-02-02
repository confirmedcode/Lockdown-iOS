//
//  UIView+Corners.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/28/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

/// Better set cornerRadius using this property for smooth corners
enum Corners {
    /// Preferable (for smoothness)
    case continuous(CGFloat)
    
    case circular(CGFloat)
}

extension Corners {
    var radius: CGFloat {
        switch self {
        case .circular(let radius), .continuous(let radius):
            return radius
        }
    }
}

extension UIView {
    var corners: Corners {
        get {
            let radius = layer.cornerRadius
            return layer.cornerCurve == .continuous ? .continuous(radius) : .circular(radius)
        }
        set {
            switch newValue {
            case .circular:
                layer.cornerCurve = .circular
            case .continuous:
                layer.cornerCurve = .continuous
            }
            layer.cornerRadius = newValue.radius
        }
    }
}

extension CALayer {
    var corners: Corners {
        get {
            return cornerCurve == .continuous ? .continuous(cornerRadius) : .circular(cornerRadius)
        }
        set {
            switch newValue {
            case .circular:
                cornerCurve = .circular
            case .continuous:
                cornerCurve = .continuous
            }
            cornerRadius = newValue.radius
        }
    }
}
