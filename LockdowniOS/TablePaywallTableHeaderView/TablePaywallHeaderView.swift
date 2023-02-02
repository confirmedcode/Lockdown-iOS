//
//  TablePaywallHeaderView.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/5/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

final class TablePaywallHeaderView: UIView, NibLoadable {
    
    @IBOutlet private var featureTitleLabel: UILabel!
    @IBOutlet private var freeLevelTitleLabel: UILabel!
    @IBOutlet private var vpnLevelTitleLabel: UILabel!
    @IBOutlet private var proLevelTitleLabel: UILabel!
    
    static func make() -> TablePaywallHeaderView {
        let view = TablePaywallHeaderView.loadFromNib()
        
        view.featureTitleLabel.text = .localized("feature_table_column")
        view.freeLevelTitleLabel.text = .localized("feature_level_table_column")
        
        let fontSize: CGFloat = UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 16 : 11
        view.featureTitleLabel.font = .semiboldLockdownFont(size: fontSize)
        view.freeLevelTitleLabel.font = .semiboldLockdownFont(size: fontSize)
        view.vpnLevelTitleLabel.font = .semiboldLockdownFont(size: fontSize)
        view.proLevelTitleLabel.font = .semiboldLockdownFont(size: fontSize)
        
        return view
    }
}
