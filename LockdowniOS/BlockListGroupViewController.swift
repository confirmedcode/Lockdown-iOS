//
//  BlockListGroupViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class BlockListGroupViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    var lockdownGroup : LockdownGroup?
    @IBOutlet var lockdownEnabled : UISwitch?
    @IBOutlet var groupTitle : UILabel?
    var blockListVC : BlockListViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let lockdown = lockdownGroup {
            self.groupTitle?.text = lockdown.name
            self.lockdownEnabled?.isOn = lockdown.enabled
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return (lockdownGroup?.domains.count)!
        }
        else {
            return (lockdownGroup?.ipRanges.keys.count)!
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 45))
        view.backgroundColor = UIColor.groupTableViewBackground
        let label = UILabel(frame: CGRect.init(x: 20, y: 20, width: tableView.frame.size.width, height: 24))
        label.font = fontMedium14
        label.textColor = UIColor.darkGray
        
        if section == 0 {
            label.text = NSLocalizedString("Domains", comment: "")
        }
        else {
            label.text = NSLocalizedString("IP Ranges", comment: "")
        }
        
        view.addSubview(label)
        
        return view
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockListGroupCell", for: indexPath) as! BlockListGroupCell
        if indexPath.section == 0 {
            if let domainKeys = lockdownGroup?.domains {
                let keys = domainKeys.keys.sorted {$0 < $1}
                cell.cellTitle?.text = keys[indexPath.row]
            }
        }
        else {
            if let ipKeys = lockdownGroup?.ipRanges {
                let keys = ipKeys.keys.sorted {$0 < $1}
                if let bits = ipKeys[keys[indexPath.row]]?.subnetBits {
                    if bits == 0 {
                        cell.cellTitle?.text = "\(keys[indexPath.row])"
                    }
                    else {
                        cell.cellTitle?.text = "\(keys[indexPath.row]) / \(bits)"
                    }
                }
                else {
                    cell.cellTitle?.text = "\(keys[indexPath.row])"
                }
            }
        }
        return cell
    }

    @IBAction func toggleLockdown(sender : Any) {
        if let vc = self.blockListVC {
            vc.didMakeChange = true
        }
        lockdownGroup?.enabled = self.lockdownEnabled!.isOn
        var ldDefaults = getLockdownBlockedDomains()
        ldDefaults.lockdownDefaults[(lockdownGroup?.internalID)!] = lockdownGroup
        
        defaults.set(try? PropertyListEncoder().encode(ldDefaults), forKey: kLockdownBlockedDomains)
    }

    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: {
            if let vc = self.blockListVC {
                vc.tableView.reloadData()
            }
        })
    }

}
