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
    
    var _dns: DNSCryptThread!;
    
    //MARK: - OVERRIDES
    
    func getNetworkSettings() -> NEPacketTunnelNetworkSettings {
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        let dnsSettings = NEDNSSettings(servers:["127.0.0.1"])
        dnsSettings.matchDomains = [""];
        
        //var ipv4Settings = NEIPv4Settings(addresses: ["192.0.2.1"], subnetMasks: "255.255.255.0")
        //networkSettings.ipv4Settings = ipv4Settings;
        
        networkSettings.dnsSettings = dnsSettings;
        
        return networkSettings;
    }
    
    func startProxy() {
        _dns.start()
    }
    
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {

        // usleep(10000000)
        
        let configFile = Bundle.main.url(forResource: "dnscrypt-proxy", withExtension: "toml")
        
        let blocklistFile = Bundle.main.url(forResource: "blocked-names", withExtension: "txt")
        
        print("configFilePath")
        print(configFile!.absoluteString)
        print("blocklistFilepath")
        print(blocklistFile!.absoluteString)
        
        let fileManager = FileManager.default
        
        var sharedDir = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.confirmed")
        
        // create directory if not exists
        let filePath = sharedDir!.appendingPathComponent("dnscrypt")
        if !FileManager.default.fileExists(atPath: filePath.path) {
            do {
                try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                let e = error
            }
        }

        // copy blocklist file into shared dir and check its content
        var newContentFile = sharedDir!.appendingPathComponent("blacklist.txt")
        var newContentFilePath = newContentFile.path;
        if fileManager.fileExists(atPath: newContentFile.path){
            do{
                try fileManager.removeItem(atPath: newContentFile.path)
            }catch let error {
                print("error occurred, here are the details:\n \(error)")
            }
        }
        
        
        do {
            let content = try String(contentsOf: blocklistFile!, encoding: .utf8)
            let a = "blah"
            do {
                try content.write(to: newContentFile, atomically: true, encoding: .utf8)
            }
            catch {
                var e = error
            }
            do {
                let blocklistFileContent = try String(contentsOf: newContentFile, encoding: .utf8)
                let a = "blah"
            }
            catch {
                var e = error
            }
            
        }
        catch {
            var e = error
        }
        
        //clear prefix suffix files
        var prefixFile = sharedDir!.appendingPathComponent("blacklist.txt.prefixes")
        var suffixFile = sharedDir!.appendingPathComponent("blacklist.txt.suffixes")
        if fileManager.fileExists(atPath: prefixFile.path){
            do{
                try fileManager.removeItem(atPath: prefixFile.path)
            }catch let error {
                print("error occurred, here are the details:\n \(error)")
            }
        }
        if fileManager.fileExists(atPath: suffixFile.path){
            do{
                try fileManager.removeItem(atPath: suffixFile.path)
            }catch let error {
                print("error occurred, here are the details:\n \(error)")
            }
        }
        
        // fill new pre/suff files
        var errorPtr: NSErrorPointer = nil
        DnscryptproxyFillPatternlistTrees(newContentFile.path, errorPtr)
        if let error = errorPtr?.pointee {
            let zz = error
        }
        
        // show what pre/suff files contents
        do {
            let content = try String(contentsOf: prefixFile, encoding: .utf8)
            let content2 = try String(contentsOf: suffixFile, encoding: .ascii)
            let a = "blah"
        }
        catch {
            var e = error
            var zz = e
        }
        
        
        
        
        var configFileText = ""
        
        do {
            configFileText = try String(contentsOf: configFile!, encoding: .utf8)
        }
        catch {
            let e = error
        }
        
        let blockListFilePath = blocklistFile!.absoluteString.replacingOccurrences(of: "file://", with: "")
        
        // replace
        let replacedConfig = configFileText.replacingOccurrences(of: "BLACKLIST_FILE_HERE", with: "\(newContentFile.path)").replacingOccurrences(of: "BLACKLIST_LOG_HERE", with: "\(sharedDir!.appendingPathComponent("blacklistlog.log").absoluteString.replacingOccurrences(of: "file://", with: ""))")
        
        var replacedConfigURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // write replaced string to new file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

            replacedConfigURL = dir.appendingPathComponent("replaced-config.toml")

            //writing
            do {
                try replacedConfig.write(to: replacedConfigURL, atomically: false, encoding: .utf8)
            }
            catch {
                var e = error
            }

            //reading blocklist  file
            do {
                let blocklistFileContent = try String(contentsOf: blocklistFile!, encoding: .utf8)
                let a = "blah"
            }
            catch {
                var e = error
            }
            
            //reading
            do {
                let replacedConfigText = try String(contentsOf: replacedConfigURL, encoding: .utf8)
                let a = "blah"
            }
            catch {
                var e = error
            }
        }
        
        // print the directory to see what's there
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: sharedDir!,
                includingPropertiesForKeys: nil
            )
            var cont = ""
            for url in directoryContents {
                cont = cont + "\n" + url.absoluteString
            }
            let z = cont
            let dfsd = "abc"
        }
        catch {
            let e = error
        }
        
        
        let networkSettings = getNetworkSettings()
        
        _dns = DNSCryptThread(arguments: [replacedConfigURL.path]);
        
        
        startProxy();
        
        self.setTunnelNetworkSettings(networkSettings, completionHandler: { error in
            if (error != nil) {
                completionHandler(error);
            } else {
                completionHandler(nil);
            }
        })
        
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler();
        exit(EXIT_SUCCESS);
    }
    
//    override func sleep(completionHandler: @escaping () -> Void) {
//        completionHandler();
//    }
//
//    override func wake() {
//        super.wake()
//        // TODO: reactivate, etc
//    }
    
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
