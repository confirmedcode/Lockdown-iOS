//
//  String+Localized.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 6/20/22.
//  Copyright © 2022 Confirmed Inc. All rights reserved.
//

import Foundation

public extension String {
    
    static func localized(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }
    
    func localized(comment: String = "", inserting arguments: CVarArg...) -> String {
        let localizedString = NSLocalizedString(self, comment: comment)
        return String(format: localizedString, arguments: arguments)
    }
    
    static let localizedSignOut = NSLocalizedString("Sign Out", comment: "")
    static let localizedCancel = NSLocalizedString("Cancel", comment: "")
    static let localizedOK = NSLocalizedString("OK", comment: "")
    static let localizedOkay = NSLocalizedString("Okay", comment: "")
}
