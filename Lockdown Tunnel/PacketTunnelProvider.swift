//
//  PacketTunnelProvider.swift
//  LockdownTunnel
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import NetworkExtension
import NEKit

var latestBlockedDomains = getAllBlockedDomains()

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let proxyServerPort: UInt16 = 9090;
    let proxyServerAddress = "127.0.0.1";
    var proxyServer: GCDHTTPProxyServer!
    
    //MARK: - OVERRIDES
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        if proxyServer != nil {
            proxyServer.stop()
        }
        proxyServer = nil
        
        PacketTunnelProviderLogs.log("startTunnel function called with protected file access")
        self.connect(options: options, completionHandler: completionHandler)
    }
    
    private func connect(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: proxyServerAddress)
        settings.mtu = NSNumber(value: 1500)
        
        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.httpsEnabled = true;
        proxySettings.httpsServer = NEProxyServer(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.excludeSimpleHostnames = false;
        proxySettings.exceptionList = []
        var combined: Array<String> = getAllBlockedDomains() + [testFirewallDomain] // probably not blocking whitelisted so this is safe, example.com is used to ensure firewall is still working
        combined = combined + getAllWhitelistedDomains()
        if combined.count <= 1 {
            #if DEBUG
            debugLog("PTP: COMBINED BLOCK LIST IS INVALID, LIKELY JUST RESTARTED")
            debugLog(combined.description)
            #endif
            completionHandler(NEVPNError(.configurationInvalid))
            return
        }
        proxySettings.matchDomains = combined
        
        settings.dnsSettings = NEDNSSettings(servers: ["127.0.0.1"])
        settings.proxySettings = proxySettings;
        RawSocketFactory.TunnelProvider = self
        
        self.setTunnelNetworkSettings(settings, completionHandler: { error in
            guard error == nil else {
                PacketTunnelProviderLogs.log("Error setting tunnel network settings \(error as Any)")
                completionHandler(error)
                return
            }
            let newProxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
            newProxyServer.refreshDomains()
            self.proxyServer = newProxyServer
            do {
                try self.proxyServer.start()
                PacketTunnelProviderLogs.log("Proxy server started")
                completionHandler(nil)
            } catch let proxyError {
                PacketTunnelProviderLogs.log("Error starting proxy server \(proxyError)")
                completionHandler(proxyError)
            }
        })
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        DNSServer.currentServer = nil
        RawSocketFactory.TunnelProvider = nil
        ObserverFactory.currentFactory = nil
        proxyServer.stop()
        proxyServer = nil
        PacketTunnelProviderLogs.log("LockdownTunnel: error on stopping: \(reason.debugDescription)")
        
        completionHandler()
        exit(EXIT_SUCCESS)
    }
    
    override func cancelTunnelWithError(_ error: Error?) {
        super.cancelTunnelWithError(error)
        PacketTunnelProviderLogs.log("Packet tunnel provider cancelled with error: \(error as Any)")
    }

}

extension PacketTunnelProvider {
    
    #if DEBUG
    static let debugLogsKey = AppGroupStorage.Key<[String]>(rawValue: "com.confirmed.packettunnelprovider.debuglogs")
    
    func debugLog(_ string: String) {
        let string = "DEBUG LOG \(PacketTunnelProviderLogs.dateFormatter.string(from: Date())) \(string)"
        if var existing = AppGroupStorage.shared.read(key: PacketTunnelProvider.debugLogsKey) {
            existing.append(string)
            AppGroupStorage.shared.write(content: existing, key: PacketTunnelProvider.debugLogsKey)
        } else {
            AppGroupStorage.shared.write(content: [string], key: PacketTunnelProvider.debugLogsKey)
        }
    }
    
    func flushDebugLogsToPacketTunnelProviderLogs() {
        if let existing = AppGroupStorage.shared.read(key: PacketTunnelProvider.debugLogsKey) {
            for entry in existing {
                PacketTunnelProviderLogs.log(entry)
            }
            AppGroupStorage.shared.delete(forKey: PacketTunnelProvider.debugLogsKey)
        }
    }
    #endif
}

extension NEProviderStopReason: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .none:
            return "none"
        case .userInitiated:
            return "userInitiated"
        case .providerFailed:
            return "providerFailed"
        case .noNetworkAvailable:
            return "noNetworkAvailable"
        case .unrecoverableNetworkChange:
            return "unrecoverableNetworkChange"
        case .providerDisabled:
            return "providerDisabled"
        case .authenticationCanceled:
            return "authenticationCanceled"
        case .configurationFailed:
            return "configurationFailed"
        case .idleTimeout:
            return "idleTimeout"
        case .configurationDisabled:
            return "configurationDisabled"
        case .configurationRemoved:
            return "configurationRemoved"
        case .superceded:
            return "superceded"
        case .userLogout:
            return "userLogout"
        case .userSwitch:
            return "userSwitch"
        case .connectionFailed:
            return "connectionFailed"
        case .sleep:
            return "sleep"
        case .appUpdate:
            return "appUpdate"
        }
    }
}
