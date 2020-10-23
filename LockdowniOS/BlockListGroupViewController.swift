//
//  BlockListGroupViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class BlockListGroupViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    var lockdownGroup: LockdownGroup?
    
    @IBOutlet var warningContainer: UIView!
    @IBOutlet var warningLabel: UILabel!
    @IBOutlet var lockdownEnabled: UISwitch!
    @IBOutlet var groupTitle: UILabel!
    
    weak var blockListVC: BlockListViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let lockdown = lockdownGroup {
            self.groupTitle?.text = lockdown.name
            self.lockdownEnabled?.isOn = lockdown.enabled
        }
        
        warningLabel.text = lockdownGroup?.warning
        if lockdownGroup?.warning != nil {
            warningContainer.isHidden = false
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return (lockdownGroup?.domains.count)!
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 32))
        view.backgroundColor = UIColor.groupTableViewBackground
        let label = UILabel(frame: CGRect.init(x: 12, y: 6, width: tableView.frame.size.width, height: 24))
        label.font = fontMedium14
        label.textColor = UIColor.darkGray
        
        if section == 0 {
            label.text = NSLocalizedString("Blocked Domains", comment: "")
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
        return cell
    }

    @IBAction func toggleLockdown(sender: UISwitch) {
        setIsLockdownEnabled(sender.isOn)
    }
    
    private func setIsLockdownEnabled(_ isEnabled: Bool) {
        if let vc = self.blockListVC {
            vc.didMakeChange = true
        }

        lockdownGroup?.enabled = isEnabled
        var ldDefaults = getLockdownBlockedDomains()
        ldDefaults.lockdownDefaults[(lockdownGroup?.internalID)!] = lockdownGroup
        
        defaults.set(try? PropertyListEncoder().encode(ldDefaults), forKey: kLockdownBlockedDomains)
    }

    @IBAction func dismiss() {
        blockListVC?.reloadBlockedDomains()
        self.navigationController?.popViewController(animated: true)
    }

}
