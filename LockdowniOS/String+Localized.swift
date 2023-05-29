//
//  String+Localized.swift
//  LockdowniOS
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
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
