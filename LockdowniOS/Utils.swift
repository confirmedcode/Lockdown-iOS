//
//  Utils.swift
//  ConfirmediOS
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import Foundation
import NetworkExtension
import CocoaLumberjackSwift
import Alamofire


@IBDesignable
open class ConfirmedLabel : UILabel {
    
    var adjustediPhone5SFontSize : CGFloat = 12.0
    var adjustediPhone8FontSize : CGFloat = 16.0
    
    @IBInspectable open var iPhone5SFontSize: CGFloat = 12.0 {
        didSet {
            adjustediPhone5SFontSize = iPhone5SFontSize
            adjustFontToIPhone()
        }
    }
    
    @IBInspectable open var iPhone8FontSize: CGFloat = 16.0 {
        didSet {
            adjustediPhone8FontSize = iPhone8FontSize
            adjustFontToIPhone()
        }
    }
    
    func adjustFontToIPhone() {
        guard let font  = self.font else {
            return
        }
        
        if UIDevice().userInterfaceIdiom == .phone {
            if UIScreen.main.nativeBounds.height <= 1136 {
                let oldFontName = font.fontName
                self.font = UIFont(name: oldFontName, size: adjustediPhone5SFontSize)
            }
            else if UIScreen.main.nativeBounds.height <= 1334 {
                let oldFontName = font.fontName
                self.font = UIFont(name: oldFontName, size: adjustediPhone8FontSize)
            }
        }
        
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        adjustFontToIPhone()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        adjustFontToIPhone()
    }
}

extension Alamofire.SessionManager{
    @discardableResult
    open func requestWithoutCache(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)// also you can add URLRequest.CachePolicy here as parameter
        -> DataRequest
    {
        do {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            urlRequest.cachePolicy = .reloadIgnoringCacheData // <<== Cache disabled
            let encodedURLRequest = try encoding.encode(urlRequest, with: parameters)
            return request(encodedURLRequest)
        } catch {
            // TODO: find a better way to handle error
            print(error)
            return request(URLRequest(url: URL(string: "http://example.com/wrong_request")!))
        }
    }
}

extension UnicodeScalar {
    var hexNibble:UInt8 {
        let value = self.value
        if 48 <= value && value <= 57 {
            return UInt8(value - 48)
        }
        else if 65 <= value && value <= 70 {
            return UInt8(value - 55)
        }
        else if 97 <= value && value <= 102 {
            return UInt8(value - 87)
        }
        fatalError("\(self) not a legal hex nibble")
    }
}

extension Data {
    init(hex:String) {
        let scalars = hex.unicodeScalars
        var bytes = Array<UInt8>(repeating: 0, count: (scalars.count + 1) >> 1)
        for (index, scalar) in scalars.enumerated() {
            var nibble = scalar.hexNibble
            if index & 1 == 0 {
                nibble <<= 4
            }
            bytes[index >> 1] |= nibble
        }
        self = Data(bytes: bytes)
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

enum AppConfiguration {
    case Debug
    case TestFlight
    case AppStore
}

struct Config {
    // This is private because the use of 'appConfiguration' is preferred.
    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    
    // This can be used to add debug statements.
    static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    static var appConfiguration: AppConfiguration {
        if isDebug {
            return .Debug
        } else if isTestFlight {
            return .TestFlight
        } else {
            return .AppStore
        }
    }
}


class Utils: SharedUtils {
    
}
