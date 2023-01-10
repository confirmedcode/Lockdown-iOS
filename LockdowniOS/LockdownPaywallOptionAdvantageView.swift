//
//  LockdownPaywallOptionAdvantageView.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/5/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation
import UIKit

final class LockdownPaywallOptionAdvantageView: UIView, NibLoadable {
    
    @IBOutlet private var advantageLabel: UILabel!
    
    static func make(text: String) -> LockdownPaywallOptionAdvantageView {
        let view = LockdownPaywallOptionAdvantageView.loadFromNib()
        
        view.advantageLabel.text = text
        view.advantageLabel.preferredMaxLayoutWidth = view.bounds.size.width
        
        return view
    }
    
}
