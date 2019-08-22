//
//  Client.swift
//  Lockdown
//
//  Created by Johnny Lin on 7/31/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftyStoreKit
import CocoaLumberjackSwift

let kApiCodeNoError = 0
let kApiCodeEmailNotConfirmed = 1
let kApiCodeIncorrectLogin = 2
let kApiCodeRequestFieldValidationError = 3
let kApiCodeNoActiveSubscription = 6
let kApiCodeNoSubscriptionInReceipt = 9
let kApiCodeMobileSubscriptionOnly = 38
let kApiCodeEmailAlreadyUsed = 40
let kApiCodeReceiptAlreadyUsed = 48
let kApiCodeInvalidAuth = 401
let kApiCodeTooManyRequests = 999
let kApiCodeUnknownError = 99999

class Client {

    // MARK: - CLIENT CALLS
    
    static func signIn(forceRefresh: Bool = false) throws -> Promise<SignIn> {
        DDLogInfo("API CALL: signIn")
        URLCache.shared.removeAllCachedResponses()
        clearCookies()
        return getReceipt(forceRefresh: forceRefresh)
            .then { receipt -> Promise<(data: Data, response: URLResponse)> in
                let parameters = [
                    "authtype": "ios",
                    "authreceipt": receipt
                ]
                return URLSession.shared.dataTask(.promise,
                                           with: try makePostRequest(urlString: mainURL + "/signin",
                                            parameters: parameters))
            }
            .map { data, response -> SignIn in
                try self.validateApiResponse(data: data, response: response)
                let resp = response as! HTTPURLResponse // already validated the type in validateApiResponse
                DDLogInfo("Got signin response with headers: \(resp.allHeaderFields)")
                if (hasValidCookie()) {
                    return try JSONDecoder().decode(SignIn.self, from: data)
                }
                else {
                    throw "No valid cookie received and/or set when trying to sign in"
                }
            }
    }

    static func getKey() throws -> Promise<GetKey> {
        DDLogInfo("API CALL: getKey")
        return firstly { () -> Promise<(data: Data, response: URLResponse)> in
                let parameters = [
                    "platform" : "ios"
                ]
                return URLSession.shared.dataTask(.promise, with: try makePostRequest(urlString: mainURL + "/get-key", parameters: parameters))
            }
            .map { data, response -> GetKey in
                try self.validateApiResponse(data: data, response: response)
                let getKey = try JSONDecoder().decode(GetKey.self, from: data)
                DDLogInfo("API RESULT: getKey: \(getKey)")
                return getKey
        }
    }
    
    static func getSpeedTestBucket() -> Promise<SpeedTestBucket> {
        DDLogInfo("API CALL: download speed test")
        return firstly {
            URLSession.shared.dataTask(.promise, with: try makeGetRequest(urlString: "\(mainURL)/download-speed-test"))
            }
            .map { data, response -> SpeedTestBucket in
                try self.validateApiResponse(data: data, response: response)
                let speedTestBucket = try JSONDecoder().decode(SpeedTestBucket.self, from: data)
                DDLogInfo("API RESULT: speedTestBucket: \(speedTestBucket)")
                return speedTestBucket
        }
    }
    
    static func getIP() -> Promise<IP> {
        DDLogInfo("API CALL: ip")
        URLCache.shared.removeAllCachedResponses()
        return firstly {
            URLSession.shared.dataTask(.promise, with: try makeGetRequest(urlString: "https://ip.\(mainDomain)/ip"))
            }
            .map { data, response -> IP in
                try self.validateApiResponse(data: data, response: response)
                let ip = try JSONDecoder().decode(IP.self, from: data)
                DDLogInfo("API RESULT: ip: \(ip)")
                return ip
        }
    }
    
    static func getBlockedDomainTest(connectionSuccessHandler: @escaping () -> Void, connectionFailedHandler: @escaping (_ error: Error?) -> Void) -> PMKFinalizer {
        return firstly {
            URLSession.shared.dataTask(.promise, with: try Client.makeGetRequest(urlString: "https://\(testFirewallDomain)"))
        }
        .done { _ in
            connectionSuccessHandler()
        }
        .catch { error in
            connectionFailedHandler(error)
        }
    }
    
    // MARK: - Request Makers

    static func makeGetRequest(urlString: String) throws -> URLRequest {
        DDLogInfo("makeGetRequest: \(urlString)")
        if let url = URL(string: urlString) {
            var rq = URLRequest(url: url)
            rq.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            rq.httpMethod = "GET"
            rq.addValue("application/json", forHTTPHeaderField: "Accept")
            return rq
        }
        else {
            throw "Invalid URL string: \(urlString)"
        }
    }
    
    static func makePostRequest(urlString: String, parameters: [String: Any]) throws -> URLRequest {
        DDLogInfo("makePostRequest: \(urlString), parameters: \(parameters)")
        if let url = URL(string: urlString) {
            var rq = URLRequest(url: url)
            rq.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            rq.httpMethod = "POST"
            rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
            rq.addValue("application/json", forHTTPHeaderField: "Accept")
            rq.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            return rq
        }
        else {
            throw "Invalid URL string: \(urlString)"
        }
    }
    
    // MARK: - Util
    
    private static func getReceipt(forceRefresh: Bool) -> Promise<String> {
        DDLogInfo("fetch and set latest receipt")
        return Promise { seal in
            SwiftyStoreKit.fetchReceipt(forceRefresh: forceRefresh) { result in
                switch result {
                case .success(let receiptData):
                    let receipt = receiptData.base64EncodedString(options: [])
                    DDLogInfo("fetch latest receipt success base64: \(receipt)")
                    seal.fulfill(receipt);
                case .error(let error):
                    DDLogError("fetch latest receipt failure: \(error)")
                    do {
                        switch error {
                        case ReceiptError.noReceiptData:
                            throw "Error refreshing purchases with App Store: No Receipt Data"
                        case ReceiptError.networkError(let networkError):
                            throw "Error refreshing purchases with App Store: Network Error - \(networkError.localizedDescription)"
                        case ReceiptError.noRemoteData:
                            throw "Error refreshing purchases with App Store: No Remote Data"
                        case ReceiptError.receiptInvalid(_, let receiptStatus):
                            throw "Error refreshing purchases with App Store: Invalid Receipt - \(receiptStatus)"
                        case ReceiptError.requestBodyEncodeError(let error):
                            throw "Error refreshing purchases with App Store: Encoding Error - \(error.localizedDescription)"
                        case ReceiptError.jsonDecodeError(_):
                            throw "Error refreshing purchases with App Store: JSON Decode Error"
                        }
                    }
                    catch {
                        seal.reject(error)
                    }
                }
            }
        }
    }
    
    static func hasValidCookie() -> Bool {
        DDLogInfo("checking for valid cookie")
        var hasValidCookie = false
        if let cookies = HTTPCookieStorage.shared.cookies {
            DDLogInfo("found cookies")
            for cookie in cookies {
                DDLogInfo("cookie: \(cookie)")
                if let timeUntilExpire = cookie.expiresDate?.timeIntervalSinceNow {
                    DDLogInfo("time until expire: \(timeUntilExpire)")
                    if cookie.domain.contains(mainDomain) && timeUntilExpire > 120.0 {
                        DDLogInfo("cookie contains mainDomain and timeuntilexpires > 120")
                        hasValidCookie = true
                    }
                }
            }
        }
        return hasValidCookie
    }
    
    private static func clearCookies() {
        DDLogInfo("clearing cookies")
        var cookiesToDelete:[HTTPCookie] = []
        if let cookies = HTTPCookieStorage.shared.cookies {
            DDLogInfo("found cookies")
            for cookie in cookies {
                DDLogInfo("cookie to delete: \(cookie)")
                cookiesToDelete.append(cookie)
            }
        }
        for cookie in cookiesToDelete {
            DDLogInfo("deleting cookie: \(cookie)")
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
    
    private static func validateApiResponse(data: Data, response: URLResponse) throws {
        DDLogInfo("validating API response")
        let dataString = String(data: data, encoding: String.Encoding.utf8)
        DDLogInfo("RAW RESULT: \(String(describing: dataString))")
        if let resp = response as? HTTPURLResponse {
            DDLogInfo("response is HTTPURLResponse: \(resp)")
            // see if there's a non-zero code returned
            if let apiError = try? JSONDecoder().decode(ApiError.self, from: data) {
                if apiError.code == kApiCodeNoError {
                    DDLogError("zero (non-error) API code received, validated OK: \(apiError)")
                    return;
                }
                else {
                    DDLogError("nonzero API code received, throwing: \(apiError)")
                    throw apiError;
                }
            }
            // some 4xx/5xx error
            else if (resp.statusCode >= 400 || resp.statusCode <= 0) {
                DDLogError("response has bad status code \(resp.statusCode)")
                throw "response has bad status code \(resp.statusCode)"
            }
            else {
                DDLogInfo("response has good status code (2xx, 3xx) and no error code")
            }
        }
        else {
            throw "Invalid URL Response received"
        }
    }
    
}
