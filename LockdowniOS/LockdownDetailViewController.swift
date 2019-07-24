//
//  LockdownDetailViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class LockdownDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return 60
        }
        return 50
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
        
        if section == 0 {
            label.text = "Domains".localized()
        }
        else {
            label.text = "IP Ranges".localized()
        }
        
        view.addSubview(label)
        
        return view
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LockdownGroupCell", for: indexPath) as! LockdownGroupTableViewCell
        
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        if let lockdown = lockdownGroup {
            self.groupTitle?.text = lockdown.name
            self.lockdownEnabled?.isOn = lockdown.enabled
        }
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func toggleLockdown(sender : Any) {
        lockdownGroup?.enabled = self.lockdownEnabled!.isOn
        var ldDefaults = Utils.getConfirmedLockdown()
        ldDefaults.lockdownDefaults[(lockdownGroup?.name)!] = lockdownGroup
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(try? PropertyListEncoder().encode(ldDefaults), forKey: "lockdown_domains")
        defaults.synchronize()
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: {})
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    var lockdownGroup : LockdownGroup?
    @IBOutlet var lockdownEnabled : UISwitch?
    @IBOutlet var groupTitle : UILabel?
    
}
