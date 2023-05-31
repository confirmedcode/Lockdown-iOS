//
//  ListSettingsViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 28.03.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

final class ListSettingsViewController: UIViewController {
    
    // MARK: - Properties
    private var blockedList: UserBlockListsGroup?
    
    var listName = ""
    
    weak var blockListVC: BlockListViewController?
    
    var didMakeChange = false
    
    lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.titleLabel.text = "List Settings"
        view.leftNavButton.setTitle(NSLocalizedString("BACK", comment: ""), for: .normal)
        view.leftNavButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        view.rightNavButton.setTitle("...", for: .normal)
        view.rightNavButton.titleLabel?.font = fontBold18
        view.rightNavButton.addTarget(self, action: #selector(showSubmenu), for: .touchUpInside)
        return view
    }()
    
    private lazy var switchBlockingView: SwitchBlockingView = {
        let view = SwitchBlockingView()
        view.titleLabel.text = NSLocalizedString("Blocking", comment: "")
        view.switchView.addTarget(self, action: #selector(toggleBlocking), for: .valueChanged)
        return view
    }()
    
    private lazy var subMenu: ListsSubmenuView = {
        let view = ListsSubmenuView()
        view.topButton.setTitle(NSLocalizedString("Export List...", comment: ""), for: .normal)
        view.topButton.setImage(UIImage(named: "icn_export_folder"), for: .normal)
        view.topButton.addTarget(self, action: #selector(exportList), for: .touchUpInside)
        view.bottomButton.setTitle(NSLocalizedString("Delete List...", comment: ""), for: .normal)
        view.bottomButton.setImage(UIImage(named: "icn_trash"), for: .normal)
        view.bottomButton.addTarget(self, action: #selector(deleteList), for: .touchUpInside)
        return view
    }()
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        
        
        
//        if let list = blockedList {
//            list = getBlockedLists().userBlockListsDefaults[listName]
//            switchBlockingView.switchView.isOn = list.enabled
//        }
        
        configureUI()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let userBlockedLists = getBlockedLists().userBlockListsDefaults
        blockedList = userBlockedLists[listName]
        
        switchBlockingView.switchView.isOn = didMakeChange
    }
    
    // MARK: - Configure UI
    func configureUI() {
        view.addSubview(navigationView)
        navigationView.anchors.leading.pin()
        navigationView.anchors.trailing.pin()
        navigationView.anchors.top.safeAreaPin()
        
        view.addSubview(switchBlockingView)
        switchBlockingView.anchors.top.spacing(12, to: navigationView.anchors.bottom)
        switchBlockingView.anchors.leading.marginsPin()
        switchBlockingView.anchors.trailing.marginsPin()
        switchBlockingView.anchors.height.equal(40)
        
        addTableView(tableView) { tableview in
            tableView.anchors.top.spacing(20, to: switchBlockingView.anchors.bottom)
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
            tableView.anchors.bottom.pin()
        }
        
        view.addSubview(subMenu)
        subMenu.anchors.top.spacing(0, to: navigationView.anchors.bottom)
        subMenu.anchors.trailing.marginsPin()
        subMenu.isHidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideSubmenu))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func configureTableView() {
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 40
        
        tableView.register(ListBlockedTableViewCell.self, forCellReuseIdentifier: ListBlockedTableViewCell.identifier)
        tableView.register(DomainsBlockedTableViewCell.self, forCellReuseIdentifier: DomainsBlockedTableViewCell.identifier)
    }
}

extension ListSettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        
        let sectionName = UILabel()
        sectionName.font = fontBold13
        
        view.addSubview(sectionName)
        sectionName.anchors.top.marginsPin()
        sectionName.anchors.leading.marginsPin()
        sectionName.anchors.bottom.marginsPin()
        
        switch section {
        case 0:
            sectionName.text = NSLocalizedString("NAME", comment: "")
        case 1:
            sectionName.text = NSLocalizedString("DESCRIPTION", comment: "")
        case 2:
            sectionName.text = NSLocalizedString("DOMAINS", comment: "")
            let addButton = UIButton(type: .system)
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold, scale: .large)
            addButton.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig), for: .normal)
            addButton.tintColor = .tunnelsBlue
            addButton.addTarget(self, action: #selector(addDomain), for: .touchUpInside)
            
            view.addSubview(addButton)
            addButton.anchors.top.marginsPin()
            addButton.anchors.trailing.marginsPin()
            addButton.anchors.bottom.marginsPin()
        default: break
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfDomains = blockedList?.domains.count
        
        switch section {
        case 0, 1: return 1
        case 2: return numberOfDomains ?? 0
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ListBlockedTableViewCell.identifier, for: indexPath) as? ListBlockedTableViewCell else {
                return UITableViewCell()
            }
            cell.label.text = listName
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ListBlockedTableViewCell.identifier, for: indexPath) as? ListBlockedTableViewCell else {
                return UITableViewCell()
            }
            cell.label.text = blockedList?.description ?? "Description"
            return cell
        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: DomainsBlockedTableViewCell.identifier, for: indexPath) as? DomainsBlockedTableViewCell else {
                return UITableViewCell()
            }
            let domains: [String] = Array(blockedList!.domains)
            cell.label.text = domains[indexPath.row]
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            let vc = ListDetailViewController()
            vc.delegate = self
            vc.listName = listName
            navigationController?.pushViewController(vc, animated: true)
            
        case 1:
            let vc = ListDescriptionViewController()
            vc.delegate = self
            vc.listName = listName
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}

extension ListSettingsViewController: UITableViewDelegate {
    
}

// MARK: - Functions
extension ListSettingsViewController {
    
    @objc func backButtonClicked() {
        navigationController?.popViewController(animated: true)
    }
    
    func saveNewDomain(userEnteredDomainName: String) {
        didMakeChange = true
        DDLogInfo("Adding custom domain - \(userEnteredDomainName)")

        addDomainToBlockedList(domain: userEnteredDomainName, for: listName)
        blockedList = getBlockedLists().userBlockListsDefaults[listName]
        
        tableView.reloadData()
    }
    
    @objc func addDomain() {
        let alertController = UIAlertController(title: "Add a Domain to Block", message: nil, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            guard let self else { return }
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                
                self.saveNewDomain(userEnteredDomainName: text)
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
                saveAction.isEnabled = textFieldText.isValid(.domainName)
            }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func showSubmenu() {
        subMenu.isHidden = false
    }
    
    @objc func hideSubmenu() {
        subMenu.isHidden = true
    }
    
    @objc func deleteList() {
        let alert = UIAlertController(title: NSLocalizedString("Delete List?", comment: ""), message: NSLocalizedString("Are you sure you want to remove this list?", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("No, Return", comment: ""), style: UIAlertAction.Style.default, handler: { _ in
            print("Return")
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes, Delete", comment: ""),
                                      style: UIAlertAction.Style.destructive,
                                      handler: { [weak self] (_) in
            guard let self else { return }
            if let vc = self.blockListVC {
                vc.didMakeChange = true
            }
            
            if let list = self.blockedList {
            deleteBlockedList(listName: list.name)
            }
            self.backButtonClicked()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func toggleBlocking(sender: UISwitch) {
        let sender = switchBlockingView.switchView
        setBlockingEnabled(sender.isOn)
    }
    
    func setBlockingEnabled(_ isEnabled: Bool) {
        
        let domains = getBlockedLists().userBlockListsDefaults
        var userList = domains[listName]

        userList?.enabled = isEnabled

        var data = getBlockedLists()
        data.userBlockListsDefaults[listName] = userList
        let encodedData = try? JSONEncoder().encode(data)
        defaults.set(encodedData, forKey: kUserBlockedLists)
        
        if let vc = self.blockListVC {
            vc.didMakeChange = true
        }
    }
    
    @objc func exportList(_ sender: UIButton) {
        let userList = getBlockedLists().userBlockListsDefaults[listName]
        
        guard let url = userList?.exportToURL() else { return }
        
        let activity = UIActivityViewController(
          activityItems: ["Export your list", url],
          applicationActivities: nil
        )
        activity.popoverPresentationController?.sourceView = sender
        present(activity, animated: true, completion: nil)
    }
}

extension ListSettingsViewController: ListDetailViewControllerDelegate {
    
    func changeListName(name: String) {
        listName = name
        tableView.reloadData()
    }
}

extension ListSettingsViewController: ListDescriptionViewControllerDelegate {
    
    func changeListDescription(description: String) {
        tableView.reloadData()
    }
}
