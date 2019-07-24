//
//  CountryTableViewCell.swift
//  TunnelsiOS
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit

class CountryTableViewCell: UITableViewCell {

    //MARK: OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView?.frame = CGRect(x: (self.imageView?.frame.origin.x)!, y: (self.imageView?.frame.origin.y)!,width:32,height:32);
        self.imageView?.center.y = self.contentView.center.y
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
