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
import PromiseKit
import CocoaLumberjack

var latestBlockedDomains = getAllBlockedDomains()

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let dnsServerAddress = "127.0.0.1"
    var _dns: DNSCryptThread!;
    
    let proxyServerAddress = "127.0.0.1";
    let proxyServerPort: UInt16 = 9090;
    var proxyServer: GCDHTTPProxyServer!
    
    let monitor = NWPathMonitor()
    let fileManager = FileManager.default
    let groupContainer = "group.com.confirmed"
    
    let lastReachabilityKillKey = "lastReachabilityKillTime"
    
    func log(_ str: String) {
        PacketTunnelProviderLogs.log(str)
        NSLog("ptplog - " + str)
    }
    
    override func cancelTunnelWithError(_ error: Error?) {
        self.log("===== ERROR - cancelTunnelWithError \(error?.localizedDescription ?? "")")
    }
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        log("+++++ startTunnel NEW")
        
        // usleep(10000000)
        
        // reachability check
        monitor.pathUpdateHandler = { path in
            self.log("REACHABILITY - Connected: \(path.status == .satisfied) - NWPATH: \(path.debugDescription)")
            let servers = Resolver().getservers().map(Resolver.getnameinfo)
            self.log("REACHABILITY DNS Servers: \(servers)")
            
            self.log("reachability testing network")
            self.checkNetworkConnection { success in
                self.log("reachability network check result: \(success)")
                if( success == false ) {
                    self.log("ERROR - network check failed, killing PTP if not killed in the last 30 seconds")
                    
                    // only kill PTP if it hasnt been killed in the last 30 seconds - to avoid race conditions/infinite loop
                    // TODO: maybe force VPN restart too?
                    // TODO: maybe force wait a second on stopping?
                    // TODO: make this smarter e.g- if PTP has been killed in the last 30 seconds, wait 10 seconds to kill it
                    let timeIntervalOfLastReachabilityKill = defaults.double(forKey: self.lastReachabilityKillKey)
                    let dateOfLastReachabilityKill = Date(timeIntervalSince1970: timeIntervalOfLastReachabilityKill)
                    let timeSinceLastReachabilityKill = Date().timeIntervalSince(dateOfLastReachabilityKill)
                    self.log("REACHABILITY kill - time since last kill: \(timeSinceLastReachabilityKill)")
                    if (timeSinceLastReachabilityKill < 60) {
                        self.log("REACHABILITY kill - did this < 30 seconds ago, not calling it again")
//                        return
                    }
                    else {
                        // do the kill
                        defaults.set(Date().timeIntervalSince1970, forKey: self.lastReachabilityKillKey)
//                        self.stopTunnel(with: .connectionFailed, completionHandler: {
//                            self.log("successfully stopped tunnel from reachability")
//                        })
                    }
                }
            }
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
        
        let networkSettings = getNetworkSettings();
        
        log("Calling setTunnelNetworkSettings")
        self.setTunnelNetworkSettings(networkSettings, completionHandler: { error in
            if (error != nil) {
                self.log("ERROR - StartTunnel \(error!.localizedDescription)")
                completionHandler(error);
            } else {
                self.log("No error on setTunnelNetworkSettings, starting dns and proxy")
                
                self.initializeDns();
                self.initializeProxy();

                self.startDns();
                if let proxyError = self.startProxy() {
                    self.log("ERROR - Failed to start proxy: \(proxyError)")
                    completionHandler(proxyError)
                }
                else {
                    self.log("SUCCESS - startTunnel")
                    completionHandler(nil)
//                    self.log("||||| startTunnel - checking availability to apple.com")
//                    self.checkNetworkConnection(callback: { success in
//                        self.log("startTunnel network check result: \(success)")
//                        // failures are already handled by Reachability check
//                        completionHandler(nil)
//
//                    })
                }
            }
        })
        
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        self.log("+++++ stopTunnel with reason: \(reason)")
        monitor.cancel()
        stopProxyServer()
        stopDnsServer()
            self.log("stopTunnel completionHandler, exit")
            completionHandler();
            exit(EXIT_SUCCESS);
    }

//    override func wake() {
//        log("===== wake")
//        flushBlockLog(log: log)
//        log("wake setting tunnel network settings to nil")
//        self.setTunnelNetworkSettings(nil, completionHandler: { error in
//            if (error != nil) {
//                self.log("error setting tunnelnetworksettings to nil: \(error)")
//            }
//            self.log("wake calling reactivate tunnel")
//            self.reactivateTunnel()
//        })
//    }
    
    func getNetworkSettings() -> NEPacketTunnelNetworkSettings {
        log("===== getNetworkSettings")
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: dnsServerAddress)
        networkSettings.mtu = 1500
        
        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.httpsEnabled = true;
        proxySettings.httpsServer = NEProxyServer(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.excludeSimpleHostnames = false;
        proxySettings.exceptionList = []
        proxySettings.matchDomains = getAllWhitelistedDomains()
        networkSettings.proxySettings = proxySettings;
        
//        let ipv6Settings = NEIPv6Settings()
//        ipv6Settings.includedRoutes = [NEIPv6Route(destinationAddress: "::", networkPrefixLength: 0)]
//        networkSettings.ipv6Settings = ipv6Settings
        
//        let ipv4Settings = NEIPv4Settings()
//        ipv4Settings.excludedRoutes = [NEIPv4Route(destinationAddress: "0.0.0.0", subnetMask: "128.0.0.0")]
//        networkSettings.ipv4Settings = ipv4Settings
        
//        proxySettings.exceptionList = ["mask.icloud.com", "mask-api.icloud.com", "mask-h2.icloud.com", "mask.apple-dns.net", "icloud.com", "apple.com"]
//        var toMatch = getAllWhitelistedDomains()
//        proxySettings.matchDomains = toMatch
//        proxySettings.autoProxyConfigurationEnabled = true
//        var js = "function FindProxyForURL(url, host) { "
////        js = js + "if (dnsDomainIs(host, \"mask.icloud.com\") || dnsDomainIs(host, \"mask-h2.icloud.com\") || dnsDomainIs(host, \"mask.apple-dns.net\") || dnsDomainIs(host, \"mask-api.icloud.com\") || dnsDomainIs(host, \"icloud.com\") || dnsDomainIs(host, \"apple.com\")) { "
////        js = js + "return 'DIRECT'; } "
////        js = js + "if ("
////        for domain in getAllWhitelistedDomains() {
////            js = js + "dnsDomainIs(host, \"\(domain)\") || "
////        }
////        js = js + " false )"
////        js = js + " { return 'PROXY \(proxyServerAddress):\(proxyServerPort)'; } "
//        js = js + "return 'PROXY \(proxyServerAddress):\(proxyServerPort)';"
//        js = js + " }"
//        NSLog(js)
//        proxySettings.proxyAutoConfigurationJavaScript = js
////        proxySettings.proxyAutoConfigurationJavaScript = """
////        function FindProxyForURL(url, host)
////        {
////            if (dnsDomainIs(host, "ipchicken.com") )
////            {
////                return 'PROXY \(proxyServerAddress):\(proxyServerPort)';
////            }
////            return 'DIRECT';
////        }
////        """
        
        let dnsSettings = NEDNSSettings(servers: [dnsServerAddress])
        dnsSettings.matchDomains = [""];
        networkSettings.dnsSettings = dnsSettings;
        
        return networkSettings;
    }
    
    func initializeAndReturnConfigPath() -> String {
        log("===== initializeAndReturnConfigPath")
        
        let configFile = Bundle.main.url(forResource: "dnscrypt-proxy", withExtension: "toml")
        let sharedDir = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupContainer)

        // remove blocklist if it exists
        let newBlocklistFile = sharedDir!.appendingPathComponent("blocklist.txt")
        if fileManager.fileExists(atPath: newBlocklistFile.path) {
            log("blocklist.txt exists")
            do {
                try fileManager.removeItem(atPath: newBlocklistFile.path)
                log("removed old blocklist.txt")
            } catch {
                log("ERROR - couldnt remove old blocklist.txt: \(error)")
            }
        }
        
        // generate text for new blocklist
        let blockedDomainsArray = getAllBlockedDomains()
        var blockedDomains: String = testFirewallDomain
        for blockedDomain in blockedDomainsArray {
            blockedDomains = blockedDomains + "\n" + blockedDomain
        }
        
        // copy blocklist file into shared dir
        do {
            try blockedDomains.write(to: newBlocklistFile, atomically: false, encoding: .utf8)
            log("wrote content to blocklist.txt")
        }
        catch {
            log("ERROR - couldnt write content to blocklist.txt: \(error)")
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
        log("filling in prefix/suffix files at: \(newBlocklistFile.path)")
        DnscryptproxyFillPatternlistTrees(newBlocklistFile.path, errorPtr)
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
        let replacedConfig = configFileText.replacingOccurrences(of: "BLOCKLIST_FILE_HERE", with: "\(newBlocklistFile.path)").replacingOccurrences(of: "BLOCKLIST_LOG_HERE", with: "\(sharedDir!.appendingPathComponent("blocklist.log").path)")
        
        // write replaced string to new file
        let replacedConfigURL = sharedDir!.appendingPathComponent("replaced-config.toml")
        log("replaced config file url: \(replacedConfigURL.path)")
        do {
            try replacedConfig.write(to: replacedConfigURL, atomically: false, encoding: .utf8)
            log("replaced config written")
        }
        catch {
            log("ERROR - couldn't write replaced config: \(error)")
        }
        log("returning replacedConfigURL \(replacedConfigURL)")
        return replacedConfigURL.path
    }
    
    func initializeDns() {
        log("===== initialize DNS server")
        // stopDnsServer()
        log("initializing DNSCryptThread")
        _dns = DNSCryptThread(arguments: [initializeAndReturnConfigPath()]);
    }
    
    func initializeProxy() {
        log("===== initialize proxy server")
        // stopProxyServer()
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
//        _dns.closeIdleConnections()
        
        let networkSettings = getNetworkSettings()
        
        self.setTunnelNetworkSettings(networkSettings, completionHandler: { error in
            if (error != nil) {
                self.log("ERROR - reactivateTunnel setTunnelNetworkSettings: \(error?.localizedDescription)")
            }
            self.log("reactivateTunnel setTunnelNetworkSettings complete, reasserting false")
            self.reasserting = false
            
            self._dns.closeIdleConnections()
            self.log("closed idle connections")
            
            self.log("||||| reactivate AFTER - checking availability to apple.com")
            self.checkNetworkConnection(callback: { success in
                self.log("ReactivateTunnel checkNetworkConnection result: \(success)")
                
            } )
        })
        
        startDns()
    }
    
    func checkNetworkConnection( callback: @escaping (Bool) -> Void ) {

        log("===== checkNetworkConnection - attempt #1")
        URLCache.shared.removeAllCachedResponses()
        firstly {
            try makeNetworkConnection()
        }
        .map { data, response -> Void in
            try self.validateNetworkResponse(response: response)
            callback(true)
        }
        .catch { error in
            self.log("ERROR - failed checkNetworkConnection attempt #1: \(error)")
            self.log("checkNetworkConnection - attempt #2")
            DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + 5) {
                firstly {
                    try self.makeNetworkConnection()
                }
                .map { data, response -> Void in
                    try self.validateNetworkResponse(response: response)
                    callback(true)
                }
                .catch { error in
                    self.log("ERROR - failed checkNetworkConnection attempt #2: \(error)")
                    self.log("checkNetworkConnection - attempt #3")
                    DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + 15) {
                        firstly {
                            try self.makeNetworkConnection()
                        }
                        .map { data, response -> Void in
                            try self.validateNetworkResponse(response: response)
                            callback(true)
                        }
                        .catch { error in
                            self.log("ERROR - failed checkNetworkConnection attempt #3: \(error)")
                            callback(false)
                        }
                    }
                }
            }
        }
    }
    
    func makeNetworkConnection() throws -> Promise<(data: Data, response: URLResponse)> {
        return URLSession.shared.dataTask(.promise, with: try Client.makeGetRequest(urlString: "https://apple.com"))
    }
    
    func validateNetworkResponse(response: URLResponse?) throws {
        self.log("validating checkNetworkConnection response")
        if let resp = response as? HTTPURLResponse {
            if (resp.statusCode >= 400 || resp.statusCode <= 0) {
                self.log("response has bad status code \(resp.statusCode)")
                throw "response has bad status code \(resp.statusCode)"
            }
            else {
                self.log("response has good status code (2xx, 3xx) and no error code")
            }
        }
        else {
            throw "Invalid URL Response received: \(String(describing: response))"
        }
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

//open class Resolver {
//
//    fileprivate var state = __res_9_state()
//
//    public init() {
//        res_9_ninit(&state)
//    }
//
//    deinit {
//        res_9_ndestroy(&state)
//    }
//
//    public final func getservers() -> [res_9_sockaddr_union] {
//
//        let maxServers = 10
//        var servers = [res_9_sockaddr_union](repeating: res_9_sockaddr_union(), count: maxServers)
//        let found = Int(res_9_getservers(&state, &servers, Int32(maxServers)))
//
//        // filter is to remove the erroneous empty entry when there's no real servers
//       return Array(servers[0 ..< found]).filter() { $0.sin.sin_len > 0 }
//    }
//}
//
//extension Resolver {
//    public static func getnameinfo(_ s: res_9_sockaddr_union) -> String {
//        var s = s
//        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
//
//        let sinlen = socklen_t(s.sin.sin_len)
//        let _ = withUnsafePointer(to: &s) {
//            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
//                Darwin.getnameinfo($0, sinlen,
//                                   &hostBuffer, socklen_t(hostBuffer.count),
//                                   nil, 0,
//                                   NI_NUMERICHOST)
//            }
//        }
//
//        return String(cString: hostBuffer)
//    }
//}

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
