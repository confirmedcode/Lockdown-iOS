//
//  AppGroupStorage.swift
//  LockdowniOS
//
//  Created by Oleg Dreyman on 16.10.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift

enum ProtectedFileAccess {
    
    private static let fileURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.confirmed")!
        .appendingPathComponent("protection.check")
    
    static var isAvailable: Bool {
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    @available(iOS 10.0, *)
    static func createProtectionCheck() {
        if !isAvailable {
            let result = FileManager.default.createFile(
                atPath: fileURL.path,
                contents: "This file exists to check system file protection status".data(using: .utf8),
                attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
            if result {
                DDLogInfo("Created protection.check file")
            } else {
                DDLogError("Failed to create protection.check file")
            }
        } else {
            DDLogInfo("protection.check file already exists")
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
