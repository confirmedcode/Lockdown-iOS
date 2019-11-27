//
//  TitlePageViewController.swift
//  Lockdown
//
//  Created by Johnny Lin on 8/9/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import UIKit
import RQShineLabel
import PopupDialog

class TitleViewController: BaseViewController {
    
    @IBOutlet weak var titleLabel: RQShineLabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var whyTrustButton: UIButton!
    @IBOutlet weak var overOneBillionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.textColor = .clear
        self.descriptionLabel.alpha = 0
        self.getStartedButton.alpha = 0
        self.whyTrustButton.alpha = 0
        self.overOneBillionLabel.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.titleLabel.shine(animated: true, completion: {
                UIView.animate(withDuration: 1.5, animations: {
                    self.descriptionLabel.alpha = 1
                }, completion: { e in
                    UIView.animate(withDuration: 1.5, animations: {
                        self.getStartedButton.alpha = 1
                        self.whyTrustButton.alpha = 1
                        self.overOneBillionLabel.alpha = 1
                    })
                })
            })
            self.titleLabel.textColor = .tunnelsBlue
        })
        
    }
    
    @IBAction func getStartedTapped(_ sender: Any) {
        defaults.set(true, forKey: kHasShownTitlePage)
        self.performSegue(withIdentifier: "getStartedTapped", sender: self)
    }
    
    @IBAction func whyTrustTapped(_ sender: Any) {
        showWhyTrustPopup()
    }
    
}
