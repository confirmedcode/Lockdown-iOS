//
//  BlockLogViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class BlockLogViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var blockDayCounterLabel: UILabel!
    
//    lazy var blockDayCounterLabel: UILabel = {
//        let label = UILabel()
//        label.text = "233"
//        label.textColor = .label
//        label.font = fontRegular14
//        label.textAlignment = .center
//        return label
//    }()
    
    // -- SUPPORTING LIVE UPDATES
    var timer: Timer?
    var kvoObservationToken: Any?
    let debouncer = Debouncer(seconds: 0.3)
    //
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayLogTime.count;
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
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
        blockDayCounterLabel.text = getDayMetricsString(commas: true)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(self.refreshData(_:)), for: .valueChanged);
        
        configureObservers()
        
        refreshData(self);
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    func configureObservers() {
        kvoObservationToken = defaults.observe(\.LockdownDayLogs, options: [.new, .old]) { [weak self] (defaults, change) in
            DispatchQueue.main.async {
                self?.debouncer.debounce {
                    self?.refreshData(defaults)
                }
            }
        }
        
        // timer is used as a backup in case KVO fails for any reason
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] (timer) in
            self?.refreshData(timer)
        }
        timer?.tolerance = 3.0
    }
    
    @objc func refreshData(_ sender: Any) {
        blockDayCounterLabel.text = getDayMetricsString(commas: true)
        if BlockDayLog.shared.isEnabled {
            tableView.isHidden = false
            blockLogDisabledContainer.isHidden = true
            
            let oldDayLogTime = dayLogTime
            
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
            
            if dayLogTime.count > oldDayLogTime.count, oldDayLogTime != [] {
                let diff = dayLogTime.count - oldDayLogTime.count
                let indexPaths = (0 ..< diff).map({ IndexPath(row: $0, section: 0) })
                tableView.performBatchUpdates {
                    tableView.insertRows(at: indexPaths, with: .top)
                } completion: { (finished) in
                    return
                }
            } else {
                tableView.reloadData()
            }
            
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
        
        showPopupDialog(title: NSLocalizedString("Settings", comment: ""), message: NSLocalizedString("The block log can be manually cleared or disabled. Disabling the Block Log only disables the log of connections - the number of tracking attempts will still be displayed.", comment: ""), buttons: [
                            .custom(title: isBlockEnabled ? NSLocalizedString("Disable Block Log" , comment: "") : NSLocalizedString("Enable Block Log", comment: ""), completion: {
                if isBlockEnabled {
                    self.showDisableBlockLog()
                } else {
                    self.enableBlockLog()
                }
            }),
                            .custom(title: NSLocalizedString("Clear Block Log", comment: ""), completion: {
                BlockDayLog.shared.clear()
                defaults.set(0, forKey: kDayMetrics)
                self.refreshData(self)
            }),
            .cancel()
        ])
    }
    
    func showDisableBlockLog() {
        showPopupDialog(title: NSLocalizedString("Disable Block Log?", comment: ""), message: NSLocalizedString("You'll have to reenable it later here to start seeing blocked entries again.", comment: ""), buttons: [
                            .destructive(title: NSLocalizedString("Disable", comment: ""), completion: {
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

fileprivate extension UserDefaults {
    
    @objc
    dynamic var LockdownDayLogs: [Any]? {
        get {
            return array(forKey: "LockdownDayLogs")
        }
        set {
            set(newValue, forKey: "LockdownDayLogs")
        }
    }
}

// https://stackoverflow.com/a/52338788
// by Frédéric Adda
class Debouncer {

    // MARK: - Properties
    private let queue = DispatchQueue.main
    private var workItem = DispatchWorkItem(block: {})
    private var interval: TimeInterval
    
    // MARK: - Initializer
    init(seconds: TimeInterval) {
        self.interval = seconds
    }

    // MARK: - Debouncing function
    func debounce(action: @escaping (() -> Void)) {
        workItem.cancel()
        workItem = DispatchWorkItem(block: { action() })
        queue.asyncAfter(deadline: .now() + interval, execute: workItem)
    }
}
