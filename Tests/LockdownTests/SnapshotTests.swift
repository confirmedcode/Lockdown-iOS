//
//  SnapshotTests.swift
//  LockdownTests
//
//  Created by Oleg Dreyman on 27.05.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import XCTest
@testable import SnapshotTesting
@testable import Lockdown

// SIMULATOR: iPhone SE, 1st Generation
// OS: iOS 13.3

class SnapshotTests: XCTestCase {
    
    func testEmailSignupVC() {
        let emailSignUpVC = make(EmailSignUpViewController.self, storyboardIdentifier: "emailSignUpViewController")
        lockdownSnapshotTest(emailSignUpVC)
    }
    
    func testEmailSignInVC() {
        let emailSignInVC = make(EmailSignInViewController.self, storyboardIdentifier: "emailSignInViewController")
        lockdownSnapshotTest(emailSignInVC)
    }
    
    func testWhatIsVpnVC() {
        // We are not using `lockdownSnapshotTest` here because WhatIsVpnViewController
        // has changing logic based on raw screen size, and by defaults that's not something
        // that snapshot testing library is designed to test. So we're "emulating" that
        // two different modes (iPhone SE and not iPhone SE) by toggling `is4InchIphone`
        // on and off.
        
        do {
            let whatIsVpnVC = make(WhatIsVpnViewController.self, storyboardIdentifier: "whatIsVpnViewController")
            whatIsVpnVC.is4InchIphone = true
            assertSnapshot(matching: whatIsVpnVC, as: .image(on: .iPhoneSe, userInterfaceStyle: .light))
        }
        
        do {
            let whatIsVpnVC = make(WhatIsVpnViewController.self, storyboardIdentifier: "whatIsVpnViewController")
            whatIsVpnVC.is4InchIphone = false
            assertSnapshot(matching: whatIsVpnVC, as: .image(on: .iPhone8, userInterfaceStyle: .light))
        }
        
        do {
            let whatIsVpnVC = make(WhatIsVpnViewController.self, storyboardIdentifier: "whatIsVpnViewController")
            whatIsVpnVC.is4InchIphone = false
            assertSnapshot(matching: whatIsVpnVC, as: .image(on: .iPhoneXsMax, userInterfaceStyle: .light))
        }
        
        do {
            let whatIsVpnVC = make(WhatIsVpnViewController.self, storyboardIdentifier: "whatIsVpnViewController")
            whatIsVpnVC.is4InchIphone = true
            assertSnapshot(matching: whatIsVpnVC, as: .image(on: .iPhoneSe, userInterfaceStyle: .dark))
        }
        
        do {
            let whatIsVpnVC = make(WhatIsVpnViewController.self, storyboardIdentifier: "whatIsVpnViewController")
            whatIsVpnVC.is4InchIphone = false
            assertSnapshot(matching: whatIsVpnVC, as: .image(on: .iPhone8, userInterfaceStyle: .dark))
        }
        
        do {
            let whatIsVpnVC = make(WhatIsVpnViewController.self, storyboardIdentifier: "whatIsVpnViewController")
            whatIsVpnVC.is4InchIphone = false
            assertSnapshot(matching: whatIsVpnVC, as: .image(on: .iPhoneXsMax, userInterfaceStyle: .dark))
        }

    }
    
    func testHomeVC() {
        let homeVC = make(HomeViewController.self, storyboardIdentifier: "homeViewController")
        lockdownHighQualitySnapshotTest(homeVC)
    }
    
    func testFirewallPrivacyPolicyVC() {
        let privacyPolicyVC = make(PrivacyPolicyViewController.self, storyboardIdentifier: "firewallPrivacyPolicyViewController")
        privacyPolicyVC.parentVC = nil
        privacyPolicyVC.privacyPolicyKey = kHasAgreedToFirewallPrivacyPolicy
        lockdownSnapshotTest(privacyPolicyVC)
    }
    
    func testTitleVC() {
        let titleVC = make(TitleViewController.self, storyboardIdentifier: "titleViewController")
        titleVC.isAnimatingOnAppear = false
        lockdownSnapshotTest(titleVC)
    }
    
    func testLogVC() {
        BlockDayLog.shared.clear()
        
        let date = Calendar.current.date(bySettingHour: 9, minute: 41, second: 10, of: Date())!
        
        BlockDayLog.shared.append(host: "snapshot-test.com", date: date)
        BlockDayLog.shared.append(host: "lockdown-test.com", date: date)
        let logVC = make(BlockLogViewController.self, storyboardIdentifier: "blockLogViewController")
        lockdownSnapshotTest(logVC)
        BlockDayLog.shared.clear()
    }
}

extension SnapshotTests {
    private func make<ViewController: UIViewController>(_ vc: ViewController.Type, storyboardIdentifier: String) -> ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as! ViewController
        return viewController
    }
    
    private func lockdownHighQualitySnapshotTest(
        _ viewController: UIViewController,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        
        guard UIDevice.is4InchIphone else {
            XCTFail("These snapshot tests are designed to run on iPhone SE 1st Gen, iOS 13.3 simulator", file: file, line: line)
            return
        }

        assertSnapshot(matching: viewController, as: .keyWindowImage(on: .iPhoneSe, userInterfaceStyle: .light), record: record, file: file, testName: testName, line: line)
        assertSnapshot(matching: viewController, as: .keyWindowImage(on: .iPhone8, userInterfaceStyle: .light), record: record, file: file, testName: testName, line: line)
        assertSnapshot(matching: viewController, as: .keyWindowImage(on: .iPhoneXsMax, userInterfaceStyle: .light), record: record, file: file, testName: testName, line: line)
        
        assertSnapshot(matching: viewController, as: .keyWindowImage(on: .iPhoneSe, userInterfaceStyle: .dark), record: record, file: file, testName: testName, line: line)
        assertSnapshot(matching: viewController, as: .keyWindowImage(on: .iPhone8, userInterfaceStyle: .dark), record: record, file: file, testName: testName, line: line)
        assertSnapshot(matching: viewController, as: .keyWindowImage(on: .iPhoneXsMax, userInterfaceStyle: .dark), record: record, file: file, testName: testName, line: line)
    }
    
    private func lockdownSnapshotTest(
        _ viewController: UIViewController,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        
        guard UIDevice.is4InchIphone else {
            XCTFail("These snapshot tests are designed to run on iPhone SE 1st Gen, iOS 13.3 simulator", file: file, line: line)
            return
        }
        
        assertSnapshot(matching: viewController, as: .image(on: .iPhoneSe, userInterfaceStyle: .light), record: record, file: file, testName: testName, line: line)
        assertSnapshot(matching: viewController, as: .image(on: .iPhone8, userInterfaceStyle: .light), record: record, file: file, testName: testName, line: line)
        assertSnapshot(matching: viewController, as: .image(on: .iPhoneXsMax, userInterfaceStyle: .light), record: record, file: file, testName: testName, line: line)
        
        assertSnapshot(matching: viewController, as: .image(on: .iPhoneSe, userInterfaceStyle: .dark), record: record, file: file, testName: testName, line: line)
        assertSnapshot(matching: viewController, as: .image(on: .iPhone8, userInterfaceStyle: .dark), record: record, file: file, testName: testName, line: line)
        assertSnapshot(matching: viewController, as: .image(on: .iPhoneXsMax, userInterfaceStyle: .dark), record: record, file: file, testName: testName, line: line)
    }
}

extension Snapshotting where Value == UIViewController, Format == UIImage {
    static func image(on device: ViewImageConfig, userInterfaceStyle: UIUserInterfaceStyle) -> Snapshotting {
        return image(on: device, traits: .init(userInterfaceStyle: userInterfaceStyle))
    }
    
    static func keyWindowImage(on device: ViewImageConfig, userInterfaceStyle: UIUserInterfaceStyle) -> Snapshotting {
        let traits = UITraitCollection(traitsFrom: [device.traits, .init(userInterfaceStyle: userInterfaceStyle)])
        
        return image(drawHierarchyInKeyWindow: true, precision: 0.995, size: device.size, traits: traits)
    }
}
