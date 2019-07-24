//
//  AddWidgetViewController.swift
//  Tunnels
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit

class AddWidgetViewController: ConfirmedBaseViewController {

    
    //MARK: - OVERRIDE
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //MARK: - ACTION
    @IBAction func dismissWidgetInstructions (sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - VARIABLES
    @IBOutlet var numberOne: UILabel?
    @IBOutlet var numberTwo: UILabel?
    @IBOutlet var numberThree: UILabel?

}
