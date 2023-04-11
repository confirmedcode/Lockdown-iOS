//
//  LockdownViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

final class BlockListViewController: BaseViewController {
    
    // MARK: - Properties
    var didMakeChange = false
    
    var lockdownBlockLists: [LockdownGroup] = []
    var customBlockedDomains: [(String, Bool)] = []

    // TODO: - change data structure [[userListBlockedDomains], Bool]
    var customBlockedLists: [(String, Bool)] = []
    
    let curatedBlockedDomainsTableView = StaticTableView()
    let customBlockedListsTableView = StaticTableView()
    let customBlockedDomainsTableView = StaticTableView()
    
    private lazy var listsSubmenuView: ListsSubmenuView = {
        let view = ListsSubmenuView()
        view.createNewListButton.addTarget(self, action: #selector(addList), for: .touchUpInside)
        view.importBlockListButton.addTarget(self, action: #selector(importBlockList), for: .touchUpInside)
        return view
    }()
    
    private lazy var customNavigationView: CustomNavigationView = {
        let view = CustomNavigationView()
        view.title = NSLocalizedString("Configure Blocking", comment: "")
        view.buttonTitle = NSLocalizedString("CLOSE", comment: "")
        view.onButtonPressed { [unowned self] in
            self.close()
        }
        return view
    }()
    
    enum Page: CaseIterable {
        case curated
        case custom
        
        var localizedTitle: String {
            switch self {
            case .curated:
                return NSLocalizedString("Curated", comment: "")
            case .custom:
                return NSLocalizedString("Custom", comment: "")
            }
        }
    }
    
    private lazy var segmented: UISegmentedControl = {
        let view = UISegmentedControl(items: Page.allCases.map(\.localizedTitle))
        view.selectedSegmentIndex = 0
        view.setTitleTextAttributes([.font: fontMedium14], for: .normal)
        view.selectedSegmentTintColor = .tunnelsBlue
        view.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        view.addTarget(self, action: #selector(segmentedControlDidChangeValue), for: .valueChanged)
        return view
    }()
    
    private let paragraphLabel: UILabel = {
        let view = UILabel()
        view.font = fontRegular14
        view.numberOfLines = 0
        view.text = NSLocalizedString("Block all your apps from connecting to the domains and sites below. For your convenience, Lockdown also has pre-configured suggestions.", comment: "")
        return view
    }()
    
    private lazy var addNewListButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold, scale: .large)
        button.tintColor = .tunnelsBlue
        button.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig), for: .normal)
        button.addTarget(self, action: #selector(showSubmenu), for: .touchUpInside)
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
        configure()
        configureCuratedBlockedDomainsTableView()
        configureCustomBlockedListsTableView()
        configureCustomBlockedDomainsTableView()
    }
    
    private func configure() {
        view.addSubview(customNavigationView)
        customNavigationView.anchors.leading.pin()
        customNavigationView.anchors.trailing.pin()
        customNavigationView.anchors.top.safeAreaPin()
        
        view.addSubview(paragraphLabel)
        paragraphLabel.anchors.top.spacing(0, to: customNavigationView.anchors.bottom)
        paragraphLabel.anchors.leading.readableContentPin(inset: 3)
        paragraphLabel.anchors.trailing.readableContentPin(inset: 3)
        
        view.addSubview(segmented)
        segmented.anchors.top.spacing(12, to: paragraphLabel.anchors.bottom)
        segmented.anchors.leading.readableContentPin()
        segmented.anchors.trailing.readableContentPin()
    }
    
    private func configureCuratedBlockedDomainsTableView() {
        addTableView(curatedBlockedDomainsTableView, layout: { tableView in
            tableView.anchors.top.spacing(8, to: segmented.anchors.bottom)
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
        })
        
        reloadCuratedBlockDomains()
        transition(toPage: .curated)
    }
    
    private func configureCustomBlockedListsTableView() {
        
        view.addSubview(listsLabel)
        listsLabel.anchors.top.spacing(24, to: segmented.anchors.bottom)
        listsLabel.anchors.leading.marginsPin()
        
        view.addSubview(addNewListButton)
        addNewListButton.anchors.centerY.equal(listsLabel.anchors.centerY)
        addNewListButton.anchors.trailing.marginsPin()
        
        addTableView(customBlockedListsTableView, layout: { tableView in
            tableView.anchors.top.spacing(0, to: listsLabel.anchors.bottom)
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
        })
        
        view.addSubview(listsSubmenuView)
        listsSubmenuView.anchors.trailing.marginsPin()
        listsSubmenuView.anchors.top.spacing(60, to: paragraphLabel.anchors.bottom)
        
        customBlockedListsTableView.deselectsCellsAutomatically = true
        
        reloadCustomBlockedLists()
    }
    
    private func configureCustomBlockedDomainsTableView() {
        
        view.addSubview(domainsLabel)
        domainsLabel.anchors.top.spacing(16, to: customBlockedListsTableView.anchors.bottom)
        domainsLabel.anchors.leading.marginsPin()
        
        view.addSubview(addNewDomainButton)
        addNewDomainButton.anchors.centerY.equal(domainsLabel.anchors.centerY)
        addNewDomainButton.anchors.trailing.marginsPin()
        
        view.addSubview(editDomainButton)
        editDomainButton.anchors.centerY.equal(domainsLabel.anchors.centerY)
        editDomainButton.anchors.trailing.spacing(16, to: addNewDomainButton.anchors.leading)
        
        addTableView(customBlockedDomainsTableView, layout: { tableView in
            tableView.anchors.top.spacing(0, to: domainsLabel.anchors.bottom)
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
        })
        
        customBlockedDomainsTableView.deselectsCellsAutomatically = true

        reloadCustomBlockedDomains()
    }
    
    // Curated lists
    func reloadCuratedBlockDomains() {
        curatedBlockedDomainsTableView.clear()
        lockdownBlockLists = {
            let domains = getLockdownBlockedDomains().lockdownDefaults
            let sorted = domains.sorted(by: { $0.key < $1.key })
            return Array(sorted.map(\.value))
        }()
        createCuratedBlockedDomainsRows()
        curatedBlockedDomainsTableView.reloadData()
    }
    
    func reloadCustomBlockedLists() {
        customBlockedListsTableView.clear()
        customBlockedLists = {
            let lists = getUserBlockedList()
            return lists.sorted(by: { $0.key < $1.key }).map { (key, value) -> (String, Bool) in
                if let status = value as? NSNumber {
                    return (key, status.boolValue)
                } else {
                    return (key, false)
                }
            }
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
    
    // Curated Lists
    func createCuratedBlockedDomainsRows() {
        let tableView = curatedBlockedDomainsTableView
        
        for lockdownGroup in lockdownBlockLists {
            
            let cell = tableView.addRow { (contentView) in
                let blockListView = BlockListView()
                blockListView.contents = .lockdownGroup(lockdownGroup)
                contentView.addSubview(blockListView)
                blockListView.anchors.edges.pin()
            }.onSelect { [unowned self] in
                let storyboard = UIStoryboard.main
                let target = storyboard.instantiate(BlockListGroupViewController.self)
                target.lockdownGroup = lockdownGroup
                target.blockListVC = self
                self.navigationController?.pushViewController(target, animated: true)
            }
            
            cell.accessoryType = .disclosureIndicator
        }
    }
    
    @objc
    func segmentedControlDidChangeValue() {
        let page = Page.allCases[segmented.selectedSegmentIndex]
        transition(toPage: page)
    }
    
    func transition(toPage page: Page) {
        
        switch page {
        case .curated:
            customBlockedDomainsTableView.isHidden = true
            customBlockedListsTableView.isHidden = true
            curatedBlockedDomainsTableView.isHidden = false
            listsLabel.isHidden = true
            addNewListButton.isHidden = true
            listsSubmenuView.isHidden = true
            addNewDomainButton.isHidden = true
            domainsLabel.isHidden = true
            editDomainButton.isHidden = true
        case .custom:
            customBlockedListsTableView.isHidden = false
            customBlockedDomainsTableView.isHidden = false
            curatedBlockedDomainsTableView.isHidden = true
            listsLabel.isHidden = false
            addNewListButton.isHidden = false
            addNewDomainButton.isHidden = false
            domainsLabel.isHidden = false
            editDomainButton.isHidden = false
        }
    }
    
    func saveNewList(userEnteredListName: String) {
        DDLogInfo("Adding custom list - \(userEnteredListName)")
        addUserBlockedList(list: userEnteredListName.lowercased())
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
            showPopupDialog(
                title: NSLocalizedString("Invalid domain", comment: ""),
                message: "\"\(userEnteredDomainName)\"" + NSLocalizedString(" is not a valid entry. Please only enter the host of the domain you want to block. For example, \"google.com\" without \"https://\"", comment: ""),
                acceptButton: NSLocalizedString("Okay", comment: "")
            )
        }
    }
}
// MARK: - Functions
extension BlockListViewController {
    
    func createCustomBlockedListsRows() {
        let tableView = customBlockedListsTableView
        let emptyList = emptyListsView
        
        if customBlockedLists.count == 0 {
            tableView.addRow { (contentView) in
                contentView.addSubview(emptyList)
                emptyListsView.anchors.edges.pin()
            }.onSelect {
                self.addList()
            }
        }
        
        for (list, status) in customBlockedLists {
//            var currentEnabledStatus = status
            let blockListView = BlockListView()
            blockListView.contents = .listsBlocked(listName: list, isEnabled: status)
            
            let cell = tableView.addRow { (contentView) in
                contentView.addSubview(blockListView)
                blockListView.anchors.edges.pin()
            }.onSelect { [unowned blockListView, unowned self] in
                self.didMakeChange = true
                let storyboard = UIStoryboard.main
//                let target = storyboard.instantiate(BlockListGroupViewController.self)
//                target.lockdownGroup = lockdownGroup
//                target.blockListVC = self
//                self.navigationController?.pushViewController(target, animated: true)
//                currentEnabledStatus.toggle()
//                blockListView.contents = .listsBlocked(listName: list, isEnabled: currentEnabledStatus)
//                setUserBlockedList(list: list, enabled: currentEnabledStatus)
            }.onSwipeToDelete { [unowned self] in
                self.didMakeChange = true
                deleteList(list: list)
                DDLogInfo("Deleting custom list - \(list)")
            }
            cell.accessoryType = .disclosureIndicator
        }
    }
    
    // Custom Domains
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
    
    func close() {
        dismiss(animated: true, completion: { [weak self] in
            guard let self else { return }
            if (self.didMakeChange == true) {
                if getIsCombinedBlockListEmpty() {
                    FirewallController.shared.setEnabled(false, isUserExplicitToggle: true)
                } else if (FirewallController.shared.status() == .connected) {
                    FirewallController.shared.restart()
                }
            }
        })
    }
    
    @objc func addList() {
        let tableView = customBlockedListsTableView
        let alertController = UIAlertController(title: "Create New List", message: nil, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                guard let self else { return }
                self.saveNewList(userEnteredListName: text)
                if !getUserBlockedList().isEmpty {
                    tableView.clear()
                }
                self.reloadCustomBlockedLists()
                self.listsSubmenuView.isHidden = true
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (_) in
            guard let self else { return }
            self.listsSubmenuView.isHidden = true
        }
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("List Name", comment: "")
        }
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func deleteList(list: String) {
        print("deleteDomains btn pressed ....")
        let alert = UIAlertController(title: NSLocalizedString("Delete List?", comment: ""),
                                      message: NSLocalizedString("Are you sure you want to remove this list?", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("No, Return", comment: ""),
                                      style: UIAlertAction.Style.default,
                                      handler: { [weak self] (_) in
            guard let self else { return }
            self.reloadCustomBlockedLists()
            print("Return")
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes, Delete", comment: ""),
                                      style: UIAlertAction.Style.destructive,
                                      handler: { [weak self] (_) in
            guard let self else { return }
            deleteUserBlockedList(list: list)
            self.customBlockedListsTableView.clear()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func showSubmenu() {
        listsSubmenuView.isHidden = false
    }
    
    @objc func dismissView() {
        listsSubmenuView.isHidden = true
    }
    
    @objc func importBlockList() {
        listsSubmenuView.isHidden = true
        print("importBlockList ....")
    }
    
    @objc func addDomain() {
        print("Alert is on")
        
        let tableView = customBlockedDomainsTableView
        
        let alertController = UIAlertController(title: "Add a Domain to Block", message: nil, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                guard let self else { return }
                self.saveNewDomain(userEnteredDomainName: text)
                if !getUserBlockedDomains().isEmpty {
                    tableView.clear()
                }
                
                self.reloadCustomBlockedDomains()
                print("Domain==>" + text + "added")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alertController.addTextField { (textField) in
            textField.placeholder = "domain-to-block URL"
        }
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func editDomains() {
        print("editDomains .....")
    }
}
