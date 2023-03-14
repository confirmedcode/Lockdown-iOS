//
//  DNSCryptThread.swift
//  LockdowniOS
//
//  Created by Johnny Lin on 3/31/22.
//  Copyright © 2022 Confirmed Inc. All rights reserved.
//

import Foundation
import Dnscryptproxy

let kDNSCryptProxyReady = "DNSCryptProxyReady";

class DNSCryptThread: Thread, DnscryptproxyCloakCallbackProtocol {
    var _dnsApp: DnscryptproxyApp!
    
    convenience override init() {
        self.init(arguments: nil)
    }

    init(arguments: [String]?) {
        super.init()

        _dnsApp = DnscryptproxyMain(arguments?[0])!

        name = "DNSCloak"
    }

    override func main() {
        _dnsApp.run(self)
    }

    @objc func proxyReady() {
        NotificationCenter.default.post(name: NSNotification.Name(kDNSCryptProxyReady), object: self)
    }

    func dnsApp() -> DnscryptproxyApp {
        return _dnsApp
    }

    func closeIdleConnections() {
        _dnsApp.closeIdleConnections()
    }

    func refreshServersInfo() {
        _dnsApp.refreshServersInfo()
    }

    func stopApp() {
        do {
            try _dnsApp.stop()
        } catch {
            print("Error stopping app")
        }
    }

    func logDebug(_ str: String) {
        _dnsApp.logDebug(str)
    }

    func logInfo(_ str: String) {
        _dnsApp.logInfo(str)
    }

    func logNotice(_ str: String) {
        _dnsApp.logNotice(str)
    }

    func logWarn(_ str: String) {
        _dnsApp.logWarn(str)
    }

    func logError(_ str: String) {
        _dnsApp.logError(str)
    }

    func logCritical(_ str: String) {
        _dnsApp.logCritical(str)
    }

    func logFatal(_ str: String) {
        _dnsApp.logFatal(str)
    }
}
