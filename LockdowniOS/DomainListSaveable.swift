//
//  DomainListSaveable.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 23.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

protocol DomainListSaveable {
    func showCreateList(
        initialListName: String?,
        forDomainList domains: Set<String>,
        completion: @escaping (Set<String>, String) -> Void
    )
}

extension DomainListSaveable where Self: UIViewController {
    func showCreateList(
        initialListName: String?,
        forDomainList domains: Set<String>,
        completion: @escaping (Set<String>, String) -> Void
    ) {
        let alertController = UIAlertController(title: "Create New List", message: nil, preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                self?.validateListName(text, forDomainList: domains, completion: completion)
            }
        }
        
        saveAction.isEnabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (_) in
            guard let self else { return }
            self.dismiss(animated: true)
        }
        
        alertController.addTextField { (textField) in
            textField.text = initialListName
            textField.placeholder = NSLocalizedString("List Name", comment: "")
        }
        
        NotificationCenter.default.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: alertController.textFields?.first,
            queue: .main) { (notification) -> Void in
                guard let textFieldText = alertController.textFields?.first?.text else { return }
                saveAction.isEnabled = textFieldText.isValid(.listName)
            }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func validateListName(
        _ name: String,
        forDomainList domains: Set<String>,
        completion: @escaping (Set<String>, String) -> Void
    ) {
        guard !getBlockedLists().userBlockListsDefaults.keys.contains(name) else {
            showAlertAboutExistingListName { [weak self] in
                self?.showCreateList(
                    initialListName: name,
                    forDomainList: domains,
                    completion: completion
                )
            }
            return
        }
        
        completion(domains, name)
    }
    
    private func showAlertAboutExistingListName(completion: @escaping () -> Void) {
        let alertController = UIAlertController(
            title: NSLocalizedString("This list name is already exist!", comment: ""),
            message: NSLocalizedString("Please choose another name.", comment: ""),
            preferredStyle: .alert
        )
        
        alertController.addAction(
            .init(
                title: NSLocalizedString("Ok", comment: ""),
                style: .default,
                handler: { _ in
                    completion()
                }
            )
        )
        
        present(alertController, animated: true)
    }
}
