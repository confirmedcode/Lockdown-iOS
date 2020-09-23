//
//  DomainNameValidatorTests.swift
//  LockdownTests
//
//  Created by Oleg Dreyman on 19.05.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import XCTest
@testable import Lockdown

class DomainNameValidatorTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func isDomainNameValid(_ domainName: String) -> Bool {
        let result = DomainNameValidator.validate(domainName)
        print(domainName, result)
        switch result {
        case .valid:
            return true
        case .notValid:
            return false
        }
    }

    func testValidatesValidDomains() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let validDomainNames = [
            "google.com",
            "main.apple.uk",
            "fieo.fwjo.qqq",
            "8934jjaq.com",
            "jfie---328943.com",
            "g.com",
            "fb.ru",
            // this is punycode for "правительство.рф", existing cyrillic domain name
            "xn--80aealotwbjpid2k.xn--p1ai",
        ]
        
        for validDomain in validDomainNames {
            XCTAssertTrue(isDomainNameValid(validDomain))
        }
    }

    func testNotValidatesEmptyString() {
        XCTAssertFalse(isDomainNameValid(""))
        XCTAssertFalse(isDomainNameValid("."))
        XCTAssertFalse(isDomainNameValid(".."))
        XCTAssertFalse(isDomainNameValid("..."))
        XCTAssertFalse(isDomainNameValid(".a"))
        XCTAssertFalse(isDomainNameValid("a..a"))
        XCTAssertFalse(isDomainNameValid(".a"))
    }
    
    func testNotValidatesOneLabelString() {
        let invalidDomainNames = [
            "google",
            "apple",
            "iphone eleven",
            "80aealotwbjpid2k",
            "4242fwfw3",
            "lockdown app com",
        ]
        
        for invalidName in invalidDomainNames {
            XCTAssertFalse(isDomainNameValid(invalidName))
        }
    }
    
    func testNotValidatesWildcardString() {
        let invalidDomainNames = [
            "api.*.com",
            "*.",
            ".*",
            "**",
            "*cloud.com",
        ]
        
        for invalidName in invalidDomainNames {
            XCTAssertFalse(isDomainNameValid(invalidName))
        }
    }
    
    func testValidatesWildcardAsFirstLabel() {
        let validDomainNames = [
            "*.apple.com",
            "*.uk",
            "*.paris.fr",
        ]
        
        for validName in validDomainNames {
            XCTAssertTrue(isDomainNameValid(validName))
        }
    }

    func testNotValidatesHttpsString() {
        let invalidDomainNames = [
            "https://google.com",
            "https://apple.com",
            "http://facebook.uk",
            "https://xn--80aealotwbjpid2k.xn--p1ai",
            "ssh://main.fr",
        ]
        
        for invalidName in invalidDomainNames {
            XCTAssertFalse(isDomainNameValid(invalidName))
        }
    }
    
    func testNotValidatesInvalidCharacters() {
        // These are not officially supported by the URL system.
        // To use these, one need to convert them to punycode, for example:
        // "человек.рф" -> "xn--b1afbucs4d.xn--p1ai"
        let invalidDomainNames = [
            "человек.рф",
            "бассейн.уа",
            "méxico.com",
        ]
        
        for invalidName in invalidDomainNames {
            XCTAssertFalse(isDomainNameValid(invalidName))
        }
    }
}
