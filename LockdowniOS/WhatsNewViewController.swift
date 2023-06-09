//
//  WhatsNewViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 30.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class WhatsNewViewController: UIViewController {
    
    private lazy var navigationView: CustomNavigationView = {
        let view = CustomNavigationView()
        view.title = NSLocalizedString("What's New", comment: "")
        view.titleView.font = .boldLockdownFont(size: 17)
        view.buttonTitle = NSLocalizedString("CLOSE", comment: "")
        view.onButtonPressed { [unowned self] in
            self.closeButtonClicked()
        }
        return view
    }()
    
    private lazy var headerView: UIView = {
        headerView(
            withTitle: NSLocalizedString("Lockdown 2.0", comment: "Lockdown title"),
            andSubtitle: NSLocalizedString("Lockdown 2.0 brings a variety of new features to the world's first fully audited and Openly Operated privacy app!", comment: "Lockdown subtitle")
        )
    }()
    
    private lazy var protectionLevelsView: UIView = {
        let titleLable = UILabel()
        titleLable.font = .boldLockdownFont(size: 22)
        titleLable.textColor = .label
        titleLable.numberOfLines = 0
        titleLable.text = NSLocalizedString("Protection Levels", comment: "")
        
        let footerLabel = secondaryLabel()
        footerLabel.text = NSLocalizedString("The new Advanced level features are available under the Anonymous and Universal plans.", comment: "")
        footerLabel.highlight(
                NSLocalizedString("Advanced", comment: ""),
                NSLocalizedString("Anonymous", comment: ""),
                NSLocalizedString("Universal", comment: ""),
            font: .boldLockdownFont(size: 15)
        )
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.addArrangedSubview(titleLable)
        bulletList.forEach { stackView.addArrangedSubview($0) }
        stackView.addArrangedSubview(footerLabel)
        return stackView
    }()
    
    private lazy var bulletList = [
        bulletView1,
        bulletView2,
        bulletView3,
        bulletView4
    ]
    
    private lazy var bulletView1: BulletView = {
        bulletView(
            with: BulletViewModel(
                image: UIImage(named: "icn_checkmark_bold")!,
                title: NSLocalizedString("Basic allows you to use our firewall, and block custom domains as well as domains in our basic curated lists. ", comment: ""),
                highlightedStrings: [NSLocalizedString("Basic", comment: "")]
            )
        )
    }()
    
    private lazy var bulletView2: BulletView = {
        bulletView(
            with: BulletViewModel(
                image: UIImage(named: "icn_checkmark_bold")!,
                title: NSLocalizedString("With Advanced protection, you get the benefit of blocking domains in our advanced block lists and creating/importing/exporting block lists.", comment: ""),
                highlightedStrings: [NSLocalizedString("Advanced", comment: "")]
            )
        )
    }()
    
    private lazy var bulletView3: BulletView = {
        bulletView(
            with:
                BulletViewModel(
                    image: UIImage(named: "icn_checkmark_bold")!,
                    title: NSLocalizedString("VPN subscriptions are now known as Anonymous.", comment: ""),
                    highlightedStrings: [NSLocalizedString("Anonymous", comment: "")]
                )
        )
    }()
    
    private lazy var bulletView4: BulletView = {
        bulletView(
            with: BulletViewModel(
                image: UIImage(named: "icn_checkmark_bold")!,
                title: NSLocalizedString("Pro subscriptions are now known as Universal", comment: ""),
                highlightedStrings: [NSLocalizedString("Universal", comment: "")]
            )
        )
    }()
    
    private lazy var footerView: UIView = {
        headerView(
            withTitle: NSLocalizedString("Blocking Engine", comment: ""),
            andSubtitle: NSLocalizedString("The firewall is now much more powerful, efficient, and secure. It also comes with new capabilities like importing/exporting and large curated advanced blocklists.", comment: ""),
            titleFontSize: 22
        )
    }()
    
    private lazy var bulletsStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(headerView)
        stackView.addArrangedSubview(protectionLevelsView)
        stackView.addArrangedSubview(footerView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 24
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    //MARK: ConfigureUI
    private func configureUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(navigationView)
        navigationView.anchors.top.safeAreaPin()
        navigationView.anchors.leading.pin()
        navigationView.anchors.trailing.pin()
        
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.anchors.top.spacing(18, to: navigationView.anchors.bottom)
        scrollView.anchors.leading.marginsPin()
        scrollView.anchors.trailing.marginsPin()
        scrollView.anchors.bottom.marginsPin()
        
        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.anchors.top.pin()
        contentView.anchors.leading.pin()
        contentView.anchors.trailing.pin()
        contentView.anchors.bottom.pin()
        contentView.anchors.width.equal(scrollView.anchors.width)
        
        contentView.addSubview(bulletsStackView)
        bulletsStackView.anchors.top.pin()
        bulletsStackView.anchors.leading.pin()
        bulletsStackView.anchors.trailing.pin()
        bulletsStackView.anchors.bottom.pin()
    }

    //MARK: Functions
    @objc private func closeButtonClicked() {
        dismiss(animated: true)
    }
    
    private func headerView(
        withTitle title: String,
        andSubtitle subtitle: String,
        titleFontSize: CGFloat = 26
    ) -> UIView {
        let titleLable = UILabel()
        titleLable.font = .boldLockdownFont(size: titleFontSize)
        titleLable.textColor = .label
        titleLable.numberOfLines = 0
        titleLable.text = title
        
        let subtitleLabel = secondaryLabel()
        subtitleLabel.text = subtitle
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 16.0
        stackView.addArrangedSubview(titleLable)
        stackView.addArrangedSubview(subtitleLabel)
        return stackView
    }
    
    private func secondaryLabel() -> UILabel {
        let label = UILabel()
        label.font = .regularLockdownFont(size: 15)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }
    
    private func bulletView(with model: BulletViewModel) -> BulletView {
        let view = BulletView()
        view.titleLabel.textColor = .label
        view.titleLabel.font = fontRegular15
        view.configure(with: model)
        return view
    }
 }
