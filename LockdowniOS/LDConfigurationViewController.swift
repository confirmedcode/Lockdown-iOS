//
//  LDConfigurationViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 20.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

final class LDConfigurationViewController: UIViewController {
    
    // MARK: - Properties
    
    private lazy var activityCard: LDCardView = {
        let view = LDCardView()
        view.title.text = "Activity"
        view.iconImageView.image = UIImage(named: "icn_activity")
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [weak self] in
            guard let self else { return }
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "blockLogViewController") as! BlockLogViewController
            self.present(vc, animated: true, completion: nil)
        }
        return view
    }()
    
    private lazy var configureBlockingCard: LDCardView = {
        let view = LDCardView()
        view.title.text = "Configure blocking"
        view.title.numberOfLines = 0
        view.iconImageView.image = UIImage(named: "icn_configure_blocking")
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [weak self] in
            guard let self else { return }
            let navController = UINavigationController(rootViewController: BlockListViewController())
            navController.navigationBar.isHidden = true
            self.present(navController, animated: true)
        }
        return view
    }()
    
    private lazy var personalizedBlockingCard: LDCardView = {
        let view = LDCardView()
        view.title.text = "Personalized blocking"
        view.title.numberOfLines = 0
        view.iconImageView.image = UIImage(named: "icn_personalized_blocking")
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [weak self] in
            guard let self else { return }
            let vc = BlockListViewController()
            vc.chosenBlocking = 1
            let navController = UINavigationController(rootViewController: vc)
            navController.navigationBar.isHidden = true
            self.present(navController, animated: true)
        }
        return view
    }()
    
    private lazy var importListsCard: LDCardView = {
        let view = LDCardView()
        view.title.text = "Import custom block lists"
        view.title.numberOfLines = 0
        view.iconImageView.image = UIImage(named: "icn_import")
        view.isUserInteractionEnabled = true
        view.setOnClickListener { [weak self] in
            guard let self else { return }
            let vc = ImportBlockListViewController()
            self.present(vc, animated: true)
        }
        return view
    }()
    
    private lazy var hStack1: UIStackView = {
        let stack = UIStackView()
        stack.addArrangedSubview(activityCard)
        stack.addArrangedSubview(configureBlockingCard)
        stack.alignment = .center
        stack.axis = .horizontal
        stack.distribution = .equalCentering
        stack.spacing = 16
        return stack
    }()
    
    private lazy var hStack2: UIStackView = {
        let stack = UIStackView()
        stack.addArrangedSubview(personalizedBlockingCard)
        stack.addArrangedSubview(importListsCard)
        stack.alignment = .center
        stack.axis = .horizontal
        stack.distribution = .equalCentering
        stack.spacing = 16
        return stack
    }()
    
    private lazy var vStack: UIStackView = {
        let stack = UIStackView()
        stack.addArrangedSubview(hStack1)
        stack.addArrangedSubview(hStack2)
        stack.alignment = .center
        stack.axis = .vertical
        stack.distribution = .equalCentering
        stack.spacing = 16
        return stack
    }()
    
    private lazy var viewAccountSettingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View account settings", for: .normal)
        button.setTitleColor(.tunnelsBlue, for: .normal)
        button.titleLabel?.font = fontBold15
        button.addTarget(self, action: #selector(viewAccountSettings), for: .touchUpInside)
        return button
    }()
    
    private lazy var viewAuditReportButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View audit report (Feb, 2023)", for: .normal)
        button.setTitleColor(.tunnelsBlue, for: .normal)
        button.titleLabel?.font = fontBold15
        button.addTarget(self, action: #selector(viewAuditReport), for: .touchUpInside)
        return button
    }()
    
    lazy var vStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(viewAccountSettingsButton)
        stackView.addArrangedSubview(viewAuditReportButton)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(vStack)
        vStack.anchors.centerY.align()
        vStack.anchors.centerX.align()
        
        activityCard.anchors.width.equal(view.bounds.width / 2 - 20)
        activityCard.anchors.height.equal(view.bounds.width / 2 - 20)

        configureBlockingCard.anchors.width.equal(view.bounds.width / 2 - 20)
        configureBlockingCard.anchors.height.equal(view.bounds.width / 2 - 20)
        
        personalizedBlockingCard.anchors.width.equal(view.bounds.width / 2 - 20)
        personalizedBlockingCard.anchors.height.equal(view.bounds.width / 2 - 20)

        importListsCard.anchors.width.equal(view.bounds.width / 2 - 20)
        importListsCard.anchors.height.equal(view.bounds.width / 2 - 20)
        
        view.addSubview(vStackView)
        vStackView.anchors.top.spacing(30, to: vStack.anchors.bottom)
        vStackView.anchors.leading.marginsPin()
        vStackView.anchors.trailing.marginsPin()
    }
}

// MARK: - Private functions

private extension LDConfigurationViewController {
    
    @objc func viewAccountSettings() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "accountViewController") as! AccountViewController
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @objc func viewAuditReport() {
        showModalWebView(title: NSLocalizedString("Audit Reports", comment: ""), urlString: "https://openaudit.com/lockdownprivacy")
    }
    
    func showModalWebView(title: String, urlString: String) {
        if let url = URL(string: urlString) {
            let storyboardToUse = storyboard != nil ? storyboard! : UIStoryboard(name: "Main", bundle: nil)
            if let webViewVC = storyboardToUse.instantiateViewController(withIdentifier: "webview") as? WebViewViewController {
                webViewVC.titleLabelText = title
                webViewVC.url = url
                self.present(webViewVC, animated: true, completion: nil)
            }
            else {
                DDLogError("Unable to instantiate webview VC")
            }
        }
        else {
            DDLogError("Invalid URL \(urlString)")
        }
    }
}
