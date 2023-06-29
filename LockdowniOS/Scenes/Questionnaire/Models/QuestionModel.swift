//
//  QuestionModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 28.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import Foundation

struct QuestionModel {
    var isFirewallOn: Bool?
    var isVPNOn: Bool?
    var vpnRegion: Country?
    var fromCountry: Country?
    var isHappeningWifiIssue: Bool?
    var isHappenningCellularIssue: Bool?
    var haveOtherFirewall: Bool?
    var haveOtherVPN: Bool?
    
    func generateMessage(
        firewallInput: String?,
        vpnInput: String?,
        otherDetailsInput: String?
    ) -> String? {
        var result = ""
        result.append(
            stringForQuestion(
                NSLocalizedString("1. Is the firewall on?", comment: ""),
                answer: isFirewallOn,
                input: firewallInput
            )
        )
        result.append(
            stringForQuestion(
                NSLocalizedString("2-1. Is the VPN on?", comment: ""),
                answer: isVPNOn,
                input: vpnInput
            )
        )
        result.append(
            stringForCountry(
                vpnRegion,
                title: NSLocalizedString("2-2. If the VPN is on, which region is it set to?", comment: "")
            )
        )
        result.append(
            stringForCountry(
                fromCountry,
                title: NSLocalizedString("3. Where are you contacting us from?", comment: "")
            )
        )
        result.append(
            stringForQuestion(
                NSLocalizedString("4. Is the issue happening on WiFi?", comment: ""),
                answer: isHappeningWifiIssue,
                input: nil
            )
        )
        result.append(
            stringForQuestion(
                NSLocalizedString("5. Is the issue happening on cellular data?", comment: ""),
                answer: isHappenningCellularIssue,
                input: nil
            )
        )
        result.append(
            stringForQuestion(
                NSLocalizedString("6. Do you have other firewall apps installed?", comment: ""),
                answer: haveOtherFirewall,
                input: nil
            )
        )
        result.append(
            stringForQuestion(
                NSLocalizedString("7. Do you have other VPN apps installed?", comment: ""),
                answer: haveOtherVPN,
                input: nil
            )
        )
        if let otherDetailsInput,
           !otherDetailsInput.isEmpty {
            result.append(otherDetailsInput)
        }
        
        guard !result.isEmpty else { return nil }
                
        return result
    }
    
    private func stringForQuestion(
        _ question: String,
        answer: Bool?,
        input: String?
    ) -> String {
        var result = ""
        if let answer {
            result.append(question)
            result.append(" " + stringFor(answer))
            if let input,
               !input.isEmpty {
                result.append("\n")
                result.append(input)
            }
            result.append("\n")
        }
        return result
    }
    
    private func stringForCountry(
        _ country: Country?,
        title: String
    ) -> String {
        var result = ""
        if let country {
            result.append(title)
            result.append(": " + country.title)
            result.append("\n")
        }
        return result
    }
    
    private func stringFor(_ boolValue: Bool) -> String {
        boolValue ? NSLocalizedString("Yes", comment: "") : NSLocalizedString("No", comment: "")
    }
}
