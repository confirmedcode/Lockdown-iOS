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
        view.buttonTitle = NSLocalizedString("CLOSE", comment: "")
        view.onButtonPressed { [unowned self] in
            self.closeButtonClicked()
        }
        return view
    }()
    
    private lazy var bulletView1: BulletView = {
        let view = BulletView()
        view.titleLabel.textColor = .label
        view.titleLabel.font = fontRegular15
        view.configure(with: BulletViewModel(image: UIImage(named: "icn_checkmark_bold")!, title: "We have updated the subscription names to better reflect the benefit of the subscriptions. VPN subscriptions are now known as Anonymous. VPN Pro subscriptions are now known as Universal. And the new firewall subscriptions are referred to as Advanced. The new firewall features are available under the Anonymous and Universal plans."))
        return view
    }()
    
    private lazy var bulletView2: BulletView = {
        let view = BulletView()
        view.titleLabel.textColor = .label
        view.titleLabel.font = fontRegular15
        view.configure(with: BulletViewModel(image: UIImage(named: "icn_checkmark_bold")!, title: "We have replaced the NEKit blocking engine with a much more powerful, efficient, and secure blocking engine, DNS Crypt. This allows us to add new firewall capabilities like importing/exporting blocklists, large curated app-specific blocklists."))
        return view
    }()
    
    private lazy var bulletView3: BulletView = {
        let view = BulletView()
        view.titleLabel.textColor = .label
        view.titleLabel.font = fontRegular15
        view.configure(with: BulletViewModel(image: UIImage(named: "icn_checkmark_bold")!, title: "New Firewall Features - import lists, build custom lists from custom added domains, export custom lists. Toggle off/on app-specific and new advanced block lists."))
        return view
    }()
    
    private lazy var bulletsStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(bulletView1)
        stackView.addArrangedSubview(bulletView2)
        stackView.addArrangedSubview(bulletView3)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 16
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
        
        view.addSubview(bulletsStackView)
        bulletsStackView.anchors.top.spacing(18, to: navigationView.anchors.bottom)
        bulletsStackView.anchors.leading.marginsPin()
        bulletsStackView.anchors.trailing.marginsPin()
    }

    //MARK: Functions
    @objc private func closeButtonClicked() {
        dismiss(animated: true)
    }
}
