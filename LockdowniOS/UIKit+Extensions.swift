//
//  UIKit+Extensions.swift
//  LockdowniOS
//
//  Created by Oleg Dreyman on 28.05.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import UIKit

extension UIDevice {
    
    static var is4InchIphone: Bool {
        return UIScreen.main.nativeBounds.height == 1136
    }
}

extension Bundle {
    var versionString: String {
        return "v" + (infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
    }
}
