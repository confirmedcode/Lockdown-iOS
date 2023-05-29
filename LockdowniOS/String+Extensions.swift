//
//  String+Extentions.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 25.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import Foundation

extension String {
    
    enum ValidityType {
        case listName
        case domainName
        case listDescription
    }
    
    enum Regex: String {
        case listName = "^[a-zA-Z0-9\\s]{1,30}$"
        case domainName = "^([a-zA-Z0-9]+(\\.[a-zA-Z0-9]+)+.*)$"
        case listDescription = "^[a-zA-Z0-9\\s]{1,500}$"
    }
    
    func isValid(_ validityType: ValidityType) -> Bool {
        let format = "SELF MATCHES %@"
        var regex = ""
        
        switch validityType {
        case .listName:
            regex = Regex.listName.rawValue
        case .domainName:
            regex = Regex.domainName.rawValue
        case .listDescription:
            regex = Regex.listDescription.rawValue
        }
        
        return NSPredicate(format: format, regex).evaluate(with: self)
    }
}
