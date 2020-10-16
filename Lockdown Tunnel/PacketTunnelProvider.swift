//
//  PacketTunnelProvider.swift
//  LockdownTunnel
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import NetworkExtension
import NEKit

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
                        #if DEBUG
                        PacketTunnelProviderLogs.log("whitelisted \(session.host), not blocking")
                        #endif
                        return
                    }
                }
                // else if firewall on, then block
                if (getUserWantsFirewallEnabled()) {
                    updateMetrics(.incrementAndLog(host: session.host), rescheduleNotifications: .withEnergySaving)
                    #if DEBUG
                    PacketTunnelProviderLogs.log("session host: \(session.host)")
                    #endif
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
        PacketTunnelProviderLogs.log("startTunnel function called")
        
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
//        if ( getUserWantsVPNEnabled() == true ) { // only add whitelist if user wants VPN active
        // bugfix: attempting to fix issue with whitelist sometimes breaking
             combined = combined + getAllWhitelistedDomains()
//        }
        proxySettings.matchDomains = combined
        
        settings.dnsSettings = NEDNSSettings(servers: ["127.0.0.1"])
        settings.proxySettings = proxySettings;
        RawSocketFactory.TunnelProvider = self
        ObserverFactory.currentFactory = LDObserverFactory()
        
        self.setTunnelNetworkSettings(settings, completionHandler: { error in
            guard error == nil else {
                PacketTunnelProviderLogs.log("Error setting tunnel network settings \(error as Any)")
                completionHandler(error)
                return
            }
            self.proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
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
