//
//  Mailto.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 21.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift

enum Mailto {
    
    static func generateURL(recipient: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoString = "mailto:\(recipient)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        guard let mailtoURL = URL(string: mailtoString) else {
            DDLogError("invalid url: \(mailtoString)")
            return nil
        }
        
        return mailtoURL
    }
}
