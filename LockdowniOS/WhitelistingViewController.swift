//
//  WhitelistingViewController.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit
import TextFieldEffects
import CocoaLumberjackSwift

class WhitelistingViewController: ConfirmedBaseViewController, UITableViewDataSource, UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        Utils.setupWhitelistedDefaults()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        if let text = addDomainTextField!.text {
            if text.count > 0 {
                DDLogInfo("Adding custom domain - \(text)")
                Utils.addDomainToUserWhitelist(key: text)
                addDomainTextField!.text = ""
            }
        }
        else {
        }
        
        
        //toggle tunneling to load new rules
        VPNController.shared.reloadWhitelistRules()
        tableview?.reloadData()
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
            let domainArray = Utils.getUserWhitelist()
            let numberOfRows = 1 + domainArray.count
            
            return numberOfRows
        }
        else {
            return Utils.getConfirmedWhitelist().count
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
        
        
        var whitelistedKey = "whitelisted_domains"
        if indexPath.section == 0 && !isPostboarding {
            whitelistedKey = "whitelisted_domains_user"
        }
        
        if let defaults = UserDefaults(suiteName: "group.com.confirmed") {
            if let domains = defaults.dictionary(forKey:whitelistedKey) {
                if let domainArray = Array(domains.keys) as? Array<String>, let statusArray = Array(domains.values) as? Array<NSNumber> {
                    if domainArray.count > indexPath.row {
                        if statusArray[indexPath.row].boolValue {
                            Utils.setKeyForDefaults(inDomain: domains, key: domainArray[indexPath.row], val: NSNumber.init(value: false), defaultKey: whitelistedKey)
                        }
                        else {
                            Utils.setKeyForDefaults(inDomain: domains, key: domainArray[indexPath.row], val: NSNumber.init(value: true), defaultKey: whitelistedKey)
                        }
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
            
            Utils.setDomainForUserWhitelist(key: (domainLabel?.text)!, val: nil)
            self.tableview?.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && !isPostboarding {
            if indexPath.row == (tableview?.numberOfRows(inSection: indexPath.section))! - 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "addWhitelistedDomainCell", for: indexPath) as! WhitelistAddCell
                let textfield = cell.addWhitelistDomain
                textfield?.addTarget(self, action: #selector(textFieldDidEndOnExit), for: .editingDidEndOnExit)
                textfield?.addTarget(self, action: #selector(didSelectTextField), for: .editingDidBegin)

                addDomainTextField = textfield
                return cell
            }
            else {
                let domains = Utils.getUserWhitelist()
                let domainArray = Array(domains.keys)
                let statusArray = Array(domains.values)
                if (domainArray.count) > indexPath.row {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "whitelistedDomainCell", for: indexPath) as! WhitelistCell
                    
                    
                    let backgroundView = UIView()
                    backgroundView.backgroundColor = UIColor.init(red: 0/255.0, green: 173/255.0, blue: 231/255.0, alpha: 1.0)
                    cell.selectedBackgroundView = backgroundView
                    
                    let domainLabel = cell.whitelistDomain
                    let statusLabel = cell.whitelistStatus
                    domainLabel?.text = domainArray[indexPath.row]
                    if (statusArray[indexPath.row] as AnyObject).boolValue {
                        statusLabel?.text = "Whitelisted".localized()
                    }
                    else {
                        statusLabel?.text = "Not Whitelisted".localized()
                    }
                    
                    domainLabel?.highlightedTextColor = UIColor.white
                    statusLabel?.highlightedTextColor = UIColor.white
                    
                    return cell
                }
            }
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "whitelistedDomainCell", for: indexPath) as! WhitelistCell
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(red: 0/255.0, green: 173/255.0, blue: 231/255.0, alpha: 1.0)
        cell.selectedBackgroundView = backgroundView
        
        let domains = Utils.getConfirmedWhitelist()
        let domainArray = Array(domains.keys)
        let statusArray = Array(domains.values)
        
        if domainArray.count > indexPath.count {
            let domainLabel = cell.whitelistDomain
            let statusLabel = cell.whitelistStatus
            domainLabel?.text = domainArray[indexPath.row]
            if (statusArray[indexPath.row] as AnyObject).boolValue {
                statusLabel?.text = "Whitelisted".localized()
            }
            else {
                statusLabel?.text = "Not Whitelisted".localized()
            }
            
            domainLabel?.highlightedTextColor = UIColor.white
            statusLabel?.highlightedTextColor = UIColor.white
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
