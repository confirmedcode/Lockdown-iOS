//
//  LockdownViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

class BlockListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    var addDomainTextField: UITextField?
    @IBOutlet weak var tableView: UITableView!
    var didMakeChange = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        self.tableView.reloadData()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func save() {
        self.dismiss(animated: true, completion: {
            if (self.didMakeChange == true) {
                if (FirewallController.shared.status() == .connected) {
                    FirewallController.shared.restart()
                }
            }
        })
    }
    
    func saveNewDomain() {
        // TODO: Check it's a valid domain format
        didMakeChange = true
        if let text = addDomainTextField?.text {
            if text.count > 0 {
                DDLogInfo("Adding custom domain - \(text)")
                addUserBlockedDomain(domain: text.lowercased())
                addDomainTextField!.text = ""
                tableView.reloadData()
            }
        }
    }
    
    //MARK: - TABLE VIEW
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            // Add Domain row
            if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
                return 70
            }
            else {
                return 50
            }
        }
        else {
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return getUserBlockedDomains().count + 1
        }
        else {
            return getLockdownBlockedDomains().lockdownDefaults.keys.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 45))
        view.backgroundColor = UIColor.groupTableViewBackground
        let label = UILabel(frame: CGRect.init(x: 20, y: 20, width: tableView.frame.size.width, height: 24))
        label.font = fontMedium14
        label.textColor = UIColor.darkGray
        
        if section == 0 {
            label.text = NSLocalizedString("Your Settings", comment: "")
        }
        else {
            label.text = NSLocalizedString("Pre-configured Suggestions", comment: "")
        }
        
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
                // Do nothing for add domain row
            }
            else {
                didMakeChange = true
                let domains = getUserBlockedDomains();
                let domainArray = domains.sorted {$0.key < $1.key}
                if domainArray.count > indexPath.row {
                    if let status = domainArray[indexPath.row].value as? NSNumber, status.boolValue == true {
                        setUserBlockedDomain(domain: domainArray[indexPath.row].key, enabled: false)
                    }
                    else {
                        setUserBlockedDomain(domain: domainArray[indexPath.row].key, enabled: true)
                    }
                }
                tableView.reloadData()
            }
        }
        else if indexPath.section == 1 {
            let domains = getLockdownBlockedDomains().lockdownDefaults
            let domainKeys = domains.keys.sorted {$0 < $1}
            let lockdownGroup = domains[domainKeys[indexPath.row]]
            self.performSegue(withIdentifier: "showBlockListGroup", sender: lockdownGroup)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showBlockListGroup") {
            if let target = segue.destination as? BlockListGroupViewController,
                let lockdownGroup = sender as? LockdownGroup {
                target.lockdownGroup = lockdownGroup;
                target.blockListVC = self
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            if indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1 {
                return true
            }
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = tableView.cellForRow(at: indexPath) as! BlockListCell
            let domainLabel = cell.blockListDomain
            
            didMakeChange = true
            deleteUserBlockedDomain(domain: (domainLabel?.text)!)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            // Add Domain
            if indexPath.row == tableView.numberOfRows(inSection: 0) - 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "blockListAddCell", for: indexPath) as! BlockListAddCell
                let textfield = cell.addBlockListDomain
                textfield?.addTarget(self, action: #selector(textFieldDidEndOnExit), for: .editingDidEndOnExit)
                textfield?.addTarget(self, action: #selector(didSelectTextField), for: .editingDidBegin)
                addDomainTextField = textfield
                return cell
            }
            else {
                let domains = getUserBlockedDomains()
                let domainArray = domains.sorted {$0.key < $1.key}
                if domainArray.count > indexPath.row {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "blockListCell", for: indexPath) as! BlockListCell
                    cell.blockListDomain?.text = domainArray[indexPath.row].key
                    if let status = domainArray[indexPath.row].value as? NSNumber, status.boolValue == true {
                        cell.blockListStatus?.text = NSLocalizedString("Blocked", comment: "")
                    }
                    else {
                        cell.blockListStatus?.text = NSLocalizedString("Not Blocked", comment: "")
                    }
                    cell.blockListIcon?.image = UIImage(named: "website_icon.png")
                    
                    return cell
                }
            }
        }
        else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "blockListCell", for: indexPath) as! BlockListCell
            let domains = getLockdownBlockedDomains().lockdownDefaults
            let domainKeys = domains.keys.sorted {$0 < $1}
            if domainKeys.count > indexPath.row {
                cell.blockListDomain?.text = domains[domainKeys[indexPath.row]]?.name
                if domains[domainKeys[indexPath.row]]!.enabled {
                    cell.blockListStatus?.text = NSLocalizedString("Blocked", comment: "")
                }
                else {
                    cell.blockListStatus?.text = NSLocalizedString("Not Blocked", comment: "")
                }
                if let imageView = cell.blockListIcon,
                    let lockdownGroup = domains[domainKeys[indexPath.row]] {
                    if let icon = UIImage(named: lockdownGroup.iconURL) {
                        imageView.image = icon
                    }
                    else {
                        imageView.image = UIImage(named: "website_icon.png")
                    }
                }
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    @IBAction func textFieldDidEndOnExit(textField: UITextField) {
        self.dismissKeyboard()
        saveNewDomain()
    }
    
    @objc func didSelectTextField(textField: UITextField) {
        let addDomainRow = tableView.numberOfRows(inSection: 0) - 1
        self.tableView.scrollToRow(at: IndexPath.init(row: addDomainRow, section: 0), at: .middle, animated: true)
    }
    
}
