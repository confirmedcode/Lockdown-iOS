//
//  ListDescriptionViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 29.03.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

protocol ListDescriptionViewControllerDelegate {
    func changeListDescription(description: String)
}

final class ListDescriptionViewController: UIViewController {
    
    var listName = ""
    
    var delegate: ListDescriptionViewControllerDelegate?
    
    var domains = getBlockedLists().userBlockListsDefaults
    
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
    
    private lazy var descriptionTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "No Description"
        view.text = domains[listName]?.description
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
        
        view.addSubview(descriptionTextField)
        descriptionTextField.anchors.top.spacing(12, to: navigationView.anchors.bottom)
        descriptionTextField.anchors.leading.marginsPin()
        descriptionTextField.anchors.trailing.marginsPin()
        descriptionTextField.anchors.height.equal(40)
        
        view.addSubview(validationPrompt)
        validationPrompt.anchors.top.spacing(8, to: descriptionTextField.anchors.bottom)
        validationPrompt.anchors.leading.marginsPin()
        validationPrompt.anchors.trailing.marginsPin()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        descriptionTextField.layer.cornerRadius = 8
    }
}

// MARK: - Functions
private extension ListDescriptionViewController {
    
    @objc func handleTextChange() {
        guard let text = descriptionTextField.text else { return }
        if text.isValid(.listDescription) {
            navigationView.rightNavButton.isEnabled = true
            validationPrompt.text = ""
        } else {
            navigationView.rightNavButton.isEnabled = false
            validationPrompt.text = "Invalid Description. Please use only letters and digits. The maximum number of symbols is 500."
        }
    }
    
    @objc func returnBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func doneButtonClicked() {
        
        guard let newDescription = descriptionTextField.text else { return }
        delegate?.changeListDescription(description: newDescription)
        
        let domains = getBlockedLists().userBlockListsDefaults
        var userList = domains[listName]

        userList?.description = descriptionTextField.text

        var data = getBlockedLists()
        data.userBlockListsDefaults[listName] = userList
        let encodedData = try? JSONEncoder().encode(data)
        defaults.set(encodedData, forKey: kUserBlockedLists)
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
