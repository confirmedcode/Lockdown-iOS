//
//  LockdownViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import TextFieldEffects
import CocoaLumberjackSwift
import SDWebImage

class LockdownViewController: ConfirmedBaseViewController, UITableViewDataSource, UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.setupWhitelistedDefaults()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableview?.reloadData()
        if isPostboarding {
            self.saveButton?.isHidden = true
        }
        else {
            self.saveButton?.isHidden = false
        }
        
        let filteredConstraints = self.view?.constraints.filter { $0.identifier == "stackViewBottomSpacing" }
        if let bottomConstraint = filteredConstraints?.first {
            if isPostboarding {
                bottomConstraint.constant = 163
            }
            else {
                bottomConstraint.constant = 0
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissWhitelistingPage() {
        saveNewDomain()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.dismiss(animated: true, completion: {})
        }
    }
    
    @IBAction func textFieldDidEndOnExit(textField: UITextField) {
        self.dismissKeyboard()
        saveNewDomain()
    }
    
    func saveNewDomain() {
        
        if let text = addDomainTextField?.text {
            if text.count > 0 {
                DDLogInfo("Adding custom domain - \(text)")
                Utils.addDomainToUserLockdown(key: text)
                addDomainTextField!.text = ""
                
                //toggle tunneling to load new rules
                VPNController.shared.reloadWhitelistRules()
                tableview?.reloadData()
            }
        }
        else {
        }
    }
    
    
    //MARK: - TABLE VIEW METHODS
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return 60
        }
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && !isPostboarding {
            if indexPath.row == (tableview?.numberOfRows(inSection: indexPath.section))! - 1 {
                return 120
            }
            else {
                if UI_USER_INTERFACE_IDIOM() == .pad {
                    return 60
                }
                return 50
            }
        }
        else {
            if UI_USER_INTERFACE_IDIOM() == .pad {
                return 60
            }
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && !isPostboarding {
            let domainArray = Utils.getUserLockdown()
            let numberOfRows = 1 + domainArray.count
            
            return numberOfRows
        }
        else {
            return Utils.getConfirmedLockdown().lockdownDefaults.keys.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 106))
        var label = UILabel(frame: CGRect.init(x: 24, y: 20, width: tableView.frame.size.width, height: 24))
        label.font = UIFont.init(name: "Montserrat-Medium", size: 14)
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            label = UILabel(frame: CGRect.init(x: 84, y: 20, width: tableView.frame.size.width, height: 24))
            label.font = UIFont.init(name: "Montserrat-Medium", size: 18)
        }
        
        label.textColor = UIColor.darkGray
        view.backgroundColor = UIColor.white
        
        if section == 0 && !isPostboarding {
            label.text = "Your settings".localized()
        }
        else {
            label.text = "Recommended by Lockdown".localized()
        }
        
        view.addSubview(label)
        
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(withIdentifier: "lockdownDetailVC") as! LockdownDetailViewController

            let domains = Utils.getConfirmedLockdown().lockdownDefaults
            let domainKeys = domains.keys.sorted {$0 < $1}
            
            vc.lockdownGroup = domains[domainKeys[indexPath.row]]
            self.show(vc, sender: self)
        }
        
        var whitelistedKey = "lockdown_domains"
        if indexPath.section == 0 && !isPostboarding {
            whitelistedKey = "lockdown_domains_user"
        }
        
        if let defaults = UserDefaults(suiteName: "group.com.confirmed") {
            if let domains = defaults.dictionary(forKey:whitelistedKey) {
                let domainArray = domains.sorted {$0.key < $1.key}
                if domainArray.count > indexPath.row {
                    if let status = domainArray[indexPath.row].value as? NSNumber, status.boolValue == true {
                        Utils.setKeyForDefaults(inDomain: domains, key: domainArray[indexPath.row].key, val: NSNumber.init(value: false), defaultKey: whitelistedKey)
                    }
                    else {
                        Utils.setKeyForDefaults(inDomain: domains, key: domainArray[indexPath.row].key, val: NSNumber.init(value: true), defaultKey: whitelistedKey)
                    }
                }
            }
        }
        
        VPNController.shared.reloadWhitelistRules()
        tableView.reloadData()
    }
    
    @objc func didSelectTextField(textField: UITextField) {
        let addDomainRow = (tableview?.numberOfRows(inSection: 0))! - 1
        self.tableview?.scrollToRow(at: IndexPath.init(row: addDomainRow, section: 0), at: .middle, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            if indexPath.row < (tableview?.numberOfRows(inSection: indexPath.section))! - 1 {
                return true
            }
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = tableView.cellForRow(at: indexPath) as! WhitelistCell
            let domainLabel = cell.whitelistDomain
            
            Utils.setDomainForUserLockdown(key: (domainLabel?.text)!, val: nil)
            self.tableview?.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func setFavIcon(imageView: UIImageView, domain : String) {
        imageView.sd_setImage(with: URL(string: "https://\(domain)/apple-touch-icon.png"), placeholderImage: UIImage.init(named: "website_icon.png"), options: [], completed: { (image, error, cacheType, imageURL) in
            
            if error != nil {
                imageView.sd_setImage(with: URL(string: "https://\(domain)/favicon.ico"), placeholderImage: UIImage.init(named: "website_icon.png"), options: [], completed: { (image, error, cacheType, imageURL) in
                    
                    if error != nil {
                        
                    }
                    
                })
            }
        })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            if indexPath.row == (tableview?.numberOfRows(inSection: indexPath.section))! - 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "addWhitelistedDomainCell", for: indexPath) as! WhitelistAddCell
                let textfield = cell.addWhitelistDomain
                textfield?.addTarget(self, action: #selector(textFieldDidEndOnExit), for: .editingDidEndOnExit)
                textfield?.addTarget(self, action: #selector(didSelectTextField), for: .editingDidBegin)
                
                addDomainTextField = textfield
                return cell
            }
            else {
                let domains = Utils.getUserLockdown() 
                let domainArray = domains.sorted {$0.key < $1.key}
                if (domainArray.count) > indexPath.row {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "whitelistedDomainCell", for: indexPath) as! WhitelistCell
                    
                    
                    let backgroundView = UIView()
                    backgroundView.backgroundColor = UIColor.init(red: 0/255.0, green: 173/255.0, blue: 231/255.0, alpha: 1.0)
                    cell.selectedBackgroundView = backgroundView
                    
                    let domainLabel = cell.whitelistDomain
                    let statusLabel = cell.whitelistStatus
                    domainLabel?.text = domainArray[indexPath.row].key
                    if let status = domainArray[indexPath.row].value as? NSNumber, status.boolValue == true {
                        statusLabel?.text = "Blocked".localized()
                    }
                    else {
                        statusLabel?.text = "Not Blocked".localized()
                    }
                    cell.whitelistIcon?.clipsToBounds = true
                    cell.whitelistIcon?.layer.cornerRadius = 4
                    if let imageView = cell.whitelistIcon, let domain = domainLabel?.text {
                        self.setFavIcon(imageView: imageView, domain: domain)
                    }
                    
                    domainLabel?.highlightedTextColor = UIColor.white
                    statusLabel?.highlightedTextColor = UIColor.white
                    
                    return cell
                }
                else {
                    print("Unknown error")
                }
            }
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "whitelistedDomainCell", for: indexPath) as! WhitelistCell
        cell.whitelistIcon?.image = UIImage.init(named: "website_icon.png")
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(red: 0/255.0, green: 173/255.0, blue: 231/255.0, alpha: 1.0)
        cell.selectedBackgroundView = backgroundView
        
        let domains = Utils.getConfirmedLockdown().lockdownDefaults
        let domainKeys = domains.keys.sorted {$0 < $1}
        
        if domainKeys.count > indexPath.row {
            let domainLabel = cell.whitelistDomain
            let statusLabel = cell.whitelistStatus
            domainLabel?.text = domains[domainKeys[indexPath.row]]?.name
            if domains[domainKeys[indexPath.row]]!.enabled {
                statusLabel?.text = "Blocked".localized()
            }
            else {
                statusLabel?.text = "Not Blocked".localized()
            }
            
            domainLabel?.highlightedTextColor = UIColor.white
            statusLabel?.highlightedTextColor = UIColor.white
            cell.whitelistIcon?.clipsToBounds = true
            cell.whitelistIcon?.layer.cornerRadius = 4
            if let imageView = cell.whitelistIcon, let domain = domainLabel?.text, let lockdownGroup = domains[domainKeys[indexPath.row]] {
                if let icon = UIImage.init(named: lockdownGroup.iconURL) {
                    imageView.image = icon
                }
                else {
                    imageView.image = UIImage.init(named: "website_icon.png")
                }
            }
        }
        
        
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isPostboarding {
            return 1
        }
        return 2
    }
    
    //MARK: - VARIABLES
    
    var isPostboarding : Bool = false //Postboarding are the setup/walkthrough slides after starting a trial
    @IBOutlet var saveButton : UIButton?
    
    var addDomainTextField : HoshiTextField?
    @IBOutlet weak var tableview : UITableView?
    @IBOutlet weak var stackView : UIStackView?

}
