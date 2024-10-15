//
//  RadioSwitcher.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 22.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class RadioSwitcher: UIView {
    
    var isSelected = false {
        didSet {
            updateImageView()
        }
    }
    var didSelect: ((Bool) -> Void)?
    
    var selectedImage = UIImage(named: "selectedRadioSwitcher")
    var unselectedImage = UIImage(named: "unselectedRadioSwitcher")
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: unselectedImage)
        view.contentMode = .scaleAspectFit
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggle() {
        tapped()
    }

    private func configure() {
        backgroundColor = .clear
        
        addSubview(imageView)
        imageView.anchors.edges.pin()
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped))
        )
    }
    
    private func updateImageView() {
        imageView.image = isSelected ? selectedImage : unselectedImage
    }

    @objc private func tapped() {
        isSelected.toggle()
        didSelect?(isSelected)
    }
}
