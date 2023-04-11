//
//  EditDomainsViewController.swift
//  LockdownSandbox
//
//  Created by Aliaksandr Dvoineu on 4.04.23.
//

import UIKit

final class EditDomainsViewController: UIViewController {
    
    // MARK: - Properties
    private var didMakeChange = false
    
    private var customBlockedDomains: [(String, Bool)] = []
    
    private var titleName = NSLocalizedString("Edit Domains", comment: "")
    
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.titleLabel.text = NSLocalizedString(titleName, comment: "")
        view.leftNavButton.setTitle(NSLocalizedString("CLOSE", comment: ""), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        view.rightNavButton.setTitle(NSLocalizedString("DONE", comment: ""), for: .normal)
        view.rightNavButton.titleLabel?.font = fontBold13
        view.rightNavButton.tintColor = .gray
        view.rightNavButton.addTarget(self, action: #selector(doneButtonClicked), for: .touchUpInside)
        return view
    }()
    
    private lazy var domainsLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Domains", comment: "")
        label.textColor = .label
        label.font = fontBold18
        return label
    }()
    
    private lazy var bottomMenu: BottomMenu = {
        let view = BottomMenu()
        view.leftButton.addTarget(self, action: #selector(selectAllddDomains), for: .touchUpInside)
        view.middleButton.addTarget(self, action: #selector(moveToList), for: .touchUpInside)
        view.rightButton.addTarget(self, action: #selector(deleteDomains), for: .touchUpInside)
        return view
    }()
    
    private let customBlockedDomainsTableView = CustomTableView()
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        configureUI()
        configureDomainsTableView()
    }
    
    // MARK: - Configure UI
    private func configureUI() {
        view.addSubview(navigationView)
        navigationView.anchors.leading.pin()
        navigationView.anchors.trailing.pin()
        navigationView.anchors.top.safeAreaPin()
        
        view.addSubview(bottomMenu)
        bottomMenu.anchors.bottom.pin()
        bottomMenu.anchors.height.equal(60)
        bottomMenu.anchors.leading.marginsPin()
        bottomMenu.anchors.trailing.marginsPin()
    }
    
    private func configureDomainsTableView() {
        addTableView(customBlockedDomainsTableView) { tableView in
            tableView.anchors.top.spacing(16, to: navigationView.anchors.bottom)
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
        }
        
        reloadCustomBlockedDomains()
    }
}

// MARK: - Functions
private extension EditDomainsViewController {
    
    func reloadCustomBlockedDomains() {
        customBlockedDomainsTableView.clear()
        customBlockedDomains = {
            let lists = getUserBlockedDomains()
            return lists.sorted(by: { $0.key < $1.key }).map { (key, value) -> (String, Bool) in
                if let status = value as? NSNumber {
                    return (key, status.boolValue)
                } else {
                    return (key, false)
                }
            }
        }()
        
        createUserBlockedDomainsRows()
        customBlockedDomainsTableView.reloadData()
    }
    
    func createUserBlockedDomainsRows() {
        let tableView = customBlockedDomainsTableView
        tableView.separatorStyle = .singleLine
        
        let tableTitle = domainsLabel
        
        tableView.addHeader { view in
            view.addSubview(tableTitle)
            tableTitle.anchors.top.marginsPin()
            tableTitle.anchors.leading.marginsPin()
            tableTitle.anchors.bottom.marginsPin()
        }
        
        for (domain, status) in customBlockedDomains {
            let blockListView = EditDomainsCell()
//            var statusChecked = status.toggle()
            blockListView.contents = .userBlocked(domain: domain, isSelected: status)
            
            let cell = tableView.addRow { (contentView) in
                contentView.addSubview(blockListView)
                blockListView.anchors.edges.pin()
            }.onSelect { [unowned blockListView] in
                self.didMakeChange = true
                // TODO: - move domains to list

            }
            
            cell.accessoryType = .none
        }
    }
    
    @objc func closeButtonClicked() {
        print("Close btn pressed ....")
        dismiss(animated: true)
    }
    
    @objc func doneButtonClicked() {
        print("doneButtonTapped btn pressed ....")
    }
    
    @objc func selectAllddDomains() {
//        let cell = CheckboxTableViewCell()
//        cell.isChecked = false
//        tableView.reloadData()
        print("selectAllddDomains btn pressed ....")
    }
    
    @objc func moveToList() {
        print("moveToList btn pressed ....")
    }
    
    @objc func deleteDomains() {
        print("deleteDomains btn pressed ....")
        let alert = UIAlertController(title: NSLocalizedString("Delete Entries?", comment: ""),
                                      message: NSLocalizedString("Are you sure you want to remove these domains?", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("No, Return", comment: ""),
                                      style: UIAlertAction.Style.default,
                                      handler: { _ in
            print("Return")
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes, Delete", comment: ""),
                                      style: UIAlertAction.Style.destructive,
                                      handler: {(_: UIAlertAction!) in
            // Delete action
            //  tableView.clear()
            //  tableView.reloadData()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
