//
//  SetRegionViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

class SetRegionViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var homeVC: HomeViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.reloadData()
    }
    
    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - TABLE VIEW
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vpnRegions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let tappedVpnRegion = vpnRegions[indexPath.row]
        setSavedVPNRegion(vpnRegion: tappedVpnRegion)
        if homeVC != nil {
            homeVC!.updateVPNRegionLabel()
        }
        
        dismiss(animated: true, completion: {
            if VPNController.shared.status() == .connected {
                VPNController.shared.restart()
            }
        })
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vpnRegion = vpnRegions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "setRegionCell", for: indexPath) as! SetRegionCell
        cell.regionFlag.text = vpnRegion.regionFlagEmoji
        cell.regionName.text = vpnRegion.regionDisplayName
        
        if vpnRegion.serverPrefix == getSavedVPNRegion().serverPrefix {
            cell.regionSelected.isHidden = false
        }
        else {
            cell.regionSelected.isHidden = true
        }
        
        return cell
    }
    
}
