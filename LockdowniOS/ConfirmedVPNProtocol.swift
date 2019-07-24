//
//  ConfirmedVPNProtocol.swift
//  ConfirmediOS
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import NetworkExtension

enum ServerRegion : String {
    case usWest = "us-west"
    case usEast = "us-east"
    case euLondon = "eu-london"
    case euIreland = "eu-ireland"
    case euFrankfurt = "eu-frankfurt"
    case canada = "canada"
    case tokyo = "ap-tokyo"
    case sydney = "ap-sydney"
    case seoul = "ap-seoul"
    case singapore = "ap-singapore"
    case mumbai = "ap-mumbai"
    case brazil = "sa"
}

var regionMetadata : Dictionary<ServerRegion, ServerMetadata> = [
    .usEast : ServerMetadata.init(countryName: "United States - East".localized(), flagImagePath: "usa_flag", countryCode: "us"),
    .usWest : ServerMetadata.init(countryName: "United States - West".localized(), flagImagePath: "usa_flag", countryCode: "us"),
    .euLondon : ServerMetadata.init(countryName: "United Kingdom".localized(), flagImagePath: "great_brittain", countryCode: "uk"),
    .euIreland : ServerMetadata.init(countryName: "Ireland".localized(), flagImagePath: "ireland_flag", countryCode: "irl"),
    .euFrankfurt : ServerMetadata.init(countryName: "Germany".localized(), flagImagePath: "germany_flag", countryCode: "de"),
    .canada : ServerMetadata.init(countryName: "Canada".localized(), flagImagePath: "canada_flag", countryCode: "ca"),
    .tokyo : ServerMetadata.init(countryName: "Japan".localized(), flagImagePath: "japan_flag", countryCode: "jp"),
    .sydney : ServerMetadata.init(countryName: "Australia".localized(), flagImagePath: "australia_flag", countryCode: "au"),
    .seoul : ServerMetadata.init(countryName: "South Korea".localized(), flagImagePath: "korea_flag", countryCode: "kr"),
    .singapore : ServerMetadata.init(countryName: "Singapore".localized(), flagImagePath: "singapore_flag", countryCode: "sg"),
    .mumbai : ServerMetadata.init(countryName: "India".localized(), flagImagePath: "india_flag", countryCode: "in"),
    .brazil : ServerMetadata.init(countryName: "Brazil".localized(), flagImagePath: "brazil_flag", countryCode: "br"),
]


protocol ConfirmedVPNProtocol {
    var supportedRegions : Array<ServerRegion> { get }
    static var protocolName : String { get }
    
    
    func endpointForRegion(region : ServerRegion) -> String
    func disableWhitelistingProxy(completion: @escaping (_ error: Error?) -> Void)
    func setupVPN(completion: @escaping (_ error: Error?) -> Void)
    func connectToVPN()
    func disconnectFromVPN()
    func getStatus(completion: @escaping (_ status: NEVPNStatus) -> Void) -> Void
}
