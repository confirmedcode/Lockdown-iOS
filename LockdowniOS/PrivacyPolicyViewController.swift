//
//  PrivacyPlicyViewController.swift
//  Tunnels
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit

class PrivacyPolicyViewController: ConfirmedBaseViewController {

    //MARK: - OVERRIDE
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - ACTION
    @IBAction func goToPrivacyPolicy () {
        dismissView()
        UIApplication.shared.open(URL(string: "https://lockdownhq.com/privacy")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
    @IBAction func goToAuditReports(_ sender: Any) {
        dismissView()
        UIApplication.shared.open(URL(string: "https://openlyoperated.org/report/confirmedvpn")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
    @IBAction func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
