//
//  FirewallTodayViewController.swift
//  Today
//
//  Copyright © 2019 Confirmed, Inc. All rights reserved.
//

import UIKit
import NotificationCenter
import NetworkExtension
import CloudKit
import CocoaLumberjackSwift
import PromiseKit

class FirewallTodayViewController: UIViewController, NCWidgetProviding {
    
    var lastFirewallStatus: NEVPNStatus?
    var metricsTimer : Timer?
    
    @IBOutlet weak var blockedTodayLabel: UILabel!
    @IBOutlet weak var toggleFirewall: UIButton!
    @IBOutlet weak var firewallStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.toggleFirewall.layer.borderWidth = 2.5
        self.toggleFirewall.layer.borderColor = UIColor.tunnelsBlue.cgColor
        self.toggleFirewall.layer.cornerRadius = self.toggleFirewall.frame.size.width / 2.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(firewallStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
        
        setupFirewallButtons()
        
        if metricsTimer == nil {
            metricsTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(updateMetrics), userInfo: nil, repeats: true)
            metricsTimer?.fire()
        }
        updateMetrics()
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFirewallButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        FirewallController.shared.refreshManager(completion: { error in
            if let e = error {
                DDLogError("Error refreshing Manager in background check: \(e)")
                return
            }
            self.setupFirewallButtons()
            if getUserWantsFirewallEnabled() && (FirewallController.shared.status() == .connected || FirewallController.shared.status() == .invalid) {
                DDLogInfo("Widget Firewall Test: user wants firewall enabled and connected, testing blocking with widget")
                _ = Client.getBlockedDomainTest(connectionSuccessHandler: {
                    DDLogError("Widget Firewall Test: Connected to \(testFirewallDomain) even though it's supposed to be blocked, restart the Firewall")
                    self.restartFirewall()
                }, connectionFailedHandler: {
                    error in
                    if error != nil {
                        let nsError = error! as NSError
                        if nsError.domain == NSURLErrorDomain {
                            DDLogInfo("Widget Firewall Test: Successful blocking of \(testFirewallDomain) with NSURLErrorDomain error: \(nsError)")
                        }
                        else {
                            DDLogInfo("Widget Firewall Test: Successful blocking of \(testFirewallDomain), but seeing non-NSURLErrorDomain error: \(error!)")
                        }
                    }
                })
            }
        })
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: self.view.frame.size.width, height: 170)
        } else if activeDisplayMode == .compact{
            self.preferredContentSize = CGSize(width: maxSize.width, height: 110)
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
    @objc func updateMetrics() {
        DispatchQueue.main.async {
            self.blockedTodayLabel.text = getDayMetricsString() + NSLocalizedString(" Blocked Today", comment: "refers to number of connections blocked today, as in '34 Blocked Today'")
        }
    }
    
    // MARK: - Firewall Status/Button
    
    @objc func firewallStatusDidChange(_ notification: Notification) {
        if let tunnelProviderSession = notification.object as? NETunnelProviderSession {
            DDLogInfo("VPNStatusDidChange as NETunnelProviderSession with status: \(tunnelProviderSession.status.rawValue)");
            if (tunnelProviderSession.status != self.lastFirewallStatus) {
                self.setupFirewallButtons()
            }
        }
    }
    
    @IBAction func toggleFirewallButton(sender: UIButton) {
        switch FirewallController.shared.status() {
        case .connected, .connecting, .reasserting:
            DDLogInfo("Widget Toggle Firewall: on currently, turning it off")
            setFirewallButtonDisconnecting()
            stopFirewall()
        case .disconnected, .disconnecting, .invalid:
            DDLogInfo("Widget Toggle Firewall: off currently, turning it on")
            setFirewallButtonConnecting()
            startFirewall()
        }
    }
    
    func setupFirewallButtons() {
        // force FirewallController.init() so that it loads the manager
        let status = FirewallController.shared.status()
        if (!getUserWantsFirewallEnabled()) {
            return setFirewallButtonDisconnected()
        }
        switch status {
        case .disconnected, .invalid:
            self.setFirewallButtonDisconnected()
        case .connected:
            self.setFirewallButtonConnected()
        case .disconnecting:
            self.setFirewallButtonDisconnecting()
        case .connecting, .reasserting:
            self.setFirewallButtonConnecting()
        }
    }
    
    func setFirewallButtonConnected() {
        firewallStatusLabel.text = NSLocalizedString("Firewall Active", comment: "")
        toggleFirewall?.tintColor = .tunnelsBlue
        toggleFirewall.layer.borderColor = UIColor.tunnelsBlue.cgColor
    }
    
    func setFirewallButtonDisconnected() {
        firewallStatusLabel.text = NSLocalizedString("Firewall Not Active", comment: "")
        toggleFirewall?.tintColor = UIColor.darkGray
        toggleFirewall?.layer.borderColor = UIColor.darkGray.cgColor
    }
    
    func setFirewallButtonConnecting() {
        firewallStatusLabel.text = NSLocalizedString("Activating...", comment: "")
    }
    
    func setFirewallButtonDisconnecting() {
        firewallStatusLabel.text = NSLocalizedString("Deactivating...", comment: "")
    }
    
    // MARK: - Helpers
    
    func startFirewall() {
        setFirewallButtonConnecting()
        createRemoteRecord(recordName: kOpenFirewallTunnelRecord, shouldOpenAppOnFailure: true)
    }
    
    func stopFirewall() {
        setFirewallButtonDisconnecting()
        createRemoteRecord(recordName: kCloseFirewallTunnelRecord, shouldOpenAppOnFailure: true)
    }
    
    func restartFirewall() {
        // restartFirewall is called on ViewAppear, so it should not automatically open app on failure
        createRemoteRecord(recordName: kRestartFirewallTunnelRecord, shouldOpenAppOnFailure: false)
    }
    
    func createRemoteRecord(recordName: String, shouldOpenAppOnFailure: Bool = false) {
        let privateDatabase = CKContainer.init(identifier: kICloudContainer).privateCloudDatabase
        let myRecord = CKRecord(recordType: recordName, zoneID: CKRecordZone.default().zoneID)
        
        privateDatabase.save(myRecord, completionHandler: ({returnRecord, error in
            if let err = error {
                DDLogError("Error saving record \(err)")
                //if there is an error, open the app and close manually, internet could be down
                if (shouldOpenAppOnFailure == true) {
                    self.openApp()
                }
            } else {
                DDLogInfo("Successfully saved record: \(returnRecord)")
            }
        }))
    }
    
    func openApp() {
        self.extensionContext?.open(URL(string: "lockdown://")!, completionHandler: nil)
    }
    
    @IBAction func openLockdown(sender: UIButton) {
        openApp()
    }
    
}
