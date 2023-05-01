//
//  PlansView.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 26.04.2023.
//

import UIKit

final class PlanView: UIView {
    
    //MARK: Properties
    
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.borderGray.cgColor
        return view
    }()
    
    lazy var iconImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.image = UIImage(named: "grey-ellipse-1")
        image.layer.masksToBounds = true
        return image
    }()
    
    lazy var title: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = fontSemiBold17
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(title)
        stackView.addArrangedSubview(iconImageView)
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 0
        stackView.anchors.width.equal(130)
        return stackView
    }()
    
    //MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Functions
    
    private func configureUI() {
        
        addSubview(backgroundView)
        backgroundView.anchors.edges.pin()
        
        backgroundView.addSubview(stackView)
       
        stackView.anchors.top.marginsPin(inset: 8)
        stackView.anchors.bottom.marginsPin(inset: 8)
        stackView.anchors.leading.marginsPin(inset: 16)
        stackView.anchors.trailing.marginsPin()
    }
}
