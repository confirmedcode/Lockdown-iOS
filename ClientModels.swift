//
//  Models.swift
//  Lockdown
//
//  Created by Johnny Lin on 7/31/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation

struct IP: Codable {
    let ip: String
}

struct SpeedTestBucket: Codable {
    let bucket: String
}

struct GetKey: Codable {
    let id: String
    let b64: String
}

struct SubscriptionEvent: Codable {
    let message: String
}

struct Subscription: Codable {
    let planType: PlanType
    let receiptId: String
    let expirationDate: Date
    let expirationDateString: String
    let expirationDateMs: Int
    let cancellationDate: Date?
    let cancellationDateString: String?
    let cancellationDateMs: Int?
    
    struct PlanType: RawRepresentable, RawValueCodable, Hashable {
        let rawValue: String
        init(rawValue: String) {
            self.rawValue = rawValue
        }
        static let advancedMonthly = PlanType(rawValue: "ios-fw-monthly")
        static let advancedAnnual = PlanType(rawValue: "ios-fw-annual")
        static let anonymousMonthly = PlanType(rawValue: "ios-monthly")
        static let anonymousAnnual = PlanType(rawValue: "ios-annual")
        static let universalMonthly = PlanType(rawValue: "all-monthly")
        static let universalAnnual = PlanType(rawValue: "all-annual")
    }
}

struct SignIn: Codable {
    let code: Int
    let message: String
}

struct Signup: Codable {
    let code: Int
    let message: String
}

struct ApiError: Codable, Error {
    let code: Int
    let message: String
}

// MARK: - Helpers

public enum RawValueCodableError: Error {
    case wrongRawValue
}

public protocol RawValueCodable: RawRepresentable, Codable {
}

public extension RawValueCodable where RawValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawValue.self)
        if let value = Self.init(rawValue: rawValue) {
            self = value
        } else {
            throw RawValueCodableError.wrongRawValue
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
