//
//  ToggleMetricsViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class ToggleMetricsViewController: ConfirmedBaseViewController {
    
    @IBAction func dismiss(sender : Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func enableMetrics(sender : Any) {
        let defaults = Global.sharedUserDefaults()
        defaults.set(true, forKey: "LockdownMetricsEnabled")
        
        self.dismiss(animated: true, completion: nil)
    }
    
}
