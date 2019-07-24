//
//  AdBlockerCell.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit

class AdBlockerCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet weak var isEnabled: UISwitch?
    @IBOutlet weak var contetText: UILabel?
    
    
}
