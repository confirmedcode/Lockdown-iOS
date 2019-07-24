//
//  PacketTunnelProvider.swift
//  LockdownTunnel
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import NetworkExtension
import NEKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    //MARK: - OVERRIDES
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
        if proxyServer != nil {
            proxyServer.stop()
        }
        proxyServer = nil
        let settings = NEPacketTunnelNetworkSettings.init(tunnelRemoteAddress: proxyServerAddress)
        let ipv4Settings = NEIPv4Settings.init(addresses: ["10.0.0.8"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = getLockdownIPs()
        let ipv6Settings = NEIPv6Settings.init(addresses: ["fe80:1ca8:5ee3:4d6d:aaf5"], networkPrefixLengths: [64])
        ipv6Settings.includedRoutes = getLockdownIPv6()
        settings.ipv4Settings = ipv4Settings;
        settings.ipv6Settings = ipv6Settings;
        settings.mtu = NSNumber.init(value: 1500)
        
        let proxySettings = NEProxySettings.init()
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.httpsEnabled = true;
        proxySettings.httpsServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.excludeSimpleHostnames = false;
        proxySettings.exceptionList = []
        proxySettings.matchDomains = getLockdownRules() // ["*.apple.com", "*.confirmedvpn.com", "*.ipchicken.com"]
        proxySettings.autoProxyConfigurationEnabled = true
        proxySettings.proxyAutoConfigurationJavaScript = "function FindProxyForURL(url, host) { return \"127.0.0.1:9090\"; }"
        
        settings.dnsSettings = NEDNSSettings.init(servers: ["127.0.0.1"])
        settings.proxySettings = proxySettings;
        RawSocketFactory.TunnelProvider = self
        
        self.setTunnelNetworkSettings(settings, completionHandler: { error in
            self.proxyServer = LockdownProxy.init(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
            
            try? self.proxyServer.start()
            //print("confirmed.lockdown.tunnel: error on start: \(String(describing: error))")
            completionHandler(error)
        })
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        DNSServer.currentServer = nil
        RawSocketFactory.TunnelProvider = nil
        proxyServer.stop()
        proxyServer = nil
        print("confirmed.lockdown.tunnel: error on start: \(reason)")
        
        completionHandler()
        exit(EXIT_SUCCESS)
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        super.handleAppMessage(messageData, completionHandler: completionHandler)
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        super.sleep(completionHandler: completionHandler)
        completionHandler()
    }
    
    override func wake() {
        super.wake()
        return
    }
    
    //MARK: - ACTION
    
    func getJavascriptProxyForRules () -> String {
        let domains = getProxyRules()
        let lockdowns = getLockdownRules()
        
        if domains.count == 0 && lockdowns.count == 0 {
            return "function FindProxyForURL(url, host) { return \"127.0.0.1:123\" }"
        }
        else {
            
            //forced URLs to go through VPN (right now just IP address to show to user)
            let forcedVPNConditions = "dnsDomainIs(host, \"ip.confirmedvpn.com\")"
            
            var conditions = ""
            for (index, domain) in domains.enumerated() {
                if index > 0 {
                    conditions = conditions + " || "
                }
                let formattedDomain = domain.replacingOccurrences(of: "*.", with: "")
                conditions = conditions + "dnsDomainIs(host, \"" + formattedDomain + "\")"
            }
            
            var lockdownConditions = ""
            for (index, domain) in lockdowns.enumerated() {
                if index > 0 {
                    lockdownConditions = lockdownConditions + " || "
                }
                let formattedDomain = domain.replacingOccurrences(of: "*.", with: "")
                lockdownConditions = lockdownConditions + "dnsDomainIs(host, \"" + formattedDomain + "\")"
            }
            
            return "function FindProxyForURL(url, host) { return \"127.0.0.1:123\"; }"
        }
    }
    
    func getUserLockdown() -> Dictionary<String, Any> {
        let defaults = UserDefaults(suiteName: "group.com.confirmed")!
        
        if let domains = defaults.dictionary(forKey:Global.kUserLockdownDomains) {
            return domains
        }
        return Dictionary()
    }
    
    func getConfirmedLockdown() -> LockdownDefaults {
        let defaults = UserDefaults(suiteName: "group.com.confirmed")!
        
        guard let lockdownDefaultsData = defaults.object(forKey: Global.kConfirmedLockdownDomains) as? Data else {
            return LockdownDefaults.init(lockdownDefaults: [:])
        }
        
        guard let lockdownDefaults = try? PropertyListDecoder().decode(LockdownDefaults.self, from: lockdownDefaultsData) else {
            return LockdownDefaults.init(lockdownDefaults: [:])
        }
        
        return lockdownDefaults
    }
    
    //ipV4 only
    func getLockdownIPs() -> Array<NEIPv4Route> {
        var ipRoutes = Array<NEIPv4Route>.init()
        
        let domains = getConfirmedLockdown()
        for (ldKey, ldValue) in domains.lockdownDefaults {
            if ldValue.enabled {
                for (key, value) in ldValue.ipRanges {
                    if !value.IPv6 {
                        ipRoutes.append(NEIPv4Route.init(destinationAddress: key, subnetMask: value.subnetMask))
                    }
                }
            }
        }
        return ipRoutes
    }
    
    //ipV6 only
    func getLockdownIPv6() -> Array<NEIPv6Route> {
        var ipRoutes = Array<NEIPv6Route>.init()
        
        let domains = getConfirmedLockdown()
        for (ldKey, ldValue) in domains.lockdownDefaults {
            if ldValue.enabled {
                for (key, value) in ldValue.ipRanges {
                    if value.IPv6 {
                        if let bits = Int(value.subnetMask) {
                            ipRoutes.append(NEIPv6Route.init(destinationAddress: key, networkPrefixLength: NSNumber(value: bits)))
                        }
                        
                    }
                }
            }
        }
        return ipRoutes
    }
    
    func getLockdownRules() -> Array<String> {
        let domains = getConfirmedLockdown()
        let userDomains = getUserLockdown()
        
        var whitelistedDomains = Array<String>.init()
        
        //combine user rules with confirmed rules
        for (ldKey, ldValue) in domains.lockdownDefaults {
            if ldValue.enabled {
                for (key, value) in ldValue.domains {
                    if value {
                        var formattedKey = key
                        if key.split(separator: ".").count == 1 {
                            formattedKey = "*." + key //wildcard for two part domains
                        }
                        whitelistedDomains.append(formattedKey)
                    }
                }
            }
        }
        
        for (key, value) in userDomains {
            if (value as AnyObject).boolValue {
                var formattedKey = key
                if key.split(separator: ".").count == 1 {
                    formattedKey = "*." + key
                }
                whitelistedDomains.append(formattedKey)
            }
        }
        
        return whitelistedDomains
    }
    
    func getConfirmedWhitelist() -> Dictionary<String, Any> {
        let defaults = UserDefaults(suiteName: "group.com.confirmed")!
        
        if let domains = defaults.dictionary(forKey:Global.kConfirmedWhitelistedDomains) {
            return domains
        }
        return Dictionary()
    }
    
    func getUserWhitelist() -> Dictionary<String, Any> {
        let defaults = UserDefaults(suiteName: "group.com.confirmed")!
        
        if let domains = defaults.dictionary(forKey:Global.kUserWhitelistedDomains) {
            return domains
        }
        return Dictionary()
    }
    
    func getProxyRules() -> Array<String> {
        let domains = getConfirmedWhitelist()
        let userDomains = getUserWhitelist()
        
        var whitelistedDomains = Array<String>.init()
        
        //combine user rules with confirmed rules
        for (key, value) in domains {
            if (value as AnyObject).boolValue { //filter for approved by user
                var formattedKey = key
                if key.split(separator: ".").count == 1 {
                    formattedKey = "*." + key //wildcard for two part domains
                }
                whitelistedDomains.append(formattedKey)
            }
        }
        
        for (key, value) in userDomains {
            if (value as AnyObject).boolValue {
                var formattedKey = key
                if key.split(separator: ".").count == 1 {
                    formattedKey = "*." + key
                }
                whitelistedDomains.append(formattedKey)
            }
        }
        
        return whitelistedDomains
    }
    
    //MARK: - VARIABLES
    
    let proxyServerPort : UInt16 = 9090;
    let proxyServerAddress = "127.0.0.1";
    var proxyServer: LockdownProxy!
    
}
