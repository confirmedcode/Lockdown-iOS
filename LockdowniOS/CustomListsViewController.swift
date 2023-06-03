//
//  CustomListsViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 2.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

final class CustomListsViewController: UIViewController {
    
    // MARK: - Properties
    
    var didMakeChange = false
    var customBlockedDomains: [(String, Bool)] = []
    
    var customBlockedLists: [UserBlockListsGroup] = []
    
    let customBlockedListsTableView = StaticTableView()
    let customBlockedDomainsTableView = StaticTableView()
    
    private lazy var listsSubmenuView: ListsSubmenuView = {
        let view = ListsSubmenuView()
        view.topButton.addTarget(self, action: #selector(addList), for: .touchUpInside)
        view.bottomButton.addTarget(self, action: #selector(importBlockList), for: .touchUpInside)
        view.isHidden = true
        return view
    }()
    
    private lazy var addNewListButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold, scale: .large)
        button.tintColor = .tunnelsBlue
        button.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig), for: .normal)
        button.addTarget(self, action: #selector(showSubmenu), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private lazy var listsLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Lists", comment: "")
        label.textColor = .label
        label.font = fontBold18
        return label
    }()
    
    private lazy var emptyListsView: EmptyListsView = {
        let view = EmptyListsView()
        view.descriptionLabel.text = NSLocalizedString("No lists yet", comment: "")
        view.addButton.setTitle(NSLocalizedString("Create a list", comment: ""), for: .normal)
        view.addButton.addTarget(self, action: #selector(addList), for: .touchUpInside)
        return view
    }()
    
    private lazy var lockedListsView: LockedListsView = {
        let view = LockedListsView()
        return view
    }()
    
    private lazy var domainsLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Domains", comment: "")
        label.textColor = .label
        label.font = fontBold18
        return label
    }()
    
    private lazy var addNewDomainButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold, scale: .large)
        button.tintColor = .tunnelsBlue
        button.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig), for: .normal)
        button.addTarget(self, action: #selector(addDomain), for: .touchUpInside)
        return button
    }()
    
    private lazy var editDomainButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold, scale: .large)
        button.tintColor = .tunnelsBlue
        button.setImage(UIImage(named: "icn_edit"), for: .normal)
        button.addTarget(self, action: #selector(editDomains), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var emptyDomainsView: EmptyListsView = {
        let view = EmptyListsView()
        view.descriptionLabel.text = NSLocalizedString("No custom domains yet", comment: "")
        view.addButton.setTitle(NSLocalizedString("Add a domain", comment: ""), for: .normal)
        view.addButton.addTarget(self, action: #selector(addDomain), for: .touchUpInside)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
//        configure()
        configureCustomBlockedListsTableView()
//        configureCustomBlockedDomainsTableView()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCustomBlockedLists()
    }
    
    private func configureCustomBlockedListsTableView() {
        
//        view.addSubview(listsLabel)
//        listsLabel.anchors.top.spacing(24, to: segmented.anchors.bottom)
//        listsLabel.anchors.leading.marginsPin()

//        view.addSubview(addNewListButton)
//        addNewListButton.anchors.centerY.equal(listsLabel.anchors.centerY)
//        addNewListButton.anchors.trailing.marginsPin()
        
//        view.addSubview(domainsLabel)
//        domainsLabel.anchors.top.spacing(300, to: segmented.anchors.bottom)
//        domainsLabel.anchors.height.equal(30)
//        domainsLabel.anchors.leading.marginsPin()
        
        addTableView(customBlockedListsTableView, layout: { tableView in
            tableView.anchors.top.marginsPin()
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
//            tableView.anchors.bottom.marginsPin()
        })
        
//        view.addSubview(listsSubmenuView)
//        listsSubmenuView.anchors.trailing.marginsPin()
//        listsSubmenuView.anchors.top.marginsPin()
        
        customBlockedListsTableView.deselectsCellsAutomatically = true
    }
    
    private func configureCustomBlockedDomainsTableView() {
        
//        view.addSubview(addNewDomainButton)
//        addNewDomainButton.anchors.centerY.equal(domainsLabel.anchors.centerY)
//        addNewDomainButton.anchors.trailing.marginsPin()
//
//        view.addSubview(editDomainButton)
//        editDomainButton.anchors.centerY.equal(domainsLabel.anchors.centerY)
//        editDomainButton.anchors.trailing.spacing(16, to: addNewDomainButton.anchors.leading)
        
        addTableView(customBlockedDomainsTableView, layout: { tableView in
            tableView.anchors.top.marginsPin()
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
            tableView.anchors.bottom.safeAreaPin()
        })
        
        customBlockedDomainsTableView.deselectsCellsAutomatically = true

        reloadCustomBlockedDomains()
    }
}

private extension CustomListsViewController {
    
    func reloadCustomBlockedLists() {
        customBlockedListsTableView.clear()
        customBlockedLists = {
            let lists = getBlockedLists().userBlockListsDefaults
            let sorted = lists.sorted(by: { $0.key < $1.key })
            return Array(sorted.map(\.value))
        }()
        createCustomBlockedListsRows()
        customBlockedListsTableView.reloadData()
    }
    
    func reloadCustomBlockedDomains() {
        customBlockedDomainsTableView.clear()
        customBlockedDomains = {
            let domains = getUserBlockedDomains()
            return domains.sorted(by: { $0.key < $1.key }).map { (key, value) -> (String, Bool) in
                if let status = value as? NSNumber {
                    return (key, status.boolValue)
                } else {
                    return (key, false)
                }
            }
        }()
        createCustomBlockedDomainsRows()
        customBlockedDomainsTableView.reloadData()
    }
    
    func saveNewList(userEnteredListName: String) {
        didMakeChange = true
        DDLogInfo("Adding custom list - \(userEnteredListName)")
        addBlockedList(listName: userEnteredListName)
        reloadCustomBlockedLists()
    }
    
    func saveNewDomain(userEnteredDomainName: String) {
        let validation = DomainNameValidator.validate(userEnteredDomainName)
        
        switch validation {
        case .valid:
            didMakeChange = true
            
            DDLogInfo("Adding custom domain - \(userEnteredDomainName)")
            addUserBlockedDomain(domain: userEnteredDomainName.lowercased())
            reloadCustomBlockedDomains()
        case .notValid(let reason):
            DDLogWarn("Custom domain is not valid - \(userEnteredDomainName), reason - \(reason)")
//            showPopupDialog(
//                title: NSLocalizedString("Invalid domain", comment: ""),
//                message: "\"\(userEnteredDomainName)\"" + NSLocalizedString(" is not a valid entry. Please only enter the host of the domain you want to block. For example, \"google.com\" without \"https://\"", comment: ""),
//                acceptButton: NSLocalizedString("Okay", comment: "")
//            )
        }
    }
    
    func createCustomBlockedListsRows() {
        let tableView = customBlockedListsTableView
        let emptyList = emptyListsView
        let lockedList = lockedListsView
        
        if UserDefaults.hasSeenAdvancedPaywall || UserDefaults.hasSeenAnonymousPaywall || UserDefaults.hasSeenUniversalPaywall {
            addNewListButton.isEnabled = true
            if customBlockedLists.count == 0 {
                tableView.addRow { (contentView) in
                    contentView.addSubview(emptyList)
                    emptyListsView.anchors.edges.pin()
                }.onSelect {
                    self.addList()
                }
            }
        } else {
            tableView.addRow { (contentView) in
                contentView.addSubview(lockedList)
                lockedList.anchors.edges.pin()
            }.onSelect {
                let vc = VPNPaywallViewController()
                self.present(vc, animated: true)
            }
        }
        
        for list in customBlockedLists {
            let blockListView = BlockListView()
            blockListView.contents = .listsBlocked(list)
            
            let cell = tableView.addRow { (contentView) in
                contentView.addSubview(blockListView)
                blockListView.anchors.edges.pin()
            }.onSelect { [unowned self] in
                self.didMakeChange = true
                let vc = ListSettingsViewController()
                vc.listName = list.name
                vc.didMakeChange = list.enabled
//                vc.blockListVC = self
                navigationController?.pushViewController(vc, animated: true)
            }.onSwipeToDelete { [unowned self] in
                self.didMakeChange = true
                deleteList(list: list.name)
                DDLogInfo("Deleting custom list - \(list.name)")
            }
//            cell.accessoryType = .disclosureIndicator
        }
    }
    
    func createCustomBlockedDomainsRows() {
        let tableView = customBlockedDomainsTableView
        let emptyDomains = emptyDomainsView
        if customBlockedDomains.count == 0 {
            tableView.addRow { (contentView) in
                contentView.addSubview(emptyDomains)
                emptyDomains.anchors.edges.pin()
            }.onSelect { [unowned self] in
                self.addDomain()
            }
        }

        for (domain, isEnabled) in customBlockedDomains {
            var currentEnabledStatus = isEnabled
            let blockListView = BlockListView()
            blockListView.contents = .userBlocked(domain: domain, isEnabled: isEnabled)
            
            tableView.addRow { (contentView) in
                contentView.addSubview(blockListView)
                blockListView.anchors.edges.pin()
            }.onSelect { [unowned blockListView, unowned self] in
                self.didMakeChange = true
                currentEnabledStatus.toggle()
                blockListView.contents = .userBlocked(domain: domain, isEnabled: currentEnabledStatus)
                setUserBlockedDomain(domain: domain, enabled: currentEnabledStatus)
            }.onSwipeToDelete { [unowned self] in
                self.didMakeChange = true
                deleteUserBlockedDomain(domain: domain)
                DDLogInfo("Deleting custom domain - \(domain)")
            }
        }
    }
    
    @objc func addList() {
        
        let tableView = customBlockedListsTableView

        let alertController = UIAlertController(title: "Create New List", message: nil, preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                guard let self else { return }
                self.saveNewList(userEnteredListName: text)
//                if !getBlockedLists().isEmpty {
//                    tableView.clear()
//                }
                self.reloadCustomBlockedLists()
                self.listsSubmenuView.isHidden = true
            }
        }
        
        saveAction.isEnabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (_) in
            guard let self else { return }
            self.listsSubmenuView.isHidden = true
        }
        
        alertController.addTextField { (textField) in
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
        present(alertController, animated: true, completion: nil)
    }
    
    func deleteList(list: String) {
        
        let alert = UIAlertController(title: NSLocalizedString("Delete List?", comment: ""),
                                      message: NSLocalizedString("Are you sure you want to remove this list?", comment: ""),
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("No, Return", comment: ""),
                                      style: .default,
                                      handler: { [weak self] (_) in
            guard let self else { return }
            self.reloadCustomBlockedLists()
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes, Delete", comment: ""),
                                      style: .destructive,
                                      handler: { [weak self] (_) in
            guard let self else { return }
            deleteBlockedList(listName: list)
            self.customBlockedListsTableView.clear()
            self.reloadCustomBlockedLists()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func showSubmenu() {
        listsSubmenuView.isHidden = false
    }
    
    @objc func dismissView() {
        listsSubmenuView.isHidden = true
    }
    
    @objc func importBlockList() {
        listsSubmenuView.isHidden = true
        let vc = ImportBlockListViewController()
        vc.importCompletion = { [unowned self] in
                self.reloadCustomBlockedLists()
                self.showSuccessImportAlert()
        }
        
        navigationController?.present(vc, animated: true)
    }
    
    @objc func addDomain() {
        let tableView = customBlockedDomainsTableView
        
        let alertController = UIAlertController(title: NSLocalizedString("Add a Domain to Block", comment: ""),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                guard let self else { return }
                self.saveNewDomain(userEnteredDomainName: text)
                if !getUserBlockedDomains().isEmpty {
                    tableView.clear()
                }
                
                self.reloadCustomBlockedDomains()
                self.editDomainButton.isHidden = false
            }
        }
        
        saveAction.isEnabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.keyboardType = .URL
            textField.placeholder = "domain-to-block"
        }
        
        NotificationCenter.default.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: alertController.textFields?.first,
            queue: .main) { (notification) -> Void in
                guard let textFieldText = alertController.textFields?.first?.text else { return }
                saveAction.isEnabled = textFieldText.isValid(.domainName) && !textFieldText.isEmpty
            }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func editDomains() {
        if !customBlockedDomains.isEmpty {
            let vc = EditDomainsViewController()
            vc.updateCompletion = { [weak self] in
                self?.reloadCustomBlockedDomains()
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func showSuccessImportAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Success!", comment: ""),
                                      message: NSLocalizedString("The list has been imported successfully. You can start blocking the list's domains", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""),
                                      style: .default,
                                      handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showErrorAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                      message: NSLocalizedString("Unable to import the list. Please try again or contact support for assistance", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""),
                                      style: .default,
                                      handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
