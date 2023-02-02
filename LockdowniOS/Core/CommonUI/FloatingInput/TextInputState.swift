//
//  TextInputState.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/3/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation

/// Text field state.
///
/// - empty: no text.
/// - text: contains text.
/// - placeholder: the field is focused, but no text yet.
/// - textInput: inputting text.
public enum TextInputState {
    case empty
    case text
    case placeholder
    case textInput

    public init(hasText: Bool, firstResponder: Bool) {
        switch (hasText, firstResponder) {
        case (false, false):
            self = .empty
        case (true, false):
            self = .text
        case (false, true):
            self = .placeholder
        case (true, true):
            self = .textInput
        }
    }
}
