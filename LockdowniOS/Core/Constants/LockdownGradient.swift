//
//  LockdownGradient.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/28/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

enum LockdownGradient {
    case lightBlue
    case onboardingBlue
    case onboardingPurple
    case ltoButtonOnHomePage
    case custom([CGColor])
    
    var colors: [CGColor] {
        switch self {
        case .lightBlue:
            return [
                UIColor.fromHex("#00B6F3").cgColor,
                UIColor.fromHex("#0092CC").cgColor,
                UIColor.fromHex("#0083B7").cgColor
            ]
        case .onboardingBlue:
            return [UIColor.fromHex("#1188E4").cgColor, UIColor.fromHex("#076BB8").cgColor]
        case .onboardingPurple:
            return [UIColor.fromHex("#AA68FE").cgColor, UIColor.fromHex("#671AC9").cgColor]
        case .ltoButtonOnHomePage:
            return [UIColor.fromHex("#FFFFFF00").withAlphaComponent(0).cgColor,
                    UIColor.fromHex("#FFFFFF4D").withAlphaComponent(0.3).cgColor]
        case .custom(let colors):
            return colors
        }
    }
}
