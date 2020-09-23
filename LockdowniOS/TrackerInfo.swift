//
//  TrackerInfo.swift
//  Lockdown
//
//  Created by Oleg Dreyman on 02.06.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift

struct TrackerInfo: Decodable {
    private var trackerIds: [String : String]
    private var descriptions: [String : TrackerDescription]
    
    func description(forDomain domain: String) -> TrackerDescription? {
        if let trackerId = trackerIds[domain] {
            return descriptions[trackerId]
        } else {
            if let topDomain = trackerIds.first(where: { key, _ in domain.hasSuffix(key) }) {
                return descriptions[topDomain.value]
            }
        }
        return nil
    }
}

struct TrackerDescription: Decodable {
    var title: String
    var description: String    
}

final class TrackerInfoRegistry {
    
    static let shared = TrackerInfoRegistry()
    
    private var loaded: TrackerInfo?
    
    func info(forTrackerDomain domain: String) -> TrackerDescription {
        do {
            if let value = try getTrackerInfoDoc().description(forDomain: domain) {
                return value
            } else {
                return inferInfo(forTrackerDomain: domain)
            }
        } catch {
            DDLogError(error.localizedDescription)
            return inferInfo(forTrackerDomain: domain)
        }
    }
    
    private func inferInfo(forTrackerDomain domain: String) -> TrackerDescription {
        
        let userBlocked = getUserBlockedDomains()
        if userBlocked.keys.contains(domain) {
            return TrackerDescription(title: domain, description: "You blocked this domain in your custom blocked domains.")
        } else if let match = userBlocked.keys.first(where: { domain.hasSuffix($0) }) {
            return TrackerDescription(title: domain, description: "You blocked \(match) in your custom blocked domains.")
        }
        
        let blocked = getLockdownBlockedDomains().lockdownDefaults
        
        let groups = blocked.values
            .filter { $0.domains.keys.contains(where: { domain.hasSuffix($0) }) }
            .map { $0.name }
            .sorted()
        
        let groupsFormatted = TrackerInfoRegistry.formatList(strings: groups)
        
        if !groups.isEmpty {
            return TrackerDescription(title: domain, description: "\(domain) is a part of \(groupsFormatted) block \(groups.count == 1 ? "list" : "lists")")
        }
        
        return TrackerDescription(title: "No Info Found", description: "No additional information on this blocked domain found.")
    }
    
    static private func formatList(strings: [String]) -> String {
        var strings = strings
            .map { "\"\($0)\"" }
        
        guard strings.count > 1 else {
            return strings.first ?? ""
        }
        
        let last = strings.removeLast()
        return strings
            .joined(separator: ", ") + " and " + last
    }
    
    private func getTrackerInfoDoc() throws -> TrackerInfo {
        if let loaded = loaded {
            return loaded
        } else {
            let fromDisk = try loadFromDisk()
            self.loaded = fromDisk
            return fromDisk
        }
    }
    
    enum Error: Swift.Error {
        case noFileOnDisk
    }
    
    private func loadFromDisk() throws -> TrackerInfo {
        guard let url = Bundle.main.url(forResource: "tracker_info", withExtension: "json") else {
            throw Error.noFileOnDisk
        }
        
        do {
            let content = try Data(contentsOf: url)
            let info = try JSONDecoder().decode(TrackerInfo.self, from: content)
            return info
        } catch {
            throw error
        }
    }
    
}

extension TrackerInfo {
    #if DEBUG
    // this is used for tracker-info.json validation; see TrackerInfoTests.swift
    var test_trackerIds: [String: String] {
        return trackerIds
    }
    
    var test_descriptions: [String: TrackerDescription] {
        return descriptions
    }
    #endif
}
