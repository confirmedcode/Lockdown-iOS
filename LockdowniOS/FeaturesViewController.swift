//
//  FeaturesViewController.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import SafariServices

class FeaturesViewController: ConfirmedBaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    //MARK: - ACTION METHODS
    @IBAction func dismissFeatures (sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func setupVPN (sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        NotificationCenter.post(name: .setupVPN)
    }
    
    @IBAction func setupBlocker (sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        NotificationCenter.post(name: .showContentBlocker)
    }
    
    //MARK: - TABLEVIEW PROTOCOL
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            if NEVPNManager.shared().connection.status == .connected {
                return 2
            }
            return 3
        case 1:
            let defaults = Global.sharedUserDefaults()
            
            if contentBlockerEnabled && defaults.bool(forKey: Global.kAdBlockingEnabled) && defaults.bool(forKey: Global.kScriptBlockingEnabled) && defaults.bool(forKey: Global.kSocialBlockingEnabled) {
                return 2
            }
            return 3
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func configureCell(cell: FeatureCell, title : String, subtitle : String, isSafe : Bool) {
        
        if let checkbox = cell.featureStatus{
            checkbox.isEnabled = false
            if isSafe {
                checkbox.tintColor = .tunnelsLightBlueColor
                checkbox.setCheckState(.checked, animated: true)
            }
            else {
                checkbox.setCheckState(.mixed, animated: true)
                checkbox.tintColor = .tunnelsErrorColor
            }
        }
        
        if let titleLabel = cell.featureTitle {
            titleLabel.text = title
        }
        if let subtitleLabel = cell.featureSubtitle {
            subtitleLabel.text = subtitle
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: ipAddressCell) as! FeatureCell
                let manager = NEVPNManager.shared()
                manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
                    if manager.connection.status == .connected {
                        self.configureCell(cell: cell, title: Global.ipAddressHidden, subtitle: Global.ipAddressInformation, isSafe: true)
                    }
                    else {
                        self.configureCell(cell: cell, title: Global.ipAddressVisible, subtitle: Global.ipAddressInformation, isSafe: false)
                    }
                })
                
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: encryptedCell) as! FeatureCell
                let manager = NEVPNManager.shared()
                manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
                    if manager.connection.status == .connected {
                        self.configureCell(cell: cell, title: Global.encryptedTraffic, subtitle: Global.encryptedInformation, isSafe: true)
                    }
                    else {
                        self.configureCell(cell: cell, title: Global.unencryptedTraffic, subtitle: Global.encryptedInformation, isSafe: false)
                    }
                })
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: setupCell) as! FeatureSetupCell
                let setupButton = cell.setupButton
                setupButton?.addTarget(self, action: #selector(setupVPN(sender:)), for: .touchUpInside)
                return cell
            }
        }
        if indexPath.section == 1 {
            SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Global.contentBlockerBundleID, completionHandler: { (state, error) in
                DispatchQueue.main.async(execute: {
                    if let contentBlockerState = state {
                        self.contentBlockerEnabled = contentBlockerState.isEnabled
                    }
                })
            })
            let defaults = Global.sharedUserDefaults()
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: self.blockAdsCell) as! FeatureCell
                if self.contentBlockerEnabled && defaults.bool(forKey: Global.kAdBlockingEnabled) {
                    self.configureCell(cell: cell, title: Global.blockAds, subtitle: Global.adInformation, isSafe: true)
                }
                else {
                    self.configureCell(cell: cell, title: Global.allowAds, subtitle: Global.adInformation, isSafe: false)
                }
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: self.trackingScriptsCell) as! FeatureCell
                if self.contentBlockerEnabled && defaults.bool(forKey: Global.kScriptBlockingEnabled) && defaults.bool(forKey: Global.kSocialBlockingEnabled) {
                    self.configureCell(cell: cell, title: Global.trackingScriptsBlocked, subtitle: Global.trackingScriptsInformation, isSafe: true)
                }
                else {
                    self.configureCell(cell: cell, title: Global.trackingScriptsEnabled, subtitle: Global.trackingScriptsInformation, isSafe: false)
                }
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: setupCell) as! FeatureSetupCell
                let setupButton = cell.setupButton
                setupButton?.addTarget(self, action: #selector(setupBlocker(sender:)), for: .touchUpInside)
                return cell
            }
        }
        
        return UITableViewCell.init()
    }
    
    
    //MARK: - OVERRIDES
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Global.contentBlockerBundleID, completionHandler: { (state, error) in
            if let contentBlockerState = state {
                self.contentBlockerEnabled = contentBlockerState.isEnabled
            }
            DispatchQueue.main.async(execute: {
                self.tableView?.reloadData()
            })
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.rowHeight = UITableView.automaticDimension
        contentBlockerEnabled = false
    }
    
    //********************************************
    //MARK: - VARIABLES
    
    @IBOutlet var tableView : UITableView?
    var contentBlockerEnabled = false //cache the content blocker status
    
    let ipAddressCell = "IPAddressCell"
    let encryptedCell = "EncryptedCell"
    let blockAdsCell = "BlockAdsCell"
    let trackingScriptsCell = "BlockTrackingCell"
    let setupCell = "SetupCell"
}
