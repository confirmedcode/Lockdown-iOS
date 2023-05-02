//
//  TrackersGroupView.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 18.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

struct TrackersGroupViewModel {
    let image: UIImage
    let title: String
    let number: Int
}

final class TrackersGroupView: UIView {
    
    // MARK: - Properties
    
    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.anchors.height.equal(1)
        return view
    }()
    
    lazy var placeNumber: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontMedium15
        label.textAlignment = .left
        return label
    }()
    
    private lazy var trackersImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .left
        image.layer.masksToBounds = true
        return image
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontMedium15
        label.text = "Game Marketing"
        label.textAlignment = .left
        return label
    }()
    
    lazy var number: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontBold18
        label.textColor = .red
        label.textAlignment = .right
        return label
    }()
    
    lazy var lockImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .right
        image.layer.masksToBounds = true
        image.image = UIImage(named: "icn_lock")
        return image
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(placeNumber)
        stackView.addArrangedSubview(trackersImage)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(number)
        stackView.addArrangedSubview(lockImage)
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.anchors.height.equal(40)
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
        
        addSubview(separator)
        separator.anchors.leading.pin()
        separator.anchors.trailing.pin()
        separator.anchors.top.pin()
        
        addSubview(stackView)
        stackView.anchors.top.spacing(12, to: separator.anchors.bottom)
        stackView.anchors.bottom.pin()
        stackView.anchors.leading.marginsPin()
        stackView.anchors.trailing.marginsPin()
        
        trackersImage.anchors.leading.pin(inset: 35)
        trackersImage.anchors.centerY.equal(placeNumber.anchors.centerY)
        
        titleLabel.anchors.leading.pin(inset: 70)
    }
    
    func configure(with model: TrackersGroupViewModel) {
        trackersImage.image = model.image
        titleLabel.text = model.title
        number.text = String(model.number)
    }
}
