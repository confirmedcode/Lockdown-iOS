//
//  SpeedTest.swift
//  Lockdown
//
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//
//  Original: https://github.com/rldaulton/connectedness

import Foundation
import SystemConfiguration
import CoreTelephony
import Reachability
import CocoaLumberjackSwift
import PromiseKit

public class SpeedTest: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    
    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!
    
    var fileName = "10MB.bin"
    var fileSizeBytes:Double = 10485760
    
    public func testDownloadSpeedWithTimeout(timeout: TimeInterval) -> Promise<Double> {
        if let r = reachability, r.connection == .wifi {
            fileName = "50MB.bin"
            fileSizeBytes = 52428800
        } else {
            fileName = "10MB.bin"
            fileSizeBytes = 10485760
        }
        
        return firstly {
            Client.getSpeedTestBucket()
        }
        .then { speedTestBucket -> Promise<(data: Data, response: URLResponse)> in
            DDLogInfo("Bucket \(speedTestBucket.bucket)")
            self.startTime = CFAbsoluteTimeGetCurrent()
            self.stopTime = self.startTime
            self.bytesReceived = 0
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForResource = timeout
            let session = URLSession(configuration: configuration)
            return session.dataTask(.promise,
                                 with: try self.makeDownloadRequest(urlString: "https://\(speedTestBucket.bucket).s3-accelerate.amazonaws.com/\(self.fileName)"))
                    .validate()
        }
        .map { data, response -> Double in
            self.stopTime = CFAbsoluteTimeGetCurrent()
            let elapsed = self.stopTime - self.startTime
            if elapsed == 0 {
                throw "File download failed: no time elapsed."
            }
            else {
                return self.fileSizeBytes / elapsed / 1024.0 / 1024.0
            }
        }
    }
    
    func makeDownloadRequest(urlString: String) throws -> URLRequest {
        if let url = URL(string: urlString) {
            var rq = URLRequest(url: url)
            rq.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            rq.httpMethod = "GET"
            return rq
        }
        else {
            throw "Invalid URL string: \(urlString)"
        }
    }
    
}
