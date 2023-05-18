//
//  EmailValidatable.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/7/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation

protocol EmailValidatable: AnyObject {
    func errorValidatingEmail(_ email: String?) -> EmailValidationError?
}

extension EmailValidatable {
    func errorValidatingEmail(_ email: String?) -> EmailValidationError? {
        guard let email, !email.isEmpty else { return .notFilledIn }
        
        if email.lowercased().hasSuffix(".con") {
            return .enteredConInsteadOfCom
        }
        
        // looks for links in this case, URL (email format) as in "mailto:test@example.com"
        guard let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return .noValidEmailAddressDetected
        }
        
        // set the range and get all of the matches using NSDataDetector
        let range = NSRange(location: 0, length: email.count)
        let allMatches = dataDetector.matches(in: email, options: [], range: range)
        
        // if there is exactly 1 email address (with the mailto link)
        if allMatches.count == 1, allMatches.first?.url?.absoluteString.contains("mailto:") == true {
            // no email error detected
            return nil
        } else if allMatches.count > 1 {
            return .tooManyEmailAddressesEntered
        }
        
        return .noValidEmailAddressDetected
    }
}

enum EmailValidationError: Error {
    case notFilledIn
    case enteredConInsteadOfCom
    case noValidEmailAddressDetected
    case tooManyEmailAddressesEntered
}

extension EmailValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notFilledIn:
            return .localized("please_fill_in_your_email")
        case .enteredConInsteadOfCom:
            return .localized("you_entered_con_instead_of_com")
        case .noValidEmailAddressDetected:
            return .localized("no_valid_email_address_detected")
        case .tooManyEmailAddressesEntered:
            return .localized("too_many_email_addresses_entered")
        }
    }
}
