//
//  AccountProtocolCell.swift
//  Confirmed VPN
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class AccountProtocolCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet weak var protocolName: UILabel?
    @IBOutlet weak var changeProtocol: UIButton?
    
}
