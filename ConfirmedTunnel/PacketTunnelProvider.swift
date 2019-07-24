//
//  PacketTunnelProvider.swift
//  ConfirmedTunnel
//
//  Created by Rahul Dewan on 3/29/18.
//  Copyright © 2018 Trust Software. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Add code here to start the process of connecting the tunnel.
        
        var settings = NEPacketTunnelNetworkSettings.init(tunnelRemoteAddress: "192.0.2.2")
        
        var ipv4Settings = NEIPv4Settings.init(addresses: ["192.0.2.1"], subnetMasks: ["255.255.255.0"])
        var route = NEIPv4Route.init(destinationAddress: "10.0.0.0", subnetMask: "104.25.112.26")
        
        var excluded = NEIPv4Route.default()// NEIPv4Route.init(destinationAddress: "255.255.255.0", subnetMask: "255.255.255.0")
        
        ipv4Settings.includedRoutes = [route];
        ipv4Settings.excludedRoutes = [excluded]
        //ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
        settings.ipv4Settings = ipv4Settings;
        
        
        //settings.IPv4Settings = ipv4Settings;
        settings.mtu = NSNumber.init(value: 1600)
        var proxySettings = NEProxySettings.init()
        
        var proxyServerPort = 3838;
        var proxyServerName = "localhost";
        
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer.init(address: proxyServerName, port: proxyServerPort)
        proxySettings.httpsEnabled = true;
        proxySettings.httpsServer = NEProxyServer.init(address: proxyServerName, port: proxyServerPort)
        proxySettings.excludeSimpleHostnames = true;
        proxySettings.exceptionList = ["*.ipchicken.com", "www.ipchicken.com"];
        proxySettings.matchDomains = ["*.google.com", "*.hulu.com"];
        
        
        settings.proxySettings = proxySettings;
        
        self.setTunnelNetworkSettings(settings, completionHandler: { error in
            completionHandler(nil)
        })
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
}
