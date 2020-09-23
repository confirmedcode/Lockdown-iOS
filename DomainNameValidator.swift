//
//  DomainNameValidator.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 19.05.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation

enum DomainNameValidator {
    
    enum Status {
        case valid
        case notValid(FailureReason)
        
        // Not currently shown to the user, but can be leveraged in the future
        enum FailureReason {
            case emptyString
            case noDots
            case invalidCharacters(in: String)
            case labelEmpty
        }
    }
    
    /// All "url host allowed" characters with the exception of the wildcard symbol
    static let allowedChars = CharacterSet.urlHostAllowed
        .subtracting(CharacterSet(charactersIn: "*"))
    
    static func validate(_ domainName: String) -> Status {
        
        guard domainName.isEmpty == false else {
            return .notValid(.emptyString)
        }
        
        var labels = domainName.components(separatedBy: ".")
        guard labels.count > 1 else {
            return .notValid(.noDots)
        }
        
        // Wildcard is allowed only as a first label.
        // If first label is a wildcard, we're removing
        // it from the elements to validate
        if labels.first == "*" {
            labels.removeFirst()
        }
        
        for label in labels {
            guard label.isEmpty == false else {
                return .notValid(.labelEmpty)
            }
            
            guard allowedChars.isSuperset(of: CharacterSet(charactersIn: label)) else {
                return .notValid(.invalidCharacters(in: label))
            }
        }
        
        return .valid
    }
}
