//
//  StepsViewController.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 21.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class StepsViewController: UIViewController, StepsViewProtocol {
    
    // MARK: - models
    var viewModel: StepsViewModel!
    
    // MARK: - views
    
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView(accentColor: .darkText)
        view.leftNavButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        view.leftNavButton.tintColor = .label
        view.rightNavButton.setTitle(NSLocalizedString("Skip", comment: ""), for: .normal)
        view.rightNavButton.addTarget(self, action: #selector(skipClicked), for: .touchUpInside)
        view.rightNavButton.tintColor = .label
        return view
    }()
    
    private lazy var stepsView: StepsView = {
        let view = StepsView()
        view.steps = viewModel.stepsCount
        return view
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton()
        button.anchors.height.equal(56)
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 29
        button.titleLabel?.font = .semiboldLockdownFont(size: 17)
        button.addTarget(self, action: #selector(actionClicked), for: .touchUpInside)
        button.setTitle(viewModel.actionTitle, for: .normal)
        return button
    }()
    
    private var contentView: UIView?

    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        viewModel.bind(self)
    }
    
    // MARK: - Configure UI
    private func configureUI() {
        view.backgroundColor = .panelSecondaryBackground
        
        view.addSubview(navigationView)
        navigationView.anchors.leading.pin()
        navigationView.anchors.trailing.pin()
        navigationView.anchors.top.safeAreaPin()
        
        view.addSubview(stepsView)
        stepsView.anchors.top.spacing(0, to: navigationView.anchors.bottom)
        stepsView.anchors.leading.pin(inset: 18)
        stepsView.anchors.trailing.pin(inset: 18)
        
        view.addSubview(actionButton)
        actionButton.anchors.leading.pin(inset: 24)
        actionButton.anchors.trailing.pin(inset: 24)
        actionButton.anchors.bottom.safeAreaPin(inset: 14)
        
        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped))
        )
    }
    
    func changeContent() {
        contentView?.removeFromSuperview()
        
        let staticTableView = viewModel.stepViewModel.contentView()
        addTableView(staticTableView) { tableView in
            staticTableView.anchors.top.spacing(0, to: stepsView.anchors.bottom)
            staticTableView.anchors.leading.pin()
            staticTableView.anchors.trailing.pin()
            staticTableView.anchors.bottom.spacing(18, to: actionButton.anchors.top)
        }
        contentView = staticTableView
        stepsView.currentStep = viewModel.currentStepIndex
        navigationView.rightNavButton.isHidden = !viewModel.showSkipButton
    }
    
    func close(completion: (() -> Void)?) {
        dismiss(animated: true, completion: completion)
    }
    
    func showSelectCountry(with viewModel: SelectCountryViewModelProtocol) {
        let viewController = SelectCountryViewController()
        viewController.viewModel = viewModel
        present(viewController, animated: true)
    }
    
    func showAlert(_ title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(.init(
            title: NSLocalizedString("Ok", comment: ""), style: .default)
        )
        
        present(alert, animated: true)
    }
    
    // MARK: - actions
    
    @objc private func backButtonClicked() {
        viewModel.backPressed()
    }
    
    @objc private func skipClicked() {
        viewModel.skipStep()
    }
    
    @objc private func actionClicked() {
        viewModel.performStepAction()
    }
    
    @objc private func tapped() {
        view.endEditing(true)
    }
}
