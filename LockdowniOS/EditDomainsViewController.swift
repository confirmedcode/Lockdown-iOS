//
//  EditDomainsViewController.swift
//  LockdownSandbox
//
//  Created by Aliaksandr Dvoineu on 4.04.23.
//

import UIKit

final class EditDomainsViewController: UIViewController {
    
    // MARK: - Properties
    var updateCompletion: (() -> ())?
    
    private var didMakeChange = false
    
    private var checkedStatus = false
    
    var customBlockedDomains: [(String, Bool)] = []
    
    var selectedDomains: Dictionary<String, Bool> = [:] {
        didSet {
            if selectedDomains.filter({ $0.value == true }).count == 0 {
                bottomMenu.middleButton.isEnabled = false
                bottomMenu.rightButton.isEnabled = false
            } else {
                if UserDefaults.hasSeenAdvancedPaywall || UserDefaults.hasSeenAnonymousPaywall || UserDefaults.hasSeenUniversalPaywall {
                    bottomMenu.middleButton.isEnabled = true }
                bottomMenu.rightButton.isEnabled = true
            }
        }
    }
    
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        
        configureDomainsTableView()
        configureUI()
    }
    
    // MARK: - Configure UI
    private func configureUI() {
        
        view.addSubview(bottomMenu)
        bottomMenu.anchors.bottom.pin()
        bottomMenu.anchors.height.equal(60)
        bottomMenu.anchors.leading.pin()
        bottomMenu.anchors.trailing.pin()
    }
    
    private func configureDomainsTableView() {
        
        view.addSubview(navigationView)
        navigationView.anchors.leading.pin()
        navigationView.anchors.trailing.pin()
        navigationView.anchors.top.safeAreaPin()
        
        addTableView(customBlockedDomainsTableView) { tableView in
            tableView.anchors.top.spacing(24, to: navigationView.anchors.bottom)
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
            tableView.anchors.bottom.pin(inset: 60)
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
        
        for (domain, _) in customBlockedDomains {
            let blockListView = EditDomainsCell()
            blockListView.contents = .userBlocked(domain: domain, isSelected: checkedStatus)
            
            self.selectedDomains[domain] = checkedStatus
            let cell = tableView.addRow { (contentView) in
                contentView.addSubview(blockListView)
                blockListView.anchors.edges.pin()
                
            }.onSelect { [unowned blockListView, unowned self] in
                self.didMakeChange = true
                
                checkedStatus.toggle()
                blockListView.contents = .userBlocked(domain: domain, isSelected: checkedStatus)
                
                self.selectedDomains[domain] = checkedStatus
            }
            
            cell.accessoryType = .none
        }
    }
    
    @objc func closeButtonClicked() {
        
        updateCompletion?()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func selectAllddDomains() {
        checkedStatus = true
        reloadCustomBlockedDomains()
    }
    
    @objc func moveToList() {
        let sortedDomains = selectedDomains.filter({ $0.value == true })
        let vc = MoveToListViewController()
        vc.selectedDomains = sortedDomains
        vc.moveToListCompletion = { [unowned self] in
            self.reloadCustomBlockedDomains()
        }
        
        present(vc, animated: true)
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
            let sortedDomains = self.selectedDomains.filter({ $0.value == true })
            
            for domain in sortedDomains.keys {
                deleteUserBlockedDomain(domain: domain)
            }
            
            self.reloadCustomBlockedDomains()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
