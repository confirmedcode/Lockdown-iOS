//
//  StepModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 21.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import Foundation

enum Steps {
    case whatsProblem
    case questions
    
    var actionTitle: String {
        switch self {
        case .whatsProblem: return NSLocalizedString("Next", comment: "")
        case .questions: return NSLocalizedString("Submit Feedback", comment: "")
        }
    }
    
    var showSkipButton: Bool {
        switch self {
        case .whatsProblem: return true
        case .questions: return false
        }
    }
}
