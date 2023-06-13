//
//  CuratedListsViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 2.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

final class CuratedListsViewController: UIViewController {
    
    // MARK: - Properties
    
    var didMakeChange = false {
        didSet{
            
        }
    }
    var lockdownBlockLists: [LockdownGroup] = []
    var basicLockdownBlockLists: [LockdownGroup] = []
    var advancedLockdownBlockLists: [LockdownGroup] = []
    
    let curatedBlockedDomainsTableView = StaticTableView()
    
    private let curatedTableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTableView()
    }
    
    private func configureTableView() {
        curatedTableView.delegate = self
        curatedTableView.dataSource = self
        
        addTableView(curatedTableView) { tableview in
            curatedTableView.anchors.top.pin()
            curatedTableView.anchors.leading.pin()
            curatedTableView.anchors.trailing.pin()
            curatedTableView.anchors.bottom.pin()
        }
        
        reloadTableView()
    }
    
    func reloadTableView() {
        
        lockdownBlockLists = []
        
        lockdownBlockLists = {
            let domains = getLockdownBlockedDomains().lockdownDefaults
            let sorted = domains.sorted(by: { $0.key < $1.key })
            return Array(sorted.map(\.value))
        }()
        
        basicLockdownBlockLists = lockdownBlockLists.filter{ $0.accessLevel == "basic"}
        advancedLockdownBlockLists = lockdownBlockLists.filter{ $0.accessLevel == "advanced"}
        
        curatedTableView.reloadData()
    }
}

extension CuratedListsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        
        let sectionName = UILabel()
        sectionName.font = fontBold18
        
        view.addSubview(sectionName)
        sectionName.anchors.top.marginsPin()
        sectionName.anchors.leading.marginsPin()
        sectionName.anchors.bottom.marginsPin()
        
        switch section {
        case 0:
            sectionName.text = NSLocalizedString("Basic", comment: "")
        case 1:
            sectionName.text = NSLocalizedString("Premium", comment: "")
            
                let lockImage = UIImageView()
                lockImage.image = UIImage(named: "icn_lock")
                lockImage.contentMode = .center
                
                view.addSubview(lockImage)
                lockImage.anchors.trailing.marginsPin()
                lockImage.anchors.centerY.equal(sectionName.anchors.centerY)
            
            if UserDefaults.hasSeenAdvancedPaywall || UserDefaults.hasSeenAnonymousPaywall || UserDefaults.hasSeenUniversalPaywall { lockImage.isHidden = true }
            
        default: break
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let numberOfBasicLists = basicLockdownBlockLists.count
        let numberOfAdvancedLists = advancedLockdownBlockLists.count
        
        switch section {
        case 0: return numberOfBasicLists
        case 1: return numberOfAdvancedLists
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = UITableViewCell()
            let blockListView = BlockListView()
            blockListView.contents = .lockdownGroup(basicLockdownBlockLists[indexPath.row])
            cell.contentView.addSubview(blockListView)
            blockListView.anchors.edges.pin()
            cell.accessoryType = .disclosureIndicator
            return cell
        case 1:
            let cell = UITableViewCell()
            let blockListView = BlockListView()
            blockListView.contents = .lockdownGroup(advancedLockdownBlockLists[indexPath.row])
            cell.contentView.addSubview(blockListView)
            blockListView.anchors.edges.pin()
            cell.accessoryType = .disclosureIndicator
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            let storyboard = UIStoryboard.main
            let target = storyboard.instantiate(BlockListGroupViewController.self)
            target.lockdownGroup = basicLockdownBlockLists[indexPath.row]
            target.blockListVC = self
            self.navigationController?.pushViewController(target, animated: true)
        case 1:
            if UserDefaults.hasSeenAdvancedPaywall || UserDefaults.hasSeenAnonymousPaywall || UserDefaults.hasSeenUniversalPaywall {
                let storyboard = UIStoryboard.main
                let target = storyboard.instantiate(BlockListGroupViewController.self)
                target.lockdownGroup = advancedLockdownBlockLists[indexPath.row]
                target.blockListVC = self
                self.navigationController?.pushViewController(target, animated: true)
            } else {
                let vc = VPNPaywallViewController()
                present(vc, animated: true)
            }
            
        default:
            break
        }
    }
}

extension CuratedListsViewController: UITableViewDelegate {}
