//
//  AnnualPlanView.swift
//  LockdownSandbox
//
//  Created by Алишер Ахметжанов on 30.04.2023.
//

import UIKit

final class AnnualPlanView: UIView {
    //MARK: Properties
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        return view
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.anchors.height.equal(400)
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Unlock Advanced Level Protection", comment: "")
        label.textColor = .white
        label.font = fontBold34
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("And Get", comment: "")
        label.textColor = .white
        label.font = fontSemiBold22
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    lazy var bulletView1: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Custom block lists"))
        return view
    }()
    
    lazy var bulletView2: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Advanced malware & ads blocking"))
        return view
    }()
    
    lazy var bulletView3: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Unlimited blocking"))
        return view
    }()
    
    lazy var bulletView4: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "App-specific block lists"))
        return view
    }()
    
    lazy var bulletView5: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Advanced encryption protocols"))
        return view
    }()
    
    lazy var bulletView6: BulletView = {
        let view = BulletView()
        view.configure(with: BulletViewModel(image: UIImage(named: "Checkbox")!, title: "Import/Export your own block lists"))
        return view
    }()
    
    private lazy var bulletsStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(bulletView1)
        stackView.addArrangedSubview(bulletView2)
        stackView.addArrangedSubview(bulletView3)
        stackView.addArrangedSubview(bulletView4)
        stackView.addArrangedSubview(bulletView5)
        stackView.addArrangedSubview(bulletView6)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        return stackView
    }()
    
    lazy var firsttimeLabel: UILabel = {
        let label = UILabel()
        label.font = fontSemiBold13
        label.textAlignment = .center
        label.numberOfLines = 0
        let attributedText = NSMutableAttributedString(string: NSLocalizedString("First time subscribers start with a ", comment: ""), attributes: [NSAttributedString.Key.font: fontSemiBold13, NSAttributedString.Key.foregroundColor: UIColor.white])
        attributedText.append(NSAttributedString(string: NSLocalizedString("7-Day Free Trial", comment: ""), attributes: [NSAttributedString.Key.font: fontSemiBold13, NSAttributedString.Key.foregroundColor: UIColor.paywallOrange]))
        label.attributedText = attributedText
        
        return label
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
    
    //MARK: ConfigureUI
    private func configureUI() {
        
        addSubview(firsttimeLabel)
        firsttimeLabel.anchors.bottom.pin(inset: 8)
        firsttimeLabel.anchors.leading.marginsPin()
        firsttimeLabel.anchors.trailing.marginsPin()
        
        addSubview(scrollView)
        scrollView.anchors.top.pin()
        scrollView.anchors.leading.pin(inset: 16)
        scrollView.anchors.trailing.pin()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.anchors.bottom.spacing(24, to: firsttimeLabel.anchors.top)
        
        scrollView.addSubview(contentView)
        contentView.anchors.top.pin()
        contentView.anchors.centerX.align()
        contentView.anchors.width.equal(scrollView.anchors.width)
        contentView.anchors.bottom.pin()
        
        contentView.addSubview(bulletsStackView)
        bulletsStackView.anchors.leading.marginsPin()
        bulletsStackView.anchors.trailing.marginsPin()
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.anchors.bottom.spacing(24, to: bulletsStackView.anchors.top)
        descriptionLabel.anchors.leading.marginsPin()
        descriptionLabel.anchors.trailing.marginsPin()
        
        contentView.addSubview(titleLabel)
        titleLabel.anchors.bottom.spacing(24, to: descriptionLabel.anchors.top)
        titleLabel.anchors.leading.marginsPin()
        titleLabel.anchors.trailing.marginsPin()
        titleLabel.anchors.top.marginsPin()
    }
}
