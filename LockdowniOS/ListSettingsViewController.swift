//
//  ListSettingsViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 28.03.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

struct ListSettingsSection {
    let title: String
    let options: [ListSettingsOptionType]
}

enum ListSettingsOptionType {
    case blockedListCell(model: ListSettingsOption)
    case blockedDomainsCell(model: ListSettingsStaticOption)
}

struct ListSettingsStaticOption {
    let title: String
    let handler: (() -> Void)
    let isBlocked: Bool
}

struct ListSettingsOption {
    let title: String
    let handler: (() -> Void)
}

import UIKit

final class ListSettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    var titleName = "" {
        didSet {
            
        }
    }
    
    lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.titleLabel.text = titleName
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
        return view
    }()
    
    private lazy var subMenu: ListsSubmenuView = {
        let view = ListsSubmenuView()
        view.topButton.setTitle(NSLocalizedString("Export List...", comment: ""), for: .normal)
        // TODO: Change image for buttons
        view.topButton.setImage(UIImage(named: "icn_export_folder"), for: .normal)
        view.topButton.addTarget(self, action: #selector(exportList), for: .touchUpInside)
        view.bottomButton.setTitle(NSLocalizedString("Delete List...", comment: ""), for: .normal)
        // TODO: Change image for buttons
        view.bottomButton.setImage(UIImage(named: "icn_trash"), for: .normal)
        view.bottomButton.addTarget(self, action: #selector(deleteList), for: .touchUpInside)
        return view
    }()
    
//    lazy var addDomainToBlockButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.tintColor = .tunnelsBlue
//        button.setTitle("Add a Domain to Block...", for: .normal)
//        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
//        button.setTitleColor(.label, for: .normal)
//        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
//        return button
//    }()
//
//    lazy var deleteListButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Delete this list", for: .normal)
//        button.setTitleColor(.red, for: .normal)
//        return button
//    }()
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    var models = [ListSettingsSection]()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        view.backgroundColor = .secondarySystemBackground
        configureUI()
        configureTableView()
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
        view.addGestureRecognizer(tap)
    }
    
    func configureTableView() {
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 40
        
        tableView.register(ListBlockedTableViewCell.self, forCellReuseIdentifier: ListBlockedTableViewCell.identifier)
        tableView.register(DomainsBlockedTableViewCell.self, forCellReuseIdentifier: DomainsBlockedTableViewCell.identifier)
//        tableView.register(CustomTableHeader.self, forHeaderFooterViewReuseIdentifier: CustomTableHeader.identifier)
    }
    
    func configure() {
        models.append(ListSettingsSection(title: "NAME", options: [
            .blockedListCell(model: ListSettingsOption(title: "My Custom List", handler: { [weak self] in
                guard let self = self else { return }
                let controller = ListDetailViewController()
//                let navigation = UINavigationController(rootViewController: self)
//                (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController = navigation
//                self.navigationController?.pushViewController(controller, animated: true)
                
                self.present(controller, animated: true)
            }))
            
        ]))
        models.append(ListSettingsSection(title: "DESCRIPTION", options: [
            .blockedListCell(model: ListSettingsOption(title: "No description", handler: {
                print("Go to description")
            }))
            
        ]))
        models.append(ListSettingsSection(title: "DOMAINS", options: [
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "vk.com", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "tut.com", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "dust.com", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "linkage.eu", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "sitizen.com", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "hibike.com", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "r2-bike.com", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "lenta.ru", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "tochka.by", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "medium.com", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "kodeco.com", handler: {}, isBlocked: true)),
            .blockedDomainsCell(model: ListSettingsStaticOption(title: "habr.com", handler: {}, isBlocked: true)),
        ]))
    }
}

extension ListSettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        
        let sectionName = UILabel()
        sectionName.font = fontBold13
        sectionName.text = models[section].title
        
        view.addSubview(sectionName)
        sectionName.anchors.top.marginsPin()
        sectionName.anchors.leading.marginsPin()
        sectionName.anchors.bottom.marginsPin()
        
        if section == 2 {
            let addButton = UIButton(type: .system)
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold, scale: .large)
            addButton.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig), for: .normal)
            addButton.tintColor = .tunnelsBlue
            addButton.addTarget(self, action: #selector(addDomain), for: .touchUpInside)
            
            view.addSubview(addButton)
            addButton.anchors.top.marginsPin()
            addButton.anchors.trailing.marginsPin()
            addButton.anchors.bottom.marginsPin()
        }
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return models.count
    }
    
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        let view = UIView()
//
//        if section == 2 {
//            view.addSubview(addDomainToBlockButton)
//            addDomainToBlockButton.anchors.leading.marginsPin()
//            addDomainToBlockButton.anchors.top.marginsPin()
//
//            view.addSubview(deleteListButton)
//            deleteListButton.anchors.leading.marginsPin()
//            deleteListButton.anchors.top.spacing(12, to: addDomainToBlockButton.anchors.bottom)
//        }
//        return view
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        models[section].options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = models[indexPath.section].options[indexPath.row]
        
        switch model {
        case .blockedListCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ListBlockedTableViewCell.identifier, for: indexPath) as? ListBlockedTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        case .blockedDomainsCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: DomainsBlockedTableViewCell.identifier, for: indexPath) as? DomainsBlockedTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
        let type = models[indexPath.section].options[indexPath.row]
        switch indexPath.section {
        case 0:
            print("list details")
            let vc = ListDetailViewController()
            navigationController?.present(vc, animated: true)
//            navigationController?.pushViewController(vc, animated: true)
        case 1:
            print("descr")
        default:
            print("domain")
        }
//        switch type {
//        case .blockedListCell(let model):
//            model.handler()
//        case .blockedDomainsCell(let model):
//            model.handler()
//        }
    }
}

extension ListSettingsViewController: UITableViewDelegate {
    
}

// MARK: - Functions
extension ListSettingsViewController {
    
    @objc func backButtonClicked() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func addDomain() {
        print("addDomain btn pressed ....")
        let alertController = UIAlertController(title: "Add a Domain to Block", message: nil, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                // operations
                
//                self.saveNewDomain(userEnteredDomainName: text)
//                if !getUserBlockedDomains().isEmpty {
//                    tableView.clear()
//                }
                
//                tableView.reloadData()
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
    
    @objc func showSubmenu() {
        print("exportList btn pressed ....")
        subMenu.isHidden = false
    }
    
    @objc func hideSubmenu() {
        subMenu.isHidden = true
    }
    
    @objc func exportList() {
        print("exportList btn pressed ....")
    }
    
    @objc func deleteList() {
        print("deleteList btn pressed ....")
        let alert = UIAlertController(title: NSLocalizedString("Delete List?", comment: ""), message: NSLocalizedString("Are you sure you want to remove this list?", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("No, Return", comment: ""), style: UIAlertAction.Style.default, handler: { _ in
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

