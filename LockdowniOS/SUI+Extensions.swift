//
//  SUI+Extensions.swift
//  Lockdown
//
//  Created by Radu Lazar on 05.08.2024.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
