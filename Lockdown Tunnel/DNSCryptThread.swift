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
    let dnsApp: DnscryptproxyApp

    init?(arguments: [String]?) {
        guard let dnsApp = DnscryptproxyMain(arguments?[0]) else { return nil }

        self.dnsApp = dnsApp
        super.init()
        name = "DNSCloak"
    }

    override func main() {
        dnsApp.run(self)
    }

    @objc func proxyReady() {
        NotificationCenter.default.post(name: NSNotification.Name(kDNSCryptProxyReady), object: self)
    }

    func closeIdleConnections() {
        dnsApp.closeIdleConnections()
    }

    func refreshServersInfo() {
        dnsApp.refreshServersInfo()
    }

    func stopApp() {
        do {
            try dnsApp.stop()
        } catch {
            print("Error stopping app")
        }
    }

    func logDebug(_ str: String) {
        dnsApp.logDebug(str)
    }

    func logInfo(_ str: String) {
        dnsApp.logInfo(str)
    }

    func logNotice(_ str: String) {
        dnsApp.logNotice(str)
    }

    func logWarn(_ str: String) {
        dnsApp.logWarn(str)
    }

    func logError(_ str: String) {
        dnsApp.logError(str)
    }

    func logCritical(_ str: String) {
        dnsApp.logCritical(str)
    }

    func logFatal(_ str: String) {
        dnsApp.logFatal(str)
    }
}
