//
//  ConnectionState.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 11.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
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
