//
//  ListDetailViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 29.03.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

protocol ListDetailViewControllerDelegate {
    func changeListName(name: String)
}

final class ListDetailViewController: UIViewController {
    
    var delegate: ListDetailViewControllerDelegate?
    
    var listName = ""
    
    // MARK: - Properties
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.titleLabel.text = NSLocalizedString("Name", comment: "")
        view.leftNavButton.setTitle("BACK", for: .normal)
        view.leftNavButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(returnBack), for: .touchUpInside)
        view.rightNavButton.setTitle("DONE", for: .normal)
        view.rightNavButton.addTarget(self, action: #selector(doneButtonClicked), for: .touchUpInside)
        return view
    }()
    
    lazy var listNameTextField: UITextField = {
        let view = UITextField()
        view.text = listName
        view.font = fontMedium17
        view.textColor = .label
        view.backgroundColor = .systemBackground
        view.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: .zero))
        view.leftViewMode = .always
        view.addTarget(self, action: #selector(handleTextChange), for: .editingChanged)
        return view
    }()
    
    private lazy var validationPrompt: UILabel = {
        let label = UILabel()
        label.textColor = .red
        label.font = fontRegular14
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        configureUI()
    }
    
    // MARK: - Configure UI
    private func configureUI() {
        view.addSubview(navigationView)
        navigationView.anchors.leading.pin()
        navigationView.anchors.trailing.pin()
        navigationView.anchors.top.safeAreaPin()
        
        view.addSubview(listNameTextField)
        listNameTextField.anchors.top.spacing(12, to: navigationView.anchors.bottom)
        listNameTextField.anchors.leading.marginsPin()
        listNameTextField.anchors.trailing.marginsPin()
        listNameTextField.anchors.height.equal(40)
        
        view.addSubview(validationPrompt)
        validationPrompt.anchors.top.spacing(8, to: listNameTextField.anchors.bottom)
        validationPrompt.anchors.leading.marginsPin()
        validationPrompt.anchors.trailing.marginsPin()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        listNameTextField.layer.cornerRadius = 8
    }
}

// MARK: - Functions
extension ListDetailViewController {
    
    @objc func handleTextChange() {
        guard let text = listNameTextField.text else { return }
        if text.isValid(.listName) {
            navigationView.rightNavButton.isEnabled = true
            validationPrompt.text = ""
        } else {
            navigationView.rightNavButton.isEnabled = false
            validationPrompt.text = "Invalid name. Please use only letters and digits. The maximum number of symbols is 20."
        }
    }
    
    @objc func returnBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func doneButtonClicked() {

        guard let newListName = listNameTextField.text else { return }
        
        delegate?.changeListName(name: newListName)
        if listName != newListName {
            changeBlockedListName(from: listName, to: newListName)
        }
        navigationController?.popViewController(animated: true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
