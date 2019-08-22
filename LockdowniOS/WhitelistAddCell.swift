//
//  WhitelistAddCell.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class WhitelistAddCell: UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add line to bottom of Add Domain Text Field
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: addWhitelistDomain.frame.height - 2, width: addWhitelistDomain.frame.width, height: 2)
        bottomLine.backgroundColor = UIColor.tunnelsBlue.cgColor
        addWhitelistDomain.layer.addSublayer(bottomLine)
    }

    @IBOutlet weak var addWhitelistDomain: UITextField!
    
}
