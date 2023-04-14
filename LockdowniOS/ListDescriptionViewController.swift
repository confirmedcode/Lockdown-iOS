//
//  ListDescriptionViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 29.03.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class ListDescriptionViewController: UIViewController {
    
    // MARK: - Properties
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.titleLabel.text = NSLocalizedString("Name", comment: "")
        view.leftNavButton.setTitle("BACK", for: .normal)
        view.leftNavButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(returnBack), for: .touchUpInside)
        view.rightNavButton.setTitle("DONE", for: .normal)
        view.rightNavButton.addTarget(self, action: #selector(doneButtonClicked), for: .touchUpInside)
        view.rightNavButton.tintColor = .gray
        return view
    }()
    
    private lazy var descriptionTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "No Description"
        view.font = fontMedium17
        view.textColor = .label
        view.backgroundColor = .systemBackground
        view.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: .zero))
        view.leftViewMode = .always
        return view
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        descriptionTextField.layer.cornerRadius = 8
    }
}

// MARK: - Functions
private extension ListDescriptionViewController {
    
    func isValidListName(_ text: String) -> Bool {
        let regEx = "^[a-zA-Z0-9]{1,20}$"
        return text.range(of: "\(regEx)", options: .regularExpression) != nil
    }
    
    @objc func returnBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func doneButtonClicked() {
        navigationController?.popViewController(animated: true)
        // TODO: - add new list name to defaults if changed
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - TextField delegate methods
extension ListDescriptionViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        if textField == descriptionTextField {
            
            if let text = descriptionTextField.text {
                if self.isValidListName(text) == true {
                    navigationView.rightNavButton.isEnabled = true
                    navigationView.rightNavButton.setTitleColor(.tunnelsBlue, for: .normal)
                } else {
                    navigationView.rightNavButton.isEnabled = false
                    navigationView.rightNavButton.setTitleColor(.gray, for: .normal)
                }
            }
        }
        return true
    }
}
