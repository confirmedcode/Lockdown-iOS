//
//  ProductButton.swift
//  Lockdown
//
//  Created by Denis Aleshyn on 10/05/2024.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import Foundation
import UIKit

final class ProductButton: UIButton {
    lazy var iconImageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        image.image = UIImage(named: "grey-ellipse-1")
        image.layer.masksToBounds = true
        image.widthAnchor.constraint(equalToConstant: 16).isActive = true
        image.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return image
    }()
    
    lazy var containerStack: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillProportionally
        stack.spacing = 0
        return stack
    }()
    
    init(title: String, subtitle: String, toHighlight: String?, isSelected: Bool = false) {
        super.init(frame: .zero)
        self.tintColor = .white
        self.backgroundColor = .clear
        self.layer.cornerRadius = 8
        
        self.layer.borderWidth = isSelected ? 3 : 1
        self.layer.borderColor = isSelected ? UIColor.white.cgColor : UIColor.gray.cgColor
        self.iconImageView.image = isSelected ? UIImage(named: "fill-2") : UIImage(named: "grey-ellipse-1")
        
        let planPeriodLabel = UILabel()
        planPeriodLabel.translatesAutoresizingMaskIntoConstraints = false
        planPeriodLabel.font = fontSemiBold15
        planPeriodLabel.textColor = .white
        planPeriodLabel.textAlignment = .left
        planPeriodLabel.text = title
        
        let planPriceLabel = UILabel()
        planPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        planPriceLabel.font = fontRegular15
        planPriceLabel.textColor = .white
        planPriceLabel.textAlignment = .left
        planPriceLabel.text = subtitle
        
        if let toHighlight {
            planPriceLabel.highlight(toHighlight, font: UIFont.boldLockdownFont(size: 16))
        }
        
        let subscriptionPlanStack = UIStackView()
        subscriptionPlanStack.addArrangedSubview(planPeriodLabel)
        subscriptionPlanStack.addArrangedSubview(planPriceLabel)
        subscriptionPlanStack.translatesAutoresizingMaskIntoConstraints = false
        subscriptionPlanStack.axis = .vertical
        subscriptionPlanStack.alignment = .leading
        subscriptionPlanStack.distribution = .fill
        subscriptionPlanStack.spacing = 7
        
        let imageContainerStack = UIStackView(arrangedSubviews: [buffer(), iconImageView, buffer()])
        imageContainerStack.axis = .vertical
        imageContainerStack.distribution = .fillEqually
        
        addSubview(containerStack)
       
        containerStack.anchors.top.pin()
        containerStack.anchors.bottom.pin()
        containerStack.anchors.leading.pin(inset: 10)
        containerStack.anchors.trailing.pin(inset: 10)
        containerStack.addArrangedSubview(subscriptionPlanStack)
        containerStack.addArrangedSubview(buffer())
        containerStack.addArrangedSubview(imageContainerStack)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buffer(_ color: UIColor = .clear) -> UIView {
        let buf = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        buf.translatesAutoresizingMaskIntoConstraints = false
        buf.backgroundColor = color
        buf.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        buf.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        return buf
    }
    
    func setSelected(_ isSelected: Bool) {
        self.layer.borderWidth = isSelected ? 3 : 1
        self.layer.borderColor = isSelected ? UIColor.white.cgColor : UIColor.gray.cgColor
        self.iconImageView.image = isSelected ? UIImage(named: "fill-2") : UIImage(named: "grey-ellipse-1")
    }

}
