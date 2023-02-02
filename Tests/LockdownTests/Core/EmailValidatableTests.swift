//
//  EmailValidatableTests.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/7/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import XCTest
@testable import Lockdown

final class EmailValidatableTests: XCTestCase, EmailValidatable {
    
    func testKnownValidEmail() throws {
        // Base line test with known working email address
        let validEmailError = errorValidatingEmail("example-user@example.com")
        XCTAssertNil(validEmailError)
    }
    
    func testEmptyTextField() throws {
        let emptyEmailError = try XCTUnwrap(errorValidatingEmail(""))
        XCTAssertEqual(emptyEmailError.localizedDescription, EmailValidationError.notFilledIn.localizedDescription)
    }
    
    func testWhiteSpaceTextField() throws {
        let whiteSpaceEmailError = try XCTUnwrap(errorValidatingEmail("     "))
        XCTAssertEqual(whiteSpaceEmailError.localizedDescription, EmailValidationError.noValidEmailAddressDetected.localizedDescription)
    }
    
    func testCharactersNoEmail() throws {
        let noEmailError = try XCTUnwrap(errorValidatingEmail("sfjowejfiojaojfoajfojweofj"))
        XCTAssertEqual(noEmailError.localizedDescription, EmailValidationError.noValidEmailAddressDetected.localizedDescription)
    }
    
    func testCheckForCon() throws {
        let endingWithConError = try XCTUnwrap(errorValidatingEmail("email@email.con"))
        XCTAssertEqual(endingWithConError.localizedDescription, EmailValidationError.enteredConInsteadOfCom.localizedDescription)
    }
    
    func testCheckForCaseAndCon() throws {
        let endingWithCaseAndConError = try XCTUnwrap(errorValidatingEmail("email@EMAIL.CON"))
        XCTAssertEqual(endingWithCaseAndConError.localizedDescription, EmailValidationError.enteredConInsteadOfCom.localizedDescription)
    }
    
    func testMultipleEmails() throws {
        let multipleEmailsError = try XCTUnwrap(errorValidatingEmail("email@email.com emailtest@email.com"))
        XCTAssertEqual(multipleEmailsError.localizedDescription, EmailValidationError.tooManyEmailAddressesEntered.localizedDescription)
    }
    
    // The link that is found contains an email address (mailto: link)
    func testOtherURLTypes() throws {
        let webUrlError = try XCTUnwrap(errorValidatingEmail("https://www.example.com"))
        XCTAssertEqual(webUrlError.localizedDescription, EmailValidationError.noValidEmailAddressDetected.localizedDescription)
        
        let phoneNumberError = try XCTUnwrap(errorValidatingEmail("+1(555)555-5555"))
        XCTAssertEqual(phoneNumberError.localizedDescription, EmailValidationError.noValidEmailAddressDetected.localizedDescription)
    }
    
    func testUkrainianEmail() throws {
        let emailUkrainian = errorValidatingEmail("квіточка@пошта.укр")
        XCTAssertNil(emailUkrainian)
    }
    
    func testGermanEmail() throws {
        let emailGerman = errorValidatingEmail("Dörte@example.de")
        let emailGermanSubDomain = errorValidatingEmail("Dörte@Sörensen.example.com")
        XCTAssertNil(emailGerman)
        XCTAssertNil(emailGermanSubDomain)
    }
    
    func testRussianEmail() throws {
        let emailRussian = errorValidatingEmail("коля@пример.рф")
        let emailRussianSubDomain = errorValidatingEmail("иван.сергеев@пример.рф")
        XCTAssertNil(emailRussian)
        XCTAssertNil(emailRussianSubDomain)
    }
    
    func testKatanaEmail() throws {
        let emailKatana = errorValidatingEmail("support@ツッ.com")
        XCTAssertNil(emailKatana)
    }
    
    func testEmojiEmail() throws {
        let emailEmojiError = try XCTUnwrap(errorValidatingEmail("🙈@📧.com"))
        XCTAssertEqual(emailEmojiError.localizedDescription, EmailValidationError.noValidEmailAddressDetected.localizedDescription)
    }
    
    // This type of error gets caught on the server side
    func testLongEmail() throws {
        let longEmail = errorValidatingEmail("email@email.comeemail@email.com")
        XCTAssertNil(longEmail)
    }
}
