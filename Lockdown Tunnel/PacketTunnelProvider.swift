//
//  PacketTunnelProvider.swift
//  LockdownTunnel
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import NetworkExtension
import NEKit
import CocoaLumberjackSwift

class LDObserverFactory: ObserverFactory {
    
    override func getObserverForProxySocket(_ socket: ProxySocket) -> Observer<ProxySocketEvent>? {
        return LDProxySocketObserver();
    }
    
    class LDProxySocketObserver: Observer<ProxySocketEvent> {

        let whitelistedDomains = getAllWhitelistedDomains()
        
        override func signal(_ event: ProxySocketEvent) {
            switch event {
            case .receivedRequest(let session, let socket):
                // this is for testing if the blocking is working correctly - always block this
                if (session.host == testFirewallDomain) {
                    socket.forceDisconnect()
                    return
                }
                // if domain is in whitelist, just return (user probably didn't whitelist something they want to block
                for whitelistedDomain in whitelistedDomains {
                    if (session.host.hasSuffix("." + whitelistedDomain) || session.host == whitelistedDomain) {
                        DDLogInfo("whitelisted \(session.host), not blocking")
                        return
                    }
                }
                // else if firewall on, then block
                if (getUserWantsFirewallEnabled()) {
                    incrementMetricsAndLog(host: session.host);
                    DDLogInfo("session host: \(session.host)")
                    socket.forceDisconnect()
                    return
                }
            default:
                break;
            }
        }
        
    }
    
}

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
        if ( getUserWantsVPNEnabled() == true ) { // only add whitelist if user wants VPN active
             combined = combined + getAllWhitelistedDomains()
        }
        proxySettings.matchDomains = combined
        
        settings.dnsSettings = NEDNSSettings(servers: ["127.0.0.1"])
        settings.proxySettings = proxySettings;
        RawSocketFactory.TunnelProvider = self
        ObserverFactory.currentFactory = LDObserverFactory()
        
        self.setTunnelNetworkSettings(settings, completionHandler: { error in
            self.proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
            do {
                try self.proxyServer.start()
                completionHandler(nil)
            }
            catch {
                DDLogError("Error starting proxy server \(error)")
                completionHandler(error)
            }
        })
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        DNSServer.currentServer = nil
        RawSocketFactory.TunnelProvider = nil
        ObserverFactory.currentFactory = nil
        proxyServer.stop()
        proxyServer = nil
        DDLogError("LockdownTunnel: error on stopping: \(reason)")
        
        completionHandler()
        exit(EXIT_SUCCESS)
    }

}
