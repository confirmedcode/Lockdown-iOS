//
//  ContentBlockerViewController.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import SafariServices
import CocoaLumberjackSwift

class ContentBlockerViewController: ConfirmedBaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    //MARK: - TABLEVIEW DATA
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AdTrackerCell") as! AdBlockerCell
        
        let contentType = cell.contetText
        let contentBlocked = cell.isEnabled
        
        if indexPath.row == 0 {
            contentType?.text = Global.blockAds
            contentBlocked?.addTarget(self, action: #selector(toggleAdTracker(sender:)), for: .valueChanged)
            let defaults = Global.sharedUserDefaults()
            if defaults.object(forKey: Global.kAdBlockingEnabled) != nil {
                contentBlocked?.isOn = defaults.bool(forKey:  Global.kAdBlockingEnabled)
            }
            else {
                setContentBlockerSetting(key: Global.kAdBlockingEnabled, val: true)
            }
        }
        else if indexPath.row == 1 {
            contentType?.text = Global.blockTrackingScripts
            contentBlocked?.addTarget(self, action: #selector(togglePrivacyTracker(sender:)), for: .valueChanged)
            
            let defaults = Global.sharedUserDefaults()
            if defaults.object(forKey: Global.kScriptBlockingEnabled) != nil {
                contentBlocked?.isOn = defaults.bool(forKey:  Global.kScriptBlockingEnabled)
            }
            else {
                setContentBlockerSetting(key: Global.kScriptBlockingEnabled, val: true)
            }
            
        }
        else if indexPath.row == 2 {
            contentType?.text = Global.blockSocialTrackers
            contentBlocked?.addTarget(self, action: #selector(toggleSocialTracker(sender:)), for: .valueChanged)
            
            let defaults = Global.sharedUserDefaults()
            if defaults.object(forKey: Global.kSocialBlockingEnabled) != nil {
                contentBlocked?.isOn = defaults.bool(forKey:  Global.kSocialBlockingEnabled)
            }
            else {
                setContentBlockerSetting(key: Global.kSocialBlockingEnabled, val: true)
            }
        }
        
        return cell
    }
    
    
    //MARK: - ACTION
    
    @IBAction func dismissContentBlockerPage() {
        self.dismiss(animated: true, completion: {})
    }
    
    func reloadData() {
        SFContentBlockerManager.reloadContentBlocker(
        withIdentifier: Global.contentBlockerBundleID) { (_ error: Error?) -> Void in
            if error != nil {
                //reload again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.reloadData()
                }
            }
            DDLogError("Reloaded blocker with error: \(String(describing: error))")
        }
    }
    
    func setContentBlockerSetting(key : String, val : Bool) {
        DDLogInfo("Setting content setting \(val) : \(key)")
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(val, forKey: key)
        defaults.synchronize()
        tableView?.reloadData()
        
        reloadData()
    }
    
    @IBAction func toggleAdTracker(sender : UISwitch) {
        DDLogInfo("Toggling tracker")
        setContentBlockerSetting(key: Global.kAdBlockingEnabled, val: sender.isOn)
    }
    
    @IBAction func togglePrivacyTracker(sender : UISwitch) {
        DDLogInfo("Toggling tracker")
        setContentBlockerSetting(key: Global.kScriptBlockingEnabled, val: sender.isOn)
    }
    
    @IBAction func toggleSocialTracker(sender : UISwitch) {
        DDLogInfo("Toggling tracker")
        setContentBlockerSetting(key: Global.kSocialBlockingEnabled, val: sender.isOn)
    }
    
    
    @objc func appIsActive() {
        refreshLoadedState()
    }
    
    func refreshLoadedState() {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Global.contentBlockerBundleID, completionHandler: { (state, error) in
            if let err = error {
                DDLogError("Refreshing content blocker failed \(err)")
            }
            if let state = state {
                DispatchQueue.main.async(execute: {
                    var frame = self.tableView?.tableHeaderView?.frame
                    
                    if state.isEnabled {
                        self.instructionsLabel?.isHidden = true
                        
                        frame?.size.height = 120
                        self.tableView?.tableHeaderView?.frame = frame!
                        self.tableView?.reloadData()
                    }
                    else {
                        self.instructionsLabel?.isHidden = false
                        
                        frame?.size.height = 220
                        self.tableView?.tableHeaderView?.frame = frame!
                        self.tableView?.reloadData()
                    }
                })
            }
        })
    }
    
    //MARK: - OVERRIDES
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(appIsActive), name: UIApplication.willEnterForegroundNotification, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isPostboarding {
            self.saveButton?.isHidden = true
        }
        else {
            self.saveButton?.isHidden = false
        }
        
        refreshLoadedState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - VARIABLES
    
    var isPostboarding : Bool = false
    @IBOutlet var saveButton : UIButton?
    @IBOutlet var instructionsLabel : UILabel?
    @IBOutlet var headerLabel : UILabel?
    @IBOutlet var tableView : UITableView?

}
