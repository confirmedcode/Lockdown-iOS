//
//  PacketTunnelProvider.swift
//  LockdownTunnel
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import NetworkExtension
import NEKit
import Dnscryptproxy
import Network

var latestBlockedDomains = getAllBlockedDomains()

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let dnsServerAddress = "127.0.0.1"
    var _dns: DNSCryptThread!;
    
    let proxyServerAddress = "127.0.0.1";
    let proxyServerPort: UInt16 = 9090;
    var proxyServer: GCDHTTPProxyServer!
    
    let monitor = NWPathMonitor()
    
    func log(_ str: String) {
        PacketTunnelProviderLogs.log(str)
    }
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        log("===== startTunnel")
        
        // usleep(10000000)
        
//        monitor.pathUpdateHandler = { path in
//            if path.status == .satisfied {
//                print("We're connected!")
//            } else {
//                print("No connection.")
//            }
//            print(path.isExpensive)
//
//            let servers = Resolver().getservers().map(Resolver.getnameinfo)
//            print(servers)
//        }
//
//        let queue = DispatchQueue(label: "Monitor")
//        monitor.start(queue: queue)
        
        let networkSettings = getNetworkSettings();
        
        initializeDns();
        initializeProxy();

        startDns();
        if let proxyError = startProxy() {
            log("ERROR - Failed to start proxy: \(proxyError)")
            return completionHandler(proxyError)
        }
        
        log("Calling setTunnelNetworkSettings")
        self.setTunnelNetworkSettings(networkSettings, completionHandler: { error in
            if (error != nil) {
                self.log("ERROR - StartTunnel \(error)")
                completionHandler(error);
            } else {
                self.log("No error on setTunnelNetworkSettings")
                completionHandler(nil);
            }
        })
        
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        self.log("===== stopTunnel")
        stopProxyServer()
        stopDnsServer()
        self.log("stopTunnel completionHandler, exit")
        completionHandler();
        exit(EXIT_SUCCESS);
    }

    override func wake() {
        log("===== wake")
        reactivateTunnel()
    }
    
    func getNetworkSettings() -> NEPacketTunnelNetworkSettings {
        log("===== getNetworkSettings")
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: dnsServerAddress)
        
        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.httpsEnabled = true;
        proxySettings.httpsServer = NEProxyServer(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.excludeSimpleHostnames = false;
        proxySettings.exceptionList = []
        proxySettings.matchDomains = getAllWhitelistedDomains()
        networkSettings.proxySettings = proxySettings;
        
        let dnsSettings = NEDNSSettings(servers: [dnsServerAddress])
        dnsSettings.matchDomains = [""];
        networkSettings.dnsSettings = dnsSettings;
        
        //var ipv4Settings = NEIPv4Settings(addresses: ["192.0.2.1"], subnetMasks: "255.255.255.0")
        //networkSettings.ipv4Settings = ipv4Settings;
        
        return networkSettings;
    }
    
    func initializeAndReturnConfigPath() -> String {
        log("===== initializeAndReturnConfigPath")
        
        let fileManager = FileManager.default
        let configFile = Bundle.main.url(forResource: "dnscrypt-proxy", withExtension: "toml")
        let blocklistFile = Bundle.main.url(forResource: "blocked-names", withExtension: "txt")
        let sharedDir = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.confirmed")

        // remove blocklist if it exists
        let newContentFile = sharedDir!.appendingPathComponent("blocklist.txt")
        if fileManager.fileExists(atPath: newContentFile.path) {
            log("blocklist.txt exists")
            do {
                try fileManager.removeItem(atPath: newContentFile.path)
                log("removed old blocklist.txt")
            } catch {
                log("ERROR - couldnt remove old blocklist.txt: \(error)")
            }
        }
        
        // copy blocklist file into shared dir
        do {
            let content = try String(contentsOf: blocklistFile!, encoding: .utf8)
            log("loaded blocklist.txt")
            do {
                try content.write(to: newContentFile, atomically: true, encoding: .utf8)
                log("wrote content to blocklist.txt")
            }
            catch {
                log("ERROR - couldnt write content to blocklist.txt: \(error)")
            }
        }
        catch {
            log("ERROR - couldnt read blocklist.txt file: \(error)")
        }
        
        // clear prefix suffix files
        let prefixFile = sharedDir!.appendingPathComponent("blacklist.txt.prefixes")
        let suffixFile = sharedDir!.appendingPathComponent("blacklist.txt.suffixes")
        if fileManager.fileExists(atPath: prefixFile.path){
            log("prefix file exists at: \(prefixFile.path)")
            do {
                try fileManager.removeItem(atPath: prefixFile.path)
                log("prefix file removed at: \(prefixFile.path)")
            } catch {
            }
        }
        if fileManager.fileExists(atPath: suffixFile.path){
            do {
                try fileManager.removeItem(atPath: suffixFile.path)
                log("suffix file removed at: \(suffixFile.path)")
            } catch {
                log("ERROR - error removing suffix file: \(error)")
            }
        }
        
        // create new prefix/suffix files
        let errorPtr: NSErrorPointer = nil
        log("filling in prefix/suffix files at: \(newContentFile.path)")
        DnscryptproxyFillPatternlistTrees(newContentFile.path, errorPtr)
        if let error = errorPtr?.pointee {
            log("ERROR - filling in prefix/suffix files: \(error)")
        }
        
        // read config file template
        var configFileText = ""
        do {
            configFileText = try String(contentsOf: configFile!, encoding: .utf8)
            log("Read config file template")
        }
        catch {
            log("ERROR - couldn't read config file template text at: \(configFile!.path)")
        }
        
        // replace BLOCKLIST_FILE_HERE and BLOCKLIST_LOG_HERE with urls of blocklist file/log
        let replacedConfig = configFileText.replacingOccurrences(of: "BLOCKLIST_FILE_HERE", with: "\(newContentFile.path)").replacingOccurrences(of: "BLOCKLIST_LOG_HERE", with: "\(sharedDir!.appendingPathComponent("blocklist.log").path)")
        var replacedConfigURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // write replaced string to new file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            replacedConfigURL = dir.appendingPathComponent("replaced-config.toml")
            log("replaced config file url: \(replacedConfigURL.path)")
            do {
                try replacedConfig.write(to: replacedConfigURL, atomically: false, encoding: .utf8)
                log("replaced config written")
            }
            catch {
                log("ERROR - couldn't write replaced config: \(error)")
            }
        }
        log("returning replacedConfigURL \(replacedConfigURL)")
        return replacedConfigURL.path
    }
    
    func initializeDns() {
        log("===== initialize DNS server")
        stopDnsServer()
        log("initializing DNSCryptThread")
        _dns = DNSCryptThread(arguments: [initializeAndReturnConfigPath()]);
    }
    
    func initializeProxy() {
        log("===== initialize proxy server")
        stopProxyServer()
        log("initializing GCDHTTPProxyServer")
        proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
    }
    
    func startProxy() -> Error? {
        log("===== startProxy")
        do {
            try self.proxyServer.start()
            log("started proxyServer")
            return nil
        } catch {
            log("ERROR - couldnt start proxyServer")
            return error
        }
    }
    
    func startDns() {
        log("===== startDns")
        _dns.start()
    }
    
    func stopDnsServer() {
        log("===== stopDnsServer")
        if (_dns != nil) {
            log("dns is not nil")
            log("dns closing idle connections")
            _dns.closeIdleConnections()
            log("dns stopApp")
            _dns.stopApp()
            log("dns set to nil")
            _dns = nil
        }
    }
    
    func stopProxyServer() {
        log("===== stopProxyServer")
        if (proxyServer != nil) {
            log("proxyServer is not nil")
            log("proxyServer stop")
            proxyServer.stop()
            log("proxyServer nil")
            proxyServer = nil
        }
    }
    
    func reactivateTunnel() {
        log("===== reactivateTunnel, reasserting true")
        reasserting = true
        
        stopDnsServer()
        stopProxyServer()
        
        initializeDns()
        startDns()
        
        initializeProxy()
        if let error = startProxy() {
            log("ERROR - failed starting proxy \(error)")
        }
        
        let networkSettings = getNetworkSettings()
        
        self.setTunnelNetworkSettings(networkSettings, completionHandler: { error in
            if (error != nil) {
                self.log("ERROR - reactivateTunnel setTunnelNetworkSettings: \(error)")
            }
            self.log("reactivateTunnel setTunnelNetworkSettings complete, reasseting false")
            self.reasserting = false
        })
    }
    
    override func cancelTunnelWithError(_ error: Error?) {
        log("===== cancelTunnelWithError: \(error)")
        // somehow the tunnel failed. kill everything so it can restart again
        stopTunnel(with: .none, completionHandler: {} )
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

open class Resolver {

    fileprivate var state = __res_9_state()

    public init() {
        res_9_ninit(&state)
    }

    deinit {
        res_9_ndestroy(&state)
    }

    public final func getservers() -> [res_9_sockaddr_union] {

        let maxServers = 10
        var servers = [res_9_sockaddr_union](repeating: res_9_sockaddr_union(), count: maxServers)
        let found = Int(res_9_getservers(&state, &servers, Int32(maxServers)))

        // filter is to remove the erroneous empty entry when there's no real servers
       return Array(servers[0 ..< found]).filter() { $0.sin.sin_len > 0 }
    }
}

extension Resolver {
    public static func getnameinfo(_ s: res_9_sockaddr_union) -> String {
        var s = s
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))

        let sinlen = socklen_t(s.sin.sin_len)
        let _ = withUnsafePointer(to: &s) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.getnameinfo($0, sinlen,
                                   &hostBuffer, socklen_t(hostBuffer.count),
                                   nil, 0,
                                   NI_NUMERICHOST)
            }
        }

        return String(cString: hostBuffer)
    }
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
