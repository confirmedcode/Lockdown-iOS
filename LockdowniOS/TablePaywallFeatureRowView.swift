//
//  TablePaywallFeatureRowView.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/5/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

final class TablePaywallFeatureRowView: UIView, NibLoadable {
    
    @IBOutlet private var featureLabel: UILabel!
    
    @IBOutlet private var freeLevelIcon: UIImageView!
    @IBOutlet private var vpnLevelIcon: UIImageView!
    @IBOutlet private var proLevelIcon: UIImageView!
    
    static func make(feature: PaywallTableFeature, isHighlighted: Bool) -> TablePaywallFeatureRowView {
        let view = TablePaywallFeatureRowView.loadFromNib()
        
        view.setupFeatureText(for: feature, isHighlighted: isHighlighted)
        view.setupIcons(for: feature)
        
        return view
    }
    
    private func setupFeatureText(for feature: PaywallTableFeature, isHighlighted: Bool) {
        featureLabel.text = feature.body
        featureLabel.textColor = isHighlighted ? .label : .gray
        
        let fontSize: CGFloat = UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 16 : 11
        featureLabel.font = .semiboldLockdownFont(size: fontSize)
    }
    
    private func setupIcons(for feature: PaywallTableFeature) {
        freeLevelIcon.image = imageForAvailabilityStatus(feature.isAvailableForFree)
        freeLevelIcon.tintColor = colorForAvailabilityStatus(feature.isAvailableForFree)
        
        vpnLevelIcon.image = imageForAvailabilityStatus(feature.isAvailableOnVPN)
        vpnLevelIcon.tintColor = colorForAvailabilityStatus(feature.isAvailableOnVPN)
        
        proLevelIcon.image = imageForAvailabilityStatus(feature.isAvailableOnPro)
        proLevelIcon.tintColor = colorForAvailabilityStatus(feature.isAvailableOnPro)
    }
    
    private func imageForAvailabilityStatus(_ isAvailable: Bool) -> UIImage {
        let image = (isAvailable ? UIImage(named: "Checkmark") : UIImage(named: "ComparisonTableXmark"))
        return image?.withRenderingMode(.alwaysTemplate) ?? UIImage()
    }
    
    private func colorForAvailabilityStatus(_ isAvailable: Bool) -> UIColor {
        return isAvailable ? .confirmedBlue : .gray
    }
}
