//
//  VPNViewController.swift
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

class VPNTodayViewController: UIViewController, NCWidgetProviding {
    
    var lastVPNStatus: NEVPNStatus?

    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var toggleVPN: UIButton!
    @IBOutlet weak var vpnStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.toggleVPN.layer.borderWidth = 2.5
        self.toggleVPN.layer.borderColor = UIColor.tunnelsBlue.cgColor
        self.toggleVPN.layer.cornerRadius = self.toggleVPN.frame.size.width / 2.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(vpnStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
        
        setupVPNButtons()
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupVPNButtons()
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
    
    // MARK: - VPN Status/Button
    
    @objc func vpnStatusDidChange(_ notification: Notification) {
        if let neVPNConnection = notification.object as? NEVPNConnection {
            DDLogInfo("Widget VPNStatusDidChange as NEVPNConnection with status: \(neVPNConnection.status.rawValue)");
            if (neVPNConnection.status != self.lastVPNStatus) {
                self.setupVPNButtons()
            }
        }
    }
    
    @IBAction func toggleVPNButton(sender: UIButton) {
        switch VPNController.shared.status() {
        case .connected, .connecting, .reasserting:
            setVPNButtonDisconnecting()
            DDLogInfo("Widget Toggle VPN: on currently, turning it off")
            VPNController.shared.setEnabled(false)
        case .disconnected, .disconnecting, .invalid:
            DDLogInfo("Widget Toggle VPN: off currently, turning it on")
            setVPNButtonConnecting()
            // TODO: Subscription checking or alerts
            VPNController.shared.setEnabled(true)
        }
    }
    
    func setupVPNButtons() {
        switch VPNController.shared.status() {
        case .disconnected, .invalid:
            self.setVPNButtonDisconnected()
        case .connected:
            self.setVPNButtonConnected()
        case .disconnecting:
            self.setVPNButtonDisconnecting()
        case .connecting, .reasserting:
            self.setVPNButtonConnecting()
        }
        regionLabel.text = getSavedVPNRegion().regionDisplayName
    }
    
    func setVPNButtonConnected() {
        vpnStatusLabel.text = NSLocalizedString("VPN Active", comment: "")
        toggleVPN?.tintColor = .tunnelsBlue
        toggleVPN.layer.borderColor = UIColor.tunnelsBlue.cgColor
    }
    
    func setVPNButtonDisconnected() {
        vpnStatusLabel.text = NSLocalizedString("VPN Not Active", comment: "")
        toggleVPN?.tintColor = UIColor.darkGray
        toggleVPN?.layer.borderColor = UIColor.darkGray.cgColor
    }
    
    func setVPNButtonConnecting() {
        vpnStatusLabel.text = NSLocalizedString("Activating...", comment: "")
    }
    
    func setVPNButtonDisconnecting() {
        vpnStatusLabel.text = NSLocalizedString("Deactivating...", comment: "")
    }
    
    // MARK: - Helpers
    
    func openApp() {
        self.extensionContext?.open(URL(string: "lockdown://")!, completionHandler: nil)
    }
    
    @IBAction func openLockdown(sender: UIButton) {
        openApp()
    }
    
}
