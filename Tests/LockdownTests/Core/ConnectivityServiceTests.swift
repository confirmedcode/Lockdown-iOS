//
//  ConnectivityServiceTests.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/7/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import XCTest
@testable import Lockdown

final class ConnectivityServiceTests: XCTestCase {
    
    func testUnknownState() {
        testConnectivity(state: .unknown, hasMessage: .defaultSwiftMessagesLabelText)
    }
    
    func testSatisfiedState() {
        testConnectivity(state: .satisfied, hasMessage: .defaultSwiftMessagesLabelText)
    }
    
    func testRestrictedCellularState() {
        testConnectivity(state: .restrictedCellular, hasMessage: "Enable Cellular Data for Lockdown")
    }
    
    func testNoConnectionState() {
        testConnectivity(state: .noConnection, hasMessage: .localized("No Internet Connection"))
    }
    
    private func testConnectivity(state: ConnectionState, hasMessage message: String) {
        // Given
        let connectivityService = ConnectivityService(connectionState: state)
        
        // When
        connectivityService.showConnectionErrorIfNeeded()
        
        let expectation = expectation(description: "ConnectivityService uses main.async, so we test it there")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
        
        // Then
        XCTAssertEqual(connectivityService.noInternetMessageView.bodyLabel?.text, message)
    }
}

private extension String {
    static let defaultSwiftMessagesLabelText = "[Message Body]"
}
