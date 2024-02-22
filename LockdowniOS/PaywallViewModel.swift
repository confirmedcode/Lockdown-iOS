//
//  PaywallViewModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 22.02.24.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import Foundation

struct PaywallViewModel {
    let title: String
    let subtitle: String
    let bulletPoints: [String]
    let mounthProductId: String
    let annualProductId: String
    
    static func empty() -> Self {
        .init(
            title: "",
            subtitle: "",
            bulletPoints: [],
            mounthProductId: "",
            annualProductId: ""
        )
    }
    
    static func advancedDetails() -> Self {
        .init(
            title: NSLocalizedString("Advanced Level Protection", comment:""),
            subtitle: NSLocalizedString("Used by 100,000+ Privacy-Conscious People", comment: ""),
            bulletPoints: [
                "Custom block lists",
                "Advanced malware & ads blocking",
                "Unlimited blocking",
                "App-specific block lists",
                "Advanced encryption protocols",
                "Import/Export block lists for more tailored protection"
            ],
            mounthProductId: VPNSubscription.productIdAdvancedMonthly,
            annualProductId: VPNSubscription.productIdAdvancedYearly
        )
    }
    
    static func anonymousDetails() -> Self {
        .init(
            title: NSLocalizedString("Secure Tunnel VPN + Advanced Firewall", comment:""),
            subtitle: NSLocalizedString("Private Browsing with Hidden IP and Global Region Switching", comment: ""),
            bulletPoints: [
                "Anonymized browsing",
                "Change your IP address to another region",
                "Maximum security with VPN and firewall",
                "Location and IP address hidden",
                "Custom block lists to block specific websites or domains",
                "Advanced malware and ads blocking",
                "Unlimited bandwidth and data usage",
                "Import/Export block lists for more tailored protection"
            ],
            mounthProductId: VPNSubscription.productIdMonthly,
            annualProductId: VPNSubscription.productIdAnnual
        )
    }
    
    static func universalDetails() -> Self {
        .init(
            title: NSLocalizedString("Unlimited Universal Protection", comment:""),
            subtitle: NSLocalizedString("Achieve Maximum Security for All Your Apple Devices", comment: ""),
            bulletPoints: [
                "Comprehensive protection across all Apple devices (iPhone, iPad, and Mac)",
                "Activation/Deactivation of MacOS protection",
                "Device-specific block lists for tailored protection",
                "Anonymized browsing and IP address change across all devices",
                "Maximum security with VPN and firewall",
                "Hidden location and IP address with advanced malware",
                "Unlimited bandwidth and data usage for all devices"
            ],
            mounthProductId: VPNSubscription.productIdMonthlyPro,
            annualProductId: VPNSubscription.productIdAnnualPro
        )
    }
}
