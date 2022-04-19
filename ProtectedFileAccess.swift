//
//  AppGroupStorage.swift
//  LockdowniOS
//
//  Created by Oleg Dreyman on 16.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift

func flushBlockLog( log: (String) -> Void) {
    
    let logFileDateFormatter = DateFormatter()
    logFileDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    logFileDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    
    let lastFlushDateKey = "lastBlockLogFlushTimeInterval"
    
    let fileManager = FileManager.default
    let sharedDir = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.confirmed")
    let blockLogFile = sharedDir!.appendingPathComponent("blocklist.log")
    
    var blockLogFileText = ""
    do {
        blockLogFileText = try String(contentsOf: blockLogFile, encoding: .utf8)
        log("Read block log file")
    }
    catch {
        log("ERROR - couldn't read block log file at: \(blockLogFile.path)")
    }
    
    let blockedEntries = blockLogFileText.split(separator: "\n")
    
    let lastFlushDate = defaults.double(forKey: lastFlushDateKey)
    
    for blockedEntry in blockedEntries {
        // parse this [2022-04-14 22:23:12]    127.0.0.1    example.com    *.example.com
        let splitLine = blockedEntry.split(separator: "\t")
        
        if (splitLine.count != 4) {
            log("ERROR: invalid blocked log entry: \(splitLine)")
            continue
        }
        else {
            // [2022-04-14 22:23:12]
            var entryDateString = String(splitLine[0])
            if (entryDateString.count < 3) {
                log("ERROR: invalid entryDateString - too short: \(entryDateString)")
                continue
            }
            entryDateString.removeLast()
            entryDateString.removeFirst()
            
            let host = String(splitLine[2])
            if (host == testFirewallDomain) {
                // skip this
                continue
            }
            // 2022-04-14 22:23:12
            if let entryDate = logFileDateFormatter.date(from: entryDateString) {
                // only log entries that are newer than lastFlushDate
//                log("entry line: \(blockedEntry)")
//                log("comparing entrydatetime \(entryDate.timeIntervalSince1970) to lastFlushDate \(lastFlushDate)")
//                log("comparing entrydatetime \(entryDate) to lastFlushDate \(Date(timeIntervalSince1970: lastFlushDate))")
                if entryDate.timeIntervalSince1970 <= lastFlushDate {
                //    log("entryDate is older, not logging it")
                    continue
                }
                //log("entryDate is newer, logging it")
                updateMetrics(.incrementAndLog(host: host), rescheduleNotifications: .withEnergySaving)
            }
            else {
                log("ERROR: couldnt format entryDateString: \(entryDateString)")
                continue
            }
        }
    }
    
    // update the last flushed time
    defaults.set(Date().timeIntervalSince1970, forKey: lastFlushDateKey)
    
//    TODO: this doesn't work bc the file is being written to at the same time
//    log("Flushing Block Log File")
//    do {
//        try "".write(to: blockLogFile, atomically: true, encoding: .utf8)
//        log("Flushed Block Log File")
//    }
//    catch {
//        log("Error flushing block log file: \(error)")
//    }
}

enum ProtectedFileAccess {
    
    private static let fileURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.confirmed")!
        .appendingPathComponent("protectionAccess.check")
    
    static var isAvailable: Bool {
        do {
            let data = try Data.init(contentsOf: fileURL, options: [.mappedIfSafe])
            let string = String(data: data, encoding: .utf8)
            return string == "CHECK"
        } catch {
            return false
        }
    }
    
    @available(iOS 10.0, *)
    static func createProtectionAccessCheckFile() {
        if !isAvailable {
            let result = FileManager.default.createFile(
                atPath: fileURL.path,
                contents: "CHECK".data(using: .utf8),
                attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
            if result {
                DDLogInfo("Created protectionAccess.check file")
            } else {
                DDLogError("Failed to create protectionAccess.check file")
            }
        } else {
            DDLogInfo("protectionAccess.check file already exists")
        }
    }
}

enum PacketTunnelProviderLogs {
    
    static let dateFormatter: DateFormatter = {
        $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
        $0.formatterBehavior = .behavior10_4
        $0.locale = .init(identifier: "en_US_POSIX")
        return $0
    }(DateFormatter())
    
    static let userDefaultsKey = "com.confirmed.lockdown.ne_temporaryLogs"
    
    static func log(_ string: String) {
        guard ProtectedFileAccess.isAvailable else {
            return
        }
        
        let string = "\(dateFormatter.string(from: Date())) \(string)"
        if var array = defaults.stringArray(forKey: userDefaultsKey) {
            // don't let it get too large
            if array.count > 40000 {
                array = Array(array.dropFirst(10000))
            }
            array.append(string)
            defaults.setValue(array, forKey: userDefaultsKey)
        } else {
            defaults.setValue([string], forKey: userDefaultsKey)
        }
    }
    
    static var allEntries: [String] {
        return defaults.stringArray(forKey: userDefaultsKey) ?? []
    }
    
    static func clear() {
        defaults.setValue(Array<String>(), forKey: userDefaultsKey)
    }
}

#if DEBUG
final class AppGroupStorage {
    
    struct Key<Value: Codable>: RawRepresentable {
        let rawValue: String
        
        init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    private static let json: (encoder: JSONEncoder, decoder: JSONDecoder) = (JSONEncoder(), JSONDecoder())
    static let directoryURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.confirmed")!.appendingPathComponent("AppGroupStorage", isDirectory: true)
    
    static let shared = AppGroupStorage()
    
    init() {
        AppGroupStorage.createDirectoryIfNeeded(at: AppGroupStorage.directoryURL)
    }
    
    func read<Content>(key: Key<Content>) -> Content? {
        do {
            let url = self.url(forKey: key)
            let data = try Data(contentsOf: url)
            let content = try AppGroupStorage.json.decoder.decode(Content.self, from: data)
            return content
        } catch {
            DDLogError(error)
            return nil
        }
    }
    
    func write<Content>(content: Content, key: Key<Content>) {
        do {
            let url = self.url(forKey: key)
            let data = try AppGroupStorage.json.encoder.encode(content)
            try data.write(to: url, options: [.atomic, .noFileProtection])
        } catch {
            DDLogError(error)
            return
        }
    }
    
    func delete<Content>(forKey key: Key<Content>) {
        let url = self.url(forKey: key)
        let fileManager = FileManager()
        do {
            try fileManager.removeItem(at: url)
        } catch {
            DDLogError(error)
        }
    }
    
    func url<Content>(forKey key: Key<Content>) -> URL {
        return AppGroupStorage.directoryURL.appendingPathComponent(key.rawValue)
    }
}

extension AppGroupStorage {
    static func createDirectoryIfNeeded(at url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            DDLogInfo("AppGroupStorage Directory exists: \(url.path)")
            return
        } else {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                DDLogInfo("AppGroupStorage Directory created: \(url.path)")
            } catch {
                DDLogError(error)
            }
        }
    }
}
#endif
