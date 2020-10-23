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

extension UIStoryboard {
    func instantiate<ViewController: UIViewController>(_ viewControllerType: ViewController.Type) -> ViewController {
        let identifier = String.init(describing: viewControllerType)
        if let resolved = instantiateViewController(withIdentifier: identifier) as? ViewController {
            return resolved
        } else {
            fatalError("No ViewController with Storyboard ID = \(identifier). Please make sure your Storyboard ID is the same as class name!")
        }
    }
}
