//
//  MoveToLsisViewController.swift
//  LockdownSandbox
//
//  Created by Aliaksandr Dvoineu on 28.04.23.
//

import UIKit
import CocoaLumberjackSwift

final class MoveToListViewController: UIViewController {
    
    // MARK: - Properties
    private var didMakeChange = false
    
    var selectedDomains: Dictionary<String, Bool> = [:] {
        didSet {
            if selectedDomains.count == 1 {
                numberOfdomains.text = "\(selectedDomains.count) " + NSLocalizedString("domain", comment: "")
            } else {
                numberOfdomains.text = "\(selectedDomains.count) " + NSLocalizedString("domains", comment: "")
            }
            domainsList.text = selectedDomains.map(\.0).joined(separator: ", ")
        }
    }
    
    private var customBlockedLists: [UserBlockListsGroup] = []
    
    private let customBlockedListsTableView = CustomTableView()
    
    private lazy var descriptionText: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Move selected Domains to an existing or a new list", comment: "")
        label.textColor = .label
        label.font = fontRegular14
        label.textColor = .gray
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.titleLabel.text = NSLocalizedString("Move to list", comment: "")
        view.leftNavButton.setTitle(NSLocalizedString("BACK", comment: ""), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        view.rightNavButton.setTitle(NSLocalizedString("CANCEL", comment: ""), for: .normal)
        view.rightNavButton.addTarget(self, action: #selector(cancelButtonClicked), for: .touchUpInside)
        return view
    }()
    
    private lazy var domainImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "globe")
        image.contentMode = .scaleAspectFit
        image.tintColor = .gray
        return image
    }()
    
    private lazy var domainsList: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontRegular14
        label.textAlignment = .natural
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var numberOfdomains: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontBold13
        label.textAlignment = .natural
        return label
    }()
    
    private lazy var vstackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(domainsList)
        stackView.addArrangedSubview(numberOfdomains)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 3
        return stackView
    }()
    
    private lazy var hstackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(domainImage)
        stackView.addArrangedSubview(vstackView)
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.spacing = 8
        stackView.alignment = .top
        return stackView
    }()
    
    private lazy var addNewListButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .tunnelsBlue
        button.setTitle(NSLocalizedString("Add a new List", comment: ""), for: .normal)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(addNewList), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        configureUI()
        configureListsTableView()
    }
    
    // MARK: - Configure UI
    private func configureUI() {
        view.addSubview(descriptionText)
        descriptionText.anchors.leading.readableContentPin(inset: 12)
        descriptionText.anchors.trailing.readableContentPin(inset: 12)
        descriptionText.anchors.top.safeAreaPin()
        
        view.addSubview(navigationView)
        navigationView.anchors.top.spacing(8, to: descriptionText.anchors.bottom)
        navigationView.anchors.leading.pin()
        navigationView.anchors.trailing.pin()
        
        view.addSubview(hstackView)
        hstackView.anchors.top.spacing(12, to: navigationView.anchors.bottom)
        hstackView.anchors.leading.marginsPin()
        hstackView.anchors.trailing.marginsPin()
    }
    
    private func configureListsTableView() {
        addTableView(customBlockedListsTableView) { tableView in
            tableView.anchors.top.spacing(16, to: hstackView.anchors.bottom)
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
        }
        
        reloadCustomBlockedLists()
    }
}

// MARK: - Private functions
private extension MoveToListViewController {
    
    func reloadCustomBlockedLists() {
        customBlockedListsTableView.clear()
        customBlockedLists = {
            let lists = getBlockedLists().userBlockListsDefaults
            let sorted = lists.sorted(by: { $0.key < $1.key })
            return Array(sorted.map(\.value))
        }()
        
        createUserBlockedListsRows()
        customBlockedListsTableView.reloadData()
    }
    
    func createUserBlockedListsRows() {
        let userBlockedLists = getBlockedLists().userBlockListsDefaults
        
        
        let tableView = customBlockedListsTableView
        tableView.separatorStyle = .singleLine
        
        let plusButton = UIButton(type: .system)
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.tintColor = .tunnelsBlue
        
        tableView.addHeader { view in
            plusButton.addTarget(self, action: #selector(addNewList), for: .touchUpInside)
            view.addSubview(plusButton)
            plusButton.anchors.top.marginsPin()
            plusButton.anchors.trailing.marginsPin()
            plusButton.anchors.bottom.marginsPin()
        }
        
        for list in customBlockedLists {
            let blockListView = BlockListView()
            blockListView.contents = .listsBlocked(list)
            
            let cell = tableView.addRow { (contentView) in
                contentView.addSubview(blockListView)
                blockListView.anchors.edges.pin()
            }.onSelect { [unowned self] in
                self.didMakeChange = true
                
                let blockedList = userBlockedLists[list.name]
                
                if let blockedList = blockedList {
                    for domain in self.selectedDomains.keys {
                        addDomainToBlockedList(domain: domain, for: blockedList.name)
                    }
                }
            }
            
            cell.accessoryType = .none
        }
    }
    
    func saveNewList(userEnteredListName: String) {
        DDLogInfo("Adding custom list - \(userEnteredListName)")
        addBlockedList(listName: userEnteredListName)
        reloadCustomBlockedLists()
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
    
    @objc func backButtonClicked() {
        dismiss(animated: true)
    }
    
    @objc func cancelButtonClicked() {
        dismiss(animated: true)
    }
    
    @objc func addNewList() {
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
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("List Name", comment: "")
        }
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
