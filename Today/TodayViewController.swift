//
//  TodayViewController.swift
//  Today
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import NotificationCenter
import NetworkExtension
import CloudKit
import CocoaLumberjackSwift
import Alamofire
import PromiseKit

class TodayViewController: UIViewController, NCWidgetProviding {
    //MARK: - OVERRIDES
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage.powerIconPadded
        toggleVPN?.setImage(image, for: .normal)
        
        self.toggleVPN.layer.borderWidth = 2.0
        self.toggleVPN.layer.borderColor = UIColor.tunnelsBlueColor.cgColor
        self.toggleVPN.layer.cornerRadius = self.toggleVPN.frame.size.width / 2.0
        self.toggleVPN?.tintColor = .tunnelsBlueColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(vpnStatusDidChange(_:)), name: .vpnStatusChanged, object: nil)
        
        setupVPNButtons()
        if #available(iOSApplicationExtension 10.0, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
        ipQueue.maxConcurrentOperationCount = 1
        buttonUIQueue.maxConcurrentOperationCount = 1
    }
    
    @available(iOS 10.0, *)
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: self.view.frame.size.width, height: 170)
        }else if activeDisplayMode == .compact{
            self.preferredContentSize = CGSize(width: maxSize.width, height: 110)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupVPNButtons()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - ACTION
    @IBAction func startSpeedTest (sender: UIButton) {
        UIView.transition(with: self.speedTestButton,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            self?.speedTestButton.setTitle("Speed".localized() + ": ...", for: .normal)
            }, completion: nil)
        
        TunnelSpeed().testDownloadSpeedWithTimout(timeout: 10.0) { (megabytesPerSecond, error) -> () in
            if megabytesPerSecond > 0 {
                DispatchQueue.main.async {
                    UIView.transition(with: self.speedTestButton,
                                      duration: 0.25,
                                      options: .transitionCrossDissolve,
                                      animations: { [weak self] in
                                        self?.speedTestButton.setTitle("Speed".localized() + ": " + String(format: "%.1f", megabytesPerSecond) + " Mbps", for: .normal)
                        }, completion: nil)
                }
                
            } else {
                DDLogError("NETWORK ERROR: \(String(describing: error))")
                DispatchQueue.main.async {
                    UIView.transition(with: self.speedTestButton,
                                      duration: 0.25,
                                      options: .transitionCrossDissolve,
                                      animations: { [weak self] in
                                        self?.speedTestButton.setTitle("Speed".localized() + ": " + "N/A", for: .normal)
                        }, completion: nil)
                }
            }
        }
    }
    
    @objc func vpnStatusDidChange(_ notification: Notification) {
        let op = BlockOperation.init()
        buttonUIQueue.cancelAllOperations()
        op.addExecutionBlock {
            sleep(2)
            if op.isCancelled { return }
            DispatchQueue.main.async {
                self.setupVPNButtons()
            }
        }
        buttonUIQueue.addOperation(op)
        
        
        DDLogInfo("VPN Status: \(NEVPNManager.shared().connection.status.rawValue)")
    }
    
    @IBAction func toggleVPNButton(sender: UIButton) {
        VPNController.shared.vpnState(completion: { status in
            if TunnelsSubscription.isSubscribed != .NotSubscribed {
                if status == .disconnected || status == .invalid {
                    self.startVPN()
                }
                else {
                    self.stopVPN()
                }
            }
            else {
                self.openApp()
            }
        })
    }
    
    func setupVPNButtons() {
        VPNController.shared.vpnState(completion: { status in
            if status == .disconnected || status == .invalid {
                self.setVPNButtonDisconnected()
                if status == .disconnected {
                    self.determineIP()
                }
            }
            else if status == .connected {
                self.setVPNButtonConnected()
                self.determineIP()
            }
            else if status == .disconnecting {
                self.setVPNButtonDisconnecting()
            }
            else {
                self.setVPNButtonConnecting()
            }
            self.toggleVPN.layer.cornerRadius = self.toggleVPN.frame.width / 2.0
        })
    }
    
    func determineIP() {
        
        ipQueue.cancelAllOperations()
        
        let op = BlockOperation.init()
      
        op.addExecutionBlock {
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.ipAddress?.text = "IP".localized() + ": ..."
            })
            usleep(1500000)
            if op.isCancelled { return }
            let sessionManager = Alamofire.SessionManager.default
            
            sessionManager.retrier = nil
            URLCache.shared.removeAllCachedResponses()
            
            sessionManager.requestWithoutCache(Global.getIPURL, method: .get, parameters: ["random" : arc4random_uniform(10000000)]).validate().responseJSON()
                .done { json, response in
                    if op.isCancelled { return }
                    if response.response?.statusCode == 200 , let js = json as? Dictionary<String, Any>, let publicIPAddress = js["ip"] as? String {
                        self.ipAddress?.text = "IP".localized() + ": " + publicIPAddress
                    }
                    else {
                        DDLogError("Error loading IP Address")
                        self.ipAddress?.text = "IP".localized() + ": ..."
                    }
                }
                .catch { error in
                    DDLogError("Error loading IP Address \(error)")
                    self.ipAddress?.text = "IP".localized() + ": ..."
            }
        }
        
        ipQueue.addOperation(op)
    }
    
    func openApp() {
        let tunnelsURL = URL.init(string: "tunnels://")
        self.extensionContext?.open(tunnelsURL!, completionHandler: nil)
    }
    
    @IBAction func changeCountry (sender: UIButton) {
        openApp()
    }
    
    func setVPNButtonConnected() {
        self.toggleVPN.setOriginalState()
        self.toggleVPN.layer.cornerRadius = self.toggleVPN.frame.width / 2.0
        let image = UIImage.powerIconPadded
        toggleVPN?.setImage(image, for: .normal)
        UIView.transition(with: self.vpnStatusLabel,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            self?.vpnStatusLabel.text = Global.protectedText
                            self?.toggleVPN?.tintColor = .tunnelsBlueColor
                            self?.toggleVPN.layer.borderColor = UIColor.tunnelsBlueColor.cgColor
                            
            }, completion: nil)
    }
    
    func setVPNButtonDisconnected() {
        self.toggleVPN.setOriginalState()
        let image = UIImage.powerIconPadded
        toggleVPN?.setImage(image, for: .normal)
        UIView.setAnimationsEnabled(true)
        UIView.transition(with: self.vpnStatusLabel,
                         duration: 0.25,
                         options: .transitionCrossDissolve,
                         animations: { [weak self] in
                            self?.vpnStatusLabel.text = Global.disconnectedText
                            self?.toggleVPN?.tintColor = UIColor.darkGray
                            self?.toggleVPN?.layer.borderColor = UIColor.darkGray.cgColor
                            
            }, completion: nil)
       
    }
    
    func setVPNButtonConnecting() {
        UIView.transition(with: self.vpnStatusLabel,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            self?.vpnStatusLabel.text = Global.connectingText
            }, completion: nil)
    }
    
    func setVPNButtonDisconnecting() {
        UIView.transition(with: self.vpnStatusLabel,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            self?.vpnStatusLabel.text = Global.disconnectingText
            }, completion: nil)
    }
    
    func startVPN() {
        VPNController.shared.connectToVPN()
        createRemoteRecord(recordName: Global.kOpenTunnelRecord)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
            self.setVPNButtonConnecting()
        })
    }
    
    func createRemoteRecord(recordName : String) {
        let privateDatabase = CKContainer.init(identifier: Global.kICloudContainer).privateCloudDatabase
        let myRecord = CKRecord(recordType: recordName, zoneID: CKRecordZone.default().zoneID)
        
        privateDatabase.save(myRecord, completionHandler: ({returnRecord, error in
            if let err = error {
                DDLogError("Error saving record \(err)")
                //if there is an error, open the app and close manually, internet could be down
                self.openApp()
            } else {
                DDLogInfo("Successfully saved record")
            }
            
        }))
    }
    
    func stopVPN() {
        VPNController.shared.disconnectFromVPN()
        createRemoteRecord(recordName: Global.kCloseTunnelRecord)
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            self.setVPNButtonDisconnecting()
        })
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
    var ipQueue : OperationQueue = OperationQueue() //used to only use the latest IP requeest
    var buttonUIQueue : OperationQueue = OperationQueue() //used to not make the button flicker on many OS notifications
    
    //MARK: - VARIABLES
    @IBOutlet weak var toggleVPN: TKTransitionSubmitButton!
    @IBOutlet weak var vpnStatusLabel: UILabel!
    @IBOutlet weak var ipAddress: UILabel!
    @IBOutlet weak var speedTestButton: UIButton!
}
