//
//  BlockListAddCell.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class BlockListAddCell: UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add line to bottom of Add Domain Text Field
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: addBlockListDomain.frame.height - 2, width: addBlockListDomain.frame.width, height: 2)
        bottomLine.backgroundColor = UIColor.tunnelsBlue.cgColor
        addBlockListDomain.layer.addSublayer(bottomLine)
    }

    @IBOutlet weak var addBlockListDomain: UITextField!
    
}
