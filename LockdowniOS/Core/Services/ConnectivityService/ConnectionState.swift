//
//  ConnectionState.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/6/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

enum ConnectionState {
    case unknown, satisfied, restrictedCellular, noConnection
    
    var errorMessage: String? {
        switch self {
        case .unknown, .satisfied:
            return nil
        case .restrictedCellular:
            return "Enable Cellular Data for Lockdown"
        case .noConnection:
            return .localized("No Internet Connection")
        }
    }
    
    var color: UIColor {
        if self == .noConnection {
            return .orange
        }
        return .red
    }
}
