//
//  PacketTunnelProvider.swift
//  LockdownTunnel
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import NetworkExtension
import NEKit
import Dnscryptproxy

var latestBlockedDomains = getAllBlockedDomains()

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let dnsServerAddress = "127.0.0.1"
    var _dns: DNSCryptThread!;
    
    let proxyServerAddress = "127.0.0.1";
    let proxyServerPort: UInt16 = 9090;
    var proxyServer: GCDHTTPProxyServer!
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // usleep(10000000)
        
        let networkSettings = getNetworkSettings();
        
        initializeDns();
        initializeProxy();
        
        startDns();
        if let proxyError = startProxy() {
            return completionHandler(proxyError)
        }
        
        self.setTunnelNetworkSettings(networkSettings, completionHandler: { error in
            if (error != nil) {
                completionHandler(error);
            } else {
                completionHandler(nil);
            }
        })
        
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopProxyServer()
        stopDnsServer()
        completionHandler();
        exit(EXIT_SUCCESS);
    }

    override func wake() {
        super.wake()
        reactivateTunnel()
    }
    
    func getNetworkSettings() -> NEPacketTunnelNetworkSettings {
        
        if proxyServer != nil {
            proxyServer.stop()
        }
        proxyServer = nil
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: dnsServerAddress)
        
        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.httpsEnabled = true;
        proxySettings.httpsServer = NEProxyServer(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.excludeSimpleHostnames = false;
        proxySettings.exceptionList = []
        proxySettings.matchDomains = getAllWhitelistedDomains() + [testFirewallDomain]
        networkSettings.proxySettings = proxySettings;
        
        let dnsSettings = NEDNSSettings(servers: [dnsServerAddress])
        dnsSettings.matchDomains = [""];
        networkSettings.dnsSettings = dnsSettings;
        
        //var ipv4Settings = NEIPv4Settings(addresses: ["192.0.2.1"], subnetMasks: "255.255.255.0")
        //networkSettings.ipv4Settings = ipv4Settings;
        
        return networkSettings;
    }
    
    func initializeAndReturnConfigPath() -> String {
        
        let fileManager = FileManager.default
        let configFile = Bundle.main.url(forResource: "dnscrypt-proxy", withExtension: "toml")
        let blocklistFile = Bundle.main.url(forResource: "blocked-names", withExtension: "txt")
        let sharedDir = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.confirmed")

        // remove blocklist if it exists
        let newContentFile = sharedDir!.appendingPathComponent("blocklist.txt")
        if fileManager.fileExists(atPath: newContentFile.path){
            do{
                try fileManager.removeItem(atPath: newContentFile.path)
            } catch let error {
                print("error occurred, here are the details:\n \(error)")
            }
        }
        
        // copy blocklist file into shared dir
        do {
            let content = try String(contentsOf: blocklistFile!, encoding: .utf8)
            do {
                try content.write(to: newContentFile, atomically: true, encoding: .utf8)
            }
            catch {
                var e = error
            }
        }
        catch {
            var e = error
        }
        
        // clear prefix suffix files
        let prefixFile = sharedDir!.appendingPathComponent("blacklist.txt.prefixes")
        let suffixFile = sharedDir!.appendingPathComponent("blacklist.txt.suffixes")
        if fileManager.fileExists(atPath: prefixFile.path){
            do{
                try fileManager.removeItem(atPath: prefixFile.path)
            } catch let error {
                print("error occurred, here are the details:\n \(error)")
            }
        }
        if fileManager.fileExists(atPath: suffixFile.path){
            do{
                try fileManager.removeItem(atPath: suffixFile.path)
            } catch let error {
                print("error occurred, here are the details:\n \(error)")
            }
        }
        
        // create new prefix/suffix files
        let errorPtr: NSErrorPointer = nil
        DnscryptproxyFillPatternlistTrees(newContentFile.path, errorPtr)
        if let error = errorPtr?.pointee {
            let e = error;
        }
        
        // read config file template
        var configFileText = ""
        do {
            configFileText = try String(contentsOf: configFile!, encoding: .utf8)
        }
        catch {
            let e = error
        }
        
        // replace BLOCKLIST_FILE_HERE and BLOCKLIST_LOG_HERE with urls of blocklist file/log
        let replacedConfig = configFileText.replacingOccurrences(of: "BLOCKLIST_FILE_HERE", with: "\(newContentFile.path)").replacingOccurrences(of: "BLOCKLIST_LOG_HERE", with: "\(sharedDir!.appendingPathComponent("blocklist.log").path)")
        var replacedConfigURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // write replaced string to new file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            replacedConfigURL = dir.appendingPathComponent("replaced-config.toml")
            do {
                try replacedConfig.write(to: replacedConfigURL, atomically: false, encoding: .utf8)
            }
            catch {
                let e = error
            }
        }
        return replacedConfigURL.path
    }
    
    func initializeDns() {
        stopDnsServer()
        _dns = DNSCryptThread(arguments: [initializeAndReturnConfigPath()]);
    }
    
    func initializeProxy() {
        stopProxyServer()
        proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
    }
    
    func startProxy() -> Error? {
        do {
            try self.proxyServer.start()
            return nil
        } catch let proxyError {
            return proxyError
        }
    }
    
    func startDns() {
        _dns.start()
    }
    
    func stopDnsServer() {
        if (_dns != nil) {
            _dns.closeIdleConnections()
            _dns.stopApp()
            _dns = nil
        }
    }
    
    func stopProxyServer() {
        if (proxyServer != nil) {
            proxyServer.stop()
            proxyServer = nil
        }
    }
    
    func reactivateTunnel() {
        
        reasserting = true
        
        stopProxyServer()
        stopDnsServer()
        
        startDns()
        if let proxyError = startProxy() {
            // TODO: error handling
        }
        
        let networkSettings = getNetworkSettings()
        
        self.setTunnelNetworkSettings(networkSettings, completionHandler: { error in
            if (error != nil) {
                self.reasserting = false
            } else {
                self.reasserting = false
            }
        })
    }
    
    // TODO: reachability
    
    // TODO: logging
    
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
