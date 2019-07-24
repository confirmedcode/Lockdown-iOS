//
//  FeatureCell.swift
//  
//
//

import UIKit

class FeatureCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet weak var featureStatus: M13Checkbox?
    @IBOutlet weak var featureTitle: UILabel?
    @IBOutlet weak var featureSubtitle: UILabel?
    
}
