//
//  WelcomeViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 18.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    private lazy var bkgView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        return view
    }()
    
    let welcomeView = WelcomeView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        view.addSubview(bkgView)
        bkgView.anchors.leading.marginsPin()
        bkgView.anchors.trailing.marginsPin()
        bkgView.anchors.centerY.equal(view.anchors.centerY)

        bkgView.addSubview(welcomeView)
        welcomeView.anchors.top.pin()
        welcomeView.anchors.leading.pin()
        welcomeView.anchors.trailing.pin()
        welcomeView.anchors.bottom.pin()
        OneTimeActions.markAsSeen(.welcomeScreen)
        
        welcomeView.continueButton.addTarget(self, action: #selector(dismissed), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bkgView.applyGradient(.welcomePurple, corners: .continuous(15.0))
    }
    
    @objc func dismissed() {
        dismiss(animated: false)
    }
}
