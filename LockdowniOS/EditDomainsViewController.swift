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
    
    var customBlockedDomains: [(String, Bool)] = []
    var selectedBlockedDomains: [(String, Bool)] = []
    
    private var titleName = NSLocalizedString("Edit Domains", comment: "")
    
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.titleLabel.text = NSLocalizedString(titleName, comment: "")
        view.leftNavButton.setTitle(NSLocalizedString("CLOSE", comment: ""), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
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
            var checkedStatus = status
            let blockListView = EditDomainsCell()
            blockListView.contents = .userBlocked(domain: domain, isUnselected: status)
            
            let cell = tableView.addRow { (contentView) in
                contentView.addSubview(blockListView)
                blockListView.anchors.edges.pin()
            }.onSelect { [unowned blockListView] in
                self.didMakeChange = true
                checkedStatus.toggle()
                blockListView.contents = .userBlocked(domain: domain, isUnselected: checkedStatus)
                
                self.bottomMenu.middleButton.setTitleColor(.tunnelsBlue, for: .normal)
                self.bottomMenu.rightButton.setTitleColor(.red, for: .normal)
                // TODO: - move domains to list

            }
            
            cell.accessoryType = .none
        }
    }
    
    @objc func closeButtonClicked() {
        dismiss(animated: true)
    }
    
    @objc func selectAllddDomains() {
        let tableView = customBlockedDomainsTableView
        tableView.reloadData()
    }
    
    @objc func moveToList() {
//        var arr: [(String, Bool)] = []
//        arr = selectedBlockedDomains.filter { (_, checked) in
//            checked == true
//        }
//        print(arr)
    }
    
    @objc func deleteDomains() {
        let alert = UIAlertController(title: NSLocalizedString("Delete Entries?", comment: ""),
                                      message: NSLocalizedString("Are you sure you want to remove these domains?", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("No, Return", comment: ""),
                                      style: UIAlertAction.Style.default,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes, Delete", comment: ""),
                                      style: UIAlertAction.Style.destructive,
                                      handler: { [weak self] (_) in
            guard let self else { return }
            self.customBlockedDomainsTableView.clear()
            self.customBlockedDomainsTableView.reloadData()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
