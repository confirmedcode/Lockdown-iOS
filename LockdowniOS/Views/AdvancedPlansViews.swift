//
//  AdvancedPlansViews.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 29.04.2023.
//

import UIKit

//// MARK: ClickListener
//class ClickListener: UITapGestureRecognizer {
//  var onClick : (() -> Void)? = nil
//}

final class AdvancedPlansViews: UIView {
    
    //MARK: Properties
    
    var isSelected: Bool = false
    
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        view.layer.borderColor = isSelected ? UIColor.white.cgColor : UIColor.borderGray.cgColor

        return view
    }()
    
    lazy var iconImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.image = isSelected ? UIImage(named: "fill-1") : UIImage(named: "grey-ellipse-1")
        image.layer.masksToBounds = true
        return image
    }()
    
    lazy var title: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = fontMedium17
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    lazy var detailTitle: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .white
        label.font = fontBold17
        return label
    }()
    
    lazy var detailTitle2: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = fontMedium13
        label.numberOfLines = 0
        label.textAlignment = .left
        
        return label
    }()
    
    lazy var discountImageView: UIImageView = {
        let imageView = UIImageView()
        //imageView.image = UIImage(named: "saveDiscount")
        imageView.contentMode = .scaleAspectFit
        return imageView
        }()
    
    private lazy var titleStackView: UIStackView = {
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
    
    private lazy var detailsStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(detailTitle)
        stackView.addArrangedSubview(detailTitle2)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        stackView.spacing = 2
        return stackView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(titleStackView)
        stackView.addArrangedSubview(detailsStackView)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.anchors.height.equal(74)
        stackView.anchors.width.equal(150)
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
        stackView.anchors.top.marginsPin(inset: 16)
        stackView.anchors.bottom.marginsPin(inset: 16)
        stackView.anchors.leading.marginsPin(inset: 16)
        stackView.anchors.trailing.pin()
        
        addSubview(discountImageView)
        discountImageView.anchors.top.spacing(-14, to: backgroundView.anchors.bottom)
        discountImageView.anchors.centerX.equal(backgroundView.anchors.centerX)
        
    }
}
