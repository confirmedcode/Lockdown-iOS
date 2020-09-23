//
//  TrackerInfoTests.swift
//  LockdownTests
//
//  Created by Oleg Dreyman on 03.06.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import XCTest
@testable import Lockdown

class TrackerInfoTests: XCTestCase {
    
    private func loadFile() throws -> TrackerInfo {
        guard let url = Bundle.main.url(forResource: "tracker_info", withExtension: "json") else {
            throw "Test: no file on disk"
        }
        
        let content = try Data(contentsOf: url)
        let info = try JSONDecoder().decode(TrackerInfo.self, from: content)
        return info
    }

    func testTrackerInfoJSONFileValid() throws {
        let info = try loadFile()
        print(info)
    }
    
    func testTrackerInfoValidateContents() throws {
        let info = try loadFile()
        
        var process = ""
        process += "------- TRACKER-INFO.JSON VALIDATION START -------"
        process += "\n  - Validating trackerIds"
        for (domain, trackerId) in info.test_trackerIds {
            if info.test_descriptions.keys.contains(trackerId) {
                process += "\n ✅ Descriptions exists for tracker ID: \(trackerId) (domain: \(domain))"
            } else {
                process += "\n ❌ Description missing for tracker ID: \(trackerId) (domain: \(domain))"
                XCTFail("Description missing for tracker ID: \(trackerId) (domain: \(domain))")
            }
        }
        process += "\n\n  - Validating descriptions used"
        for descKey in info.test_descriptions.keys {
            let usedDomains = info.test_trackerIds.filter({ $0.value == descKey }).keys
            if usedDomains.isEmpty {
                process += "\n ❌ No domain defines tracker ID: \(descKey)"
                XCTFail("No domains with tracker ID: \(descKey)")
            } else {
                process += "\n ✅ Domains for tracker ID \"\(descKey)\" are: \(usedDomains.joined(separator: ", "))"
            }
        }
        process += "\n-------- TRACKER-INFO.JSON VALIDATION END --------"
        print(process)
    }
    
}
