//
//  WhitelistViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

class WhitelistViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
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
            if self.didMakeChange == true {
                if getIsCombinedBlockListEmpty() {
                    FirewallController.shared.setEnabled(false, isUserExplicitToggle: true)
                } else if VPNController.shared.status() == .connected {
                    FirewallController.shared.restart()
                }
            }
        })
    }
    
    func saveNewDomain(userEnteredDomainName: String) {
        let validation = DomainNameValidator.validate(userEnteredDomainName)
        
        switch validation {
        case .valid:
            didMakeChange = true
            DDLogInfo("Adding custom whitelist domain - \(userEnteredDomainName)")
            addUserWhitelistedDomain(domain: userEnteredDomainName.lowercased())
            addDomainTextField?.text = ""
            tableView.reloadData()
        case .notValid(let reason):
            DDLogWarn("Custom whitelist domain not valid - \(userEnteredDomainName), reason - \(reason)")
            let notValidEntry: String = .localized("""
 is not a valid entry. Please only enter the host of the domain you want to add to a whitelist. \
For example, \"google.com\" without \"https://\"
""")
            showPopupDialog(
                title: .localized("Invalid domain"),
                message: "\"\(userEnteredDomainName)\"" + notValidEntry,
                acceptButton: .localizedOkay) {
                self.addDomainTextField?.becomeFirstResponder()
            }
        }
    }
    
    // MARK: - TABLE VIEW
    
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
                return 75
            } else {
                return 50
            }
        } else {
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return getUserWhitelistedDomains().count + 1
        } else {
            return getLockdownWhitelistedDomains().count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 45))
        view.backgroundColor = .systemGroupedBackground
        let isLeftToRight = traitCollection.layoutDirection == .leftToRight
        let label = UILabel(frame: CGRect.init(x: isLeftToRight ? 20 : -20, y: 20, width: tableView.frame.size.width, height: 24))
        label.font = .mediumLockdownFont(size: 14)
        label.textColor = UIColor.darkGray
        
        if section == 0 {
            label.text = .localized("Your Settings")
        } else {
            label.text = .localized("Pre-configured Suggestions")
        }
        
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        didMakeChange = true
        var domains: [String: Any]
        if indexPath.section == 0 {
            if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
                // Do nothing for add domain row
                return
            }
            domains = getUserWhitelistedDomains()
            let domainArray = domains.sorted {$0.key < $1.key}
            if domainArray.count > indexPath.row {
                if let status = domainArray[indexPath.row].value as? NSNumber, status.boolValue == true {
                    setUserWhitelistedDomain(domain: domainArray[indexPath.row].key, enabled: false)
                } else {
                    setUserWhitelistedDomain(domain: domainArray[indexPath.row].key, enabled: true)
                }
            }
        } else {
            domains = getLockdownWhitelistedDomains()
            let domainArray = domains.sorted {$0.key < $1.key}
            if domainArray.count > indexPath.row {
                if let status = domainArray[indexPath.row].value as? NSNumber, status.boolValue == true {
                    setLockdownWhitelistedDomain(domain: domainArray[indexPath.row].key, enabled: false)
                } else {
                    setLockdownWhitelistedDomain(domain: domainArray[indexPath.row].key, enabled: true)
                }
            }
        }
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        didMakeChange = true
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
        if editingStyle == .delete,
        let cell = tableView.cellForRow(at: indexPath) as? WhitelistCell {
            let domainLabel = cell.whitelistDomain
            
            didMakeChange = true
            deleteUserWhitelistedDomain(domain: (domainLabel?.text)!)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var domains: [String: Any]
        
        if indexPath.section == 0 {
            // Add Domain
            if indexPath.row == tableView.numberOfRows(inSection: 0) - 1,
               let cell = tableView.dequeueReusableCell(withIdentifier: "whitelistAddCell", for: indexPath) as? WhitelistAddCell {
                let textfield = cell.addWhitelistDomain
                textfield?.addTarget(self, action: #selector(textFieldDidEndOnExit), for: .editingDidEndOnExit)
                textfield?.addTarget(self, action: #selector(didSelectTextField), for: .editingDidBegin)
                addDomainTextField = textfield
                return cell
            } else {
                domains = getUserWhitelistedDomains()
            }
        } else {
            domains = getLockdownWhitelistedDomains()
        }
        
        let domainArray = domains.sorted {$0.key < $1.key}
        if domainArray.count > indexPath.row,
           let cell = tableView.dequeueReusableCell(withIdentifier: "whitelistCell", for: indexPath) as? WhitelistCell {
            cell.whitelistDomain?.text = domainArray[indexPath.row].key
            if let status = domainArray[indexPath.row].value as? NSNumber, status.boolValue == true {
                cell.whitelistStatus?.text = .localized("Whitelisted")
            } else {
                cell.whitelistStatus?.text = .localized("Not Whitelisted")
            }
            return cell
        }
        return UITableViewCell()
    }
    
    @IBAction func textFieldDidEndOnExit(textField: UITextField) {
        self.dismissKeyboard()
        
        guard let text = textField.text else {
            DDLogError("Text is empty on add domain text field")
            return
        }
        
        saveNewDomain(userEnteredDomainName: text)
    }
    
    @objc func didSelectTextField(textField: UITextField) {
        let addDomainRow = tableView.numberOfRows(inSection: 0) - 1
        self.tableView.scrollToRow(at: IndexPath.init(row: addDomainRow, section: 0), at: .middle, animated: true)
    }
    
}
