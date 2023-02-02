//
//  LockdownPaywallOptionCell.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/5/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation
import UIKit

final class LockdownPaywallOptionCell: UICollectionViewCell, Dequeuable {
    
    @IBOutlet private var gradientView: UIView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!
    @IBOutlet private var afterTrialLabel: UILabel!
    
    static var dequeuableId: String = .init(describing: LockdownPaywallOptionCell.self)
    
    private var gradientLayer: CAGradientLayer?
    
    func configure(with offer: SubscriptionOffer) {
        titleLabel.attributedText = offer.productGroup.localizedTitle(for: .defaultPaywall)
        priceLabel.text = offer.pricePerPeriod
        afterTrialLabel.text = offer.afterTrialPeriodText
    }
    
    func toggleSelect(isSelected: Bool, animated: Bool) {
        if isSelected {
            gradientView.layer.borderWidth = 0
            gradientLayer = gradientView.applyGradient(
                colors: [
                    hexStringToUIColor(hex: "#00B6F3").cgColor,
                    hexStringToUIColor(hex: "#0099CD").cgColor
                ],
                cornerRadius: gradientView.layer.cornerRadius)
            
            [titleLabel, priceLabel, afterTrialLabel].forEach {
                $0?.textColor = .white
            }
            if animated {
                showAnimatedPress()
            }
        } else {
            gradientView.layer.borderWidth = 1
            if #available(iOS 13.0, *) {
                gradientView.backgroundColor = .systemBackground
                afterTrialLabel.textColor = .secondaryLabel
                [titleLabel, priceLabel].forEach {
                    $0?.textColor = .label
                }
            } else {
                gradientView.backgroundColor = .white
                afterTrialLabel.textColor = .lightGray
                [titleLabel, priceLabel].forEach {
                    $0?.textColor = .black
                }
            }
        }
    }
    
    override func prepareForReuse() {
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        gradientView.layer.cornerRadius = 8
        gradientView.layer.borderColor = UIColor.lightGray.cgColor
    }
}
