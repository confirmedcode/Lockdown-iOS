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

struct SignIn: Codable {
    let code: Int
    let message: String
}

struct ApiError: Codable, Error {
    let code: Int
    let message: String
}
