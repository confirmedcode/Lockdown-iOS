//
//  BlockLogViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class BlockLogViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayLogTime.count;
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockLogCell", for: indexPath) as! BlockLogCell
        
        cell.time.text = dayLogTime[indexPath.row];
        cell.logHost?.text = dayLogHost[indexPath.row];
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let logHost = dayLogHost[indexPath.row]
        let info = TrackerInfoRegistry.shared.info(forTrackerDomain: logHost)

        showPopupDialog(title: info.title, message: info.description, acceptButton: "Okay")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(self.refreshData(_:)), for: .valueChanged);
        
        refreshData(self);
    }
    
    @objc func refreshData(_ sender: Any) {
        if BlockDayLog.shared.isEnabled {
            tableView.isHidden = false
            blockLogDisabledContainer.isHidden = true
            
            dayLogTime = []
            dayLogHost = []
            if let dayLogs = BlockDayLog.shared.strings?.reversed() {
                for log in dayLogs {
                    let sp = log.components(separatedBy: "_");
                    if sp.count == 2 {
                        dayLogTime.append(sp[0]);
                        dayLogHost.append(sp[1]);
                    }
                }
            }
            tableView.reloadData();
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        } else {
            tableView.isHidden = true
            blockLogDisabledContainer.isHidden = false
        }
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: {})
    }
    
    @IBAction func showMenu() {
        let isBlockEnabled = BlockDayLog.shared.isEnabled
        
        showPopupDialog(title: "Settings", message: "The block log can be manually cleared or disabled. Disabling the Block Log only disables the log of connections - the number of tracking attempts will still be displayed.", buttons: [
            .custom(title: isBlockEnabled ? "Disable Block Log" : "Enable Block Log", completion: {
                if isBlockEnabled {
                    self.showDisableBlockLog()
                } else {
                    self.enableBlockLog()
                }
            }),
            .custom(title: "Clear Block Log", completion: {
                BlockDayLog.shared.clear()
                self.refreshData(self)
            }),
            .cancel()
        ])
    }
    
    func showDisableBlockLog() {
        showPopupDialog(title: "Disable Block Log?", message: "You'll have to reenable it later here to start seeing blocked entries again.", buttons: [
            .destructive(title: "Disable", completion: {
                BlockDayLog.shared.disable(shouldClear: true)
                self.refreshData(self)
            }),
            .preferredCancel()
        ])
    }
    
    @IBAction func enableBlockLog() {
        BlockDayLog.shared.enable()
        self.refreshData(self)
    }
    
    var dayLogTime: [String] = []
    var dayLogHost: [String] = []
    private let refreshControl = UIRefreshControl()
    @IBOutlet var tableView: UITableView!
    @IBOutlet var blockLogDisabledContainer: UIStackView!
    
}
