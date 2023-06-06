//
//  BulletView.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 27.04.2023.
//

import UIKit

struct BulletViewModel {
    let image: UIImage
    let title: String
}

final class BulletView: UIView {
    
    private lazy var bulletImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .left
        image.layer.masksToBounds = true
        image.anchors.height.equal(22)
        image.anchors.width.equal(22)
        return image
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = fontMedium15
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(bulletImage)
        stackView.addArrangedSubview(titleLabel)
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.spacing = 8
        return stackView
    }()
    
    //MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Functions
    private func configureUI() {
        addSubview(stackView)
        stackView.anchors.edges.pin()
    }
    
    func configure(with model: BulletViewModel) {
        bulletImage.image = model.image
        titleLabel.text = model.title
    }
}
