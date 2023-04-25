//
//  LDCardView.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 19.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class LDCardView: UIView {
    
    // MARK: - Properties
    
    var isSelected: Bool = false
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        view.layer.borderColor = isSelected ? UIColor.gray.cgColor : UIColor.tunnelsBlue.cgColor
        return view
    }()
    
    lazy var iconImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.image = isSelected ? UIImage(named: "kksdlf") : UIImage(named: "dfgerte")
        image.layer.masksToBounds = true
        return image
    }()
    
    lazy var title: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontBold15
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    lazy var subTitle: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .label
        label.font = fontBold15
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(title)
        stackView.addArrangedSubview(subTitle)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    private func configureUI() {
        
        addSubview(backgroundView)
        backgroundView.anchors.edges.pin()
        
        backgroundView.addSubview(stackView)
        stackView.anchors.centerX.align()
        stackView.anchors.leading.marginsPin()
        stackView.anchors.trailing.marginsPin()
        stackView.anchors.centerY.align()
    }
}
