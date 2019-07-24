//
//  SideMenuViewController.swift
//  Tunnels
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//


import UIKit
import NetworkExtension
import CocoaLumberjackSwift
import Alamofire

class SideMenuViewController: ConfirmedBaseViewController, UITableViewDelegate, UITableViewDataSource {

    
    //MARK: - OVERRIDES
    override func viewDidLoad() {
        super.viewDidLoad()
        self.versionNumber?.text = Utils.getVersionString()
        tableView?.tableFooterView = UIView(frame: .zero)
        tableView?.tableFooterView?.isHidden = true
        setupIPAddressUpdater()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIDevice().userInterfaceIdiom == .pad {
            self.sideMenuController?.leftViewWidth = 400
        }
        self.versionNumber?.text = Utils.getVersionString() //update for API version switches
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - TABLEVIEW DELEGATE

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 0 //account section
        }
        else {
            return 2 //action section
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        
        if section == 1 {
            let separator = UIView.init(frame: CGRect(x:view.frame.origin.x + 40, y: 20, width:200, height:1))
            separator.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
            //view.addSubview(separator)
        }
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 40
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SideTableMenu", for: indexPath) as! SideMenuCell
        
        let textLabel = cell.tableText!
        let imageView = cell.tableImage!
        
        textLabel.font = UIFont.init(name: "Montserrat-Regular", size: 18)

        textLabel.textColor = .tunnelsBlueColor
        imageView.tintColor = .tunnelsBlueColor
        cell.backgroundColor = UIColor.clear
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = .tunnelsBlueColor
        cell.selectedBackgroundView = bgColorView
        
        if indexPath.section == 0 {
            textLabel.text = Global.accountText
            imageView.image = .accountIcon
        }
        else {
            switch indexPath.row {
            case 0:
                textLabel.text = Global.helpText
                imageView.image = .questionIcon
            case 1:
                textLabel.text = Global.privacyText
                imageView.image = .privacyIcon
            case 2:
                textLabel.text = Global.benefitsText
                imageView.image = .informationIcon
            case 3:
                textLabel.text = Global.speedTestText
                imageView.image = .lightningIconThick
            case 4:
                textLabel.text = Global.installWidgetText
                imageView.image = .installIcon
            case 5:
                textLabel.text = Global.whitelistingText
                imageView.image = .checkIcon
            case 6:
                textLabel.text = Global.contentBlockerText
                imageView.image = .blockIcon
            default:
                DDLogInfo("Unknown row rendered \(indexPath.row)")
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SideMenuCell
        let textLabel = cell.tableText!
        let imageView = cell.tableImage!
        
        textLabel.textColor = UIColor.white
        imageView.tintColor = UIColor.white
        
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SideMenuCell
        let textLabel = cell.tableText!
        let imageView = cell.tableImage!
        
        textLabel.textColor = .tunnelsBlueColor
        imageView.tintColor = .tunnelsBlueColor
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView?.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            NotificationCenter.post(name: .showAccount)
        }
        else {
            switch indexPath.row {
            case 0:
                NotificationCenter.post(name: .askForHelp)
            case 1:
                NotificationCenter.post(name: .showPrivacyPolicy)
            case 2:
                NotificationCenter.post(name: .showTutorial)
            case 3:
                self.dismiss(animated: true, completion: nil)
                NotificationCenter.post(name: .runSpeedTest)
            case 4:
                NotificationCenter.post(name: .installWidget)
            case 5:
                NotificationCenter.post(name: .showWhitelistDomains)
            case 6:
                NotificationCenter.post(name: .showContentBlocker)
            default:
                DDLogInfo("Unknown index path \(indexPath.row)")
            }
        }
    }
    
    
    //MARK: - ACTION
    func setupIPAddressUpdater() {
        return;
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.vpnStatusChanged, object: nil, queue: OperationQueue.main) { (notification) -> Void in
            if NEVPNManager.shared().connection.status == .connected || NEVPNManager.shared().connection.status == .disconnected {
                self.ipAddress?.text = "..."
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    let sessionManager = Alamofire.SessionManager.default
                    sessionManager.retrier = nil
                    URLCache.shared.removeAllCachedResponses()
                    sessionManager.request(Global.getIPURL, method: .get).responseJSON { response in
                        switch response.result {
                        case .success:
                            if let json = response.result.value as? [String: Any], let publicIPAddress = json["ip"] as? String {
                                self.ipAddress?.text = publicIPAddress
                            }
                            else {
                                self.ipAddress?.text = ""
                            }
                        case .failure(let error):
                            DDLogError("Error loading IP Address \(error)")
                            self.ipAddress?.text = ""
                        }
                    }
                })
                
            }
        }
    }
    
    //MARK: - VARIABLES
    @IBOutlet weak var versionNumber: UILabel?
    @IBOutlet weak var ipAddress: UILabel?
    @IBOutlet weak var tableView: UITableView?
    
}
