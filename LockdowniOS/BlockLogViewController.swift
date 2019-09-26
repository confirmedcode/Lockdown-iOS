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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(self.refreshData(_:)), for: .valueChanged);
        
        refreshData(self);
    }
    
    @objc func refreshData(_ sender: Any) {
        let kDayLogs = "LockdownDayLogs";
        dayLogTime = [];
        dayLogHost = [];
        if var dayLogs = defaults.array(forKey: kDayLogs) as? [String] {
            dayLogs = dayLogs.reversed();
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
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: {})
    }
    
    var dayLogTime: [String] = []
    var dayLogHost: [String] = []
    private let refreshControl = UIRefreshControl()
    @IBOutlet weak var tableView: UITableView!
    
}
