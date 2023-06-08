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
    
    var didMakeChange = false
    var lockdownBlockLists: [LockdownGroup] = []
    
    let curatedBlockedDomainsTableView = StaticTableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground

        configureCuratedBlockedDomainsTableView()
        
    }
    
    private func configureCuratedBlockedDomainsTableView() {
        addTableView(curatedBlockedDomainsTableView, layout: { tableView in
            tableView.anchors.top.marginsPin()
            tableView.anchors.leading.pin()
            tableView.anchors.trailing.pin()
            tableView.anchors.bottom.pin()
        })
        
        reloadCuratedBlockDomains()
    }
    
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
    
    func createCuratedBlockedDomainsRows() {
        let tableView = curatedBlockedDomainsTableView
        
        for lockdownGroup in lockdownBlockLists {
            
            let cell = tableView.addRow { (contentView) in
                let blockListView = BlockListView()
                blockListView.contents = .lockdownGroup(lockdownGroup)
                contentView.addSubview(blockListView)
                blockListView.anchors.edges.pin()
            }.onSelect { [unowned self] in
                if UserDefaults.hasSeenAdvancedPaywall || UserDefaults.hasSeenAnonymousPaywall || UserDefaults.hasSeenUniversalPaywall {
                    
                    let storyboard = UIStoryboard.main
                    let target = storyboard.instantiate(BlockListGroupViewController.self)
                    target.lockdownGroup = lockdownGroup
                    target.blockListVC = self
                    self.navigationController?.pushViewController(target, animated: true)
                } else {
                    if lockdownGroup.accessLevel == "advanced" {
                        let vc = VPNPaywallViewController()
                        present(vc, animated: true)
                    } else {
                        let storyboard = UIStoryboard.main
                        let target = storyboard.instantiate(BlockListGroupViewController.self)
                        target.lockdownGroup = lockdownGroup
                        target.blockListVC = self
                        self.navigationController?.pushViewController(target, animated: true)
                    }
                }
            }
            
            cell.accessoryType = .disclosureIndicator
        }
    }
}
