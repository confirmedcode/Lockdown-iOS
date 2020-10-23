//
//  LockdownViewController.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

class BlockListViewController: BaseViewController {
    
    var didMakeChange = false
    
    var lockdownBlockLists: [LockdownGroup] = []
    var userBlockedDomains: [(String, Bool)] = []
    
    let blockListsTableView = StaticTableView()
    let customBlocksTableView = StaticTableView()
    
    enum Page: CaseIterable {
        case blockLists
        case custom
        
        var localizedTitle: String {
            switch self {
            case .blockLists:
                return NSLocalizedString("Block Lists", comment: "")
            case .custom:
                return NSLocalizedString("Custom", comment: "")
            }
        }
    }
    
    let segmented = UISegmentedControl(items: Page.allCases.map(\.localizedTitle))
    let explanationLabel = UILabel()

    let blockListAddView = BlockListAddView()
    var addDomainTextField: UITextField {
        return blockListAddView.textField
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let customNavigationView = CustomNavigationView()
        customNavigationView.title = NSLocalizedString("Configure Blocking", comment: "")
        customNavigationView.buttonTitle = NSLocalizedString("SAVE", comment: "")
        customNavigationView.onButtonPressed { [unowned self] in
            self.save()
        }
        view.addSubview(customNavigationView)
        customNavigationView.anchors.leading.pin()
        customNavigationView.anchors.trailing.pin()
        customNavigationView.anchors.top.safeAreaPin()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        do {
            explanationLabel.font = fontRegular14
            explanationLabel.numberOfLines = 0
            explanationLabel.text = NSLocalizedString("Block all your apps from connecting to the domains and sites below. For your convenience, Lockdown also has pre-configured suggestions.", comment: "")
            
            view.addSubview(explanationLabel)
            explanationLabel.anchors.top.spacing(0, to: customNavigationView.anchors.bottom)
            explanationLabel.anchors.leading.readableContentPin(inset: 3)
            explanationLabel.anchors.trailing.readableContentPin(inset: 3)
        }
        
        do {
            view.addSubview(segmented)
            segmented.selectedSegmentIndex = 0
            segmented.anchors.top.spacing(12, to: explanationLabel.anchors.bottom)
            segmented.anchors.leading.readableContentPin()
            segmented.anchors.trailing.readableContentPin()
            segmented.setTitleTextAttributes([.font: fontMedium14], for: .normal)
            if #available(iOS 13.0, *) {
                segmented.selectedSegmentTintColor = .tunnelsBlue
                segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            }
            
            segmented.addTarget(self, action: #selector(segmentedControlDidChangeValue), for: .valueChanged)
        }
        
        do {
            addDomainTextField.addTarget(self, action: #selector(textFieldDidEndOnExit), for: .editingDidEndOnExit)
        }
        
        do {
            addTableView(blockListsTableView, layout: { tableView in
                tableView.anchors.top.spacing(8, to: segmented.anchors.bottom)
                tableView.anchors.leading.pin()
                tableView.anchors.trailing.pin()
                tableView.anchors.bottom.pin()
            })
            reloadBlockLists()
            
            addTableView(customBlocksTableView, layout: { tableView in
                tableView.anchors.top.spacing(8, to: segmented.anchors.bottom)
                tableView.anchors.leading.pin()
                tableView.anchors.trailing.pin()
                tableView.anchors.bottom.pin()
            })
            customBlocksTableView.deselectsCellsAutomatically = true
            reloadUserBlockedDomains()
            
            transition(toPage: .blockLists)
        }
    }
    
    func reloadBlockLists() {
        blockListsTableView.clear()
        lockdownBlockLists = {
            let domains = getLockdownBlockedDomains().lockdownDefaults
            let sorted = domains.sorted(by: { $0.key < $1.key })
            return Array(sorted.map(\.value))
        }()
        createBlockListsRows()
        blockListsTableView.reloadData()
    }
    
    func reloadUserBlockedDomains() {
        customBlocksTableView.clear()
        userBlockedDomains = {
            let domains = getUserBlockedDomains()
            return domains.sorted(by: { $0.key < $1.key }).map { (key, value) -> (String, Bool) in
                if let status = value as? NSNumber {
                    return (key, status.boolValue)
                } else {
                    return (key, false)
                }
            }
        }()
        createCustomBlocksRows()
        customBlocksTableView.reloadData()
    }
    
    func createBlockListsRows() {
        let tableView = blockListsTableView
        
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
    
    func createCustomBlocksRows() {
        let tableView = customBlocksTableView
        
        tableView.addRow { (contentView) in
            contentView.addSubview(blockListAddView)
            blockListAddView.anchors.edges.pin()
        }
        
        for (domain, isEnabled) in userBlockedDomains {
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
    
    @objc
    func segmentedControlDidChangeValue() {
        let page = Page.allCases[segmented.selectedSegmentIndex]
        transition(toPage: page)
    }
    
    func transition(toPage page: Page) {
        dismissKeyboard()
        
        switch page {
        case .blockLists:
            customBlocksTableView.isHidden = true
            blockListsTableView.isHidden = false
        case .custom:
            customBlocksTableView.isHidden = false
            blockListsTableView.isHidden = true
        }
    }
    
    @objc
    func textFieldDidEndOnExit(textField: UITextField) {
        dismissKeyboard()
        
        guard let text = textField.text else {
            DDLogError("Text is empty on add domain text field")
            return
        }
        
        saveNewDomain(userEnteredDomainName: text)
    }
    
    func saveNewDomain(userEnteredDomainName: String) {
        let validation = DomainNameValidator.validate(userEnteredDomainName)
        
        switch validation {
        case .valid:
            didMakeChange = true
            
            DDLogInfo("Adding custom domain - \(userEnteredDomainName)")
            addUserBlockedDomain(domain: userEnteredDomainName.lowercased())
            addDomainTextField.text = ""
            reloadUserBlockedDomains()
        case .notValid(let reason):
            DDLogWarn("Custom domain is not valid - \(userEnteredDomainName), reason - \(reason)")
            showPopupDialog(
                title: NSLocalizedString("Invalid domain", comment: ""),
                message: "\"\(userEnteredDomainName)\"" + NSLocalizedString(" is not a valid entry. Please only enter the host of the domain you want to block. For example, \"google.com\" without \"https://\"", comment: ""),
                acceptButton: NSLocalizedString("Okay", comment: "")
            ) {
                self.addDomainTextField.becomeFirstResponder()
            }
        }
    }
    
    func save() {
        self.dismiss(animated: true, completion: {
            if (self.didMakeChange == true) {
                if getIsCombinedBlockListEmpty() {
                    FirewallController.shared.setEnabled(false, isUserExplicitToggle: true)
                } else if (FirewallController.shared.status() == .connected) {
                    FirewallController.shared.restart()
                }
            }
        })
    }
}
