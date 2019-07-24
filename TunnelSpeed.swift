//
//  TunnelSpeed.swift
//  TunnelsiOS
//
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//
//  Original: https://github.com/rldaulton/connectedness

import Foundation
import SystemConfiguration
import CoreTelephony
import Reachability
import Alamofire
import CocoaLumberjack

public class TunnelSpeed: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    
    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!
    var speedTestCompletionHandler: ((_ megabytesPerSecond: Double, _ error: Error?) -> ())!
    
    var fileName = "10MB.bin"
    
    func configureDownloadFileSize() -> Void {
        if let r = Global.reachability {
            if r.connection == .wifi {
                fileName = "50MB.bin"
            }
            else {
                fileName = "10MB.bin"
            }
        }
        
    }
    
    public func testDownloadSpeedWithTimout(timeout: TimeInterval, completionHandler:@escaping (_ megabytesPerSecond: Double, _ error: Error?) -> ()) {
        
        let sessionManager = Alamofire.SessionManager.default
        sessionManager.retrier = nil
        sessionManager.request(Global.getSpeedTestBucket, method: .get).responseJSON { response in
            switch response.result {
            case .success:
                if let json = response.result.value as? [String: Any], let speedBucket = json["bucket"] as? String {
                    print(speedBucket)
                    self.configureDownloadFileSize()
                    let url = NSURL(string: "https://\(speedBucket).s3-accelerate.amazonaws.com/\(self.fileName)")!
                    
                    self.startTime = CFAbsoluteTimeGetCurrent()
                    self.stopTime = self.startTime
                    self.bytesReceived = 0
                    self.speedTestCompletionHandler = completionHandler
                    
                    let configuration = URLSessionConfiguration.ephemeral
                    configuration.timeoutIntervalForResource = timeout
                    
                    let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
                    session.dataTask(with: url as URL).resume()
                }
                else {
                    self.speedTestCompletionHandler(0.0, NSError.init(domain: "SpeedTest", code: 1, userInfo: nil))
                }
            case .failure(let error):
                //DDLogError("Error getting bucket \(error)")
                self.speedTestCompletionHandler(0.0, error)
                return
            }
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data){
        bytesReceived! += data.count
        stopTime = CFAbsoluteTimeGetCurrent()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let elapsed = stopTime - startTime
        let speed = elapsed != 0 ? Double(bytesReceived) / elapsed / 1024.0 / 1024.0 * 8 : -1
        speedTestCompletionHandler(speed, error)
        
    }
    
    
}
