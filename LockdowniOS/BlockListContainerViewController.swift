//
//  BlockListContainerViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 2.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class BlockListContainerViewController: UIViewController {
    
    // MARK: - Properties
    var didMakeChange = false
    
    private lazy var customNavigationView: CustomNavigationView = {
        let view = CustomNavigationView()
        view.title = NSLocalizedString("Configure Blocking", comment: "")
        view.buttonTitle = NSLocalizedString("CLOSE", comment: "")
        view.onButtonPressed { [unowned self] in
            self.close()
        }
        return view
    }()
    
    private let paragraphLabel: UILabel = {
        let view = UILabel()
        view.font = fontRegular14
        view.numberOfLines = 0
        view.text = NSLocalizedString("Block all your apps from connecting to the domains and sites below. For your convenience, Lockdown also has pre-configured suggestions.", comment: "")
        return view
    }()
    
//    enum Page: CaseIterable {
//        case curated
//        case custom
//
//        var localizedTitle: String {
//            switch self {
//            case .curated:
//                return NSLocalizedString("Curated", comment: "")
//            case .custom:
//                return NSLocalizedString("Custom", comment: "")
//            }
//        }
//    }
    
    private lazy var segmented: UISegmentedControl = {
        let view = UISegmentedControl()
//        let view = UISegmentedControl(items: Page.allCases.map(\.localizedTitle))
//        view.removeAllSegments()
        view.insertSegment(withTitle: "Curated", at: 0, animated: false)
        view.insertSegment(withTitle: "Custom", at: 1, animated: false)
        view.selectedSegmentIndex = 0
        view.setTitleTextAttributes([.font: fontMedium14], for: .normal)
        view.selectedSegmentTintColor = .tunnelsBlue
        view.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        view.addTarget(self, action: #selector(segmentedControlDidChangeValue(_:)), for: .valueChanged)
        return view
    }()
    
    // MARK: Child ViewControllers
    private lazy var curatedListsViewController: CuratedListsViewController = {
        let vc = CuratedListsViewController()
        self.add(asChildViewController: vc)
        return vc
    }()
    
    private lazy var customListsViewController: CustomListsViewController = {
        let vc = CustomListsViewController()
        self.add(asChildViewController: vc)
        return vc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        configureUI()
    }
    
    private func configureUI() {
        view.addSubview(customNavigationView)
        customNavigationView.anchors.leading.pin()
        customNavigationView.anchors.trailing.pin()
        customNavigationView.anchors.top.safeAreaPin()
        
        view.addSubview(paragraphLabel)
        paragraphLabel.anchors.top.spacing(0, to: customNavigationView.anchors.bottom)
        paragraphLabel.anchors.leading.readableContentPin(inset: 3)
        paragraphLabel.anchors.trailing.readableContentPin(inset: 3)
        paragraphLabel.anchors.height.equal(60)
        
        view.addSubview(segmented)
        segmented.anchors.top.spacing(12, to: paragraphLabel.anchors.bottom)
        segmented.anchors.leading.readableContentPin()
        segmented.anchors.trailing.readableContentPin()
        segmented.anchors.height.equal(40)
        
        updateView()
        
    }
}

private extension BlockListContainerViewController {
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
    
    @objc func segmentedControlDidChangeValue(_ sender: UISegmentedControl) {
        updateView()
    }
    
    func updateView() {
        
        if segmented.selectedSegmentIndex == 0 {
            remove(asChildViewController: customListsViewController)
            add(asChildViewController: curatedListsViewController)
        } else {
            remove(asChildViewController: curatedListsViewController)
            add(asChildViewController: customListsViewController)
        }
    }
    
    func add(asChildViewController viewController: UIViewController) {
        // Add Child View Controller
        addChild(viewController)

        // Add Child View as Subview
        view.addSubview(viewController.view)

        // Define Constraints
        viewController.view.anchors.top.spacing(24, to: segmented.anchors.bottom)
        viewController.view.anchors.leading.pin()
        viewController.view.anchors.trailing.pin()
        viewController.view.anchors.bottom.pin()

        // Notify Child View Controller
        viewController.didMove(toParent: self)
    }
    
    func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParent: nil)

        // Remove Child View From Superview
        viewController.view.removeFromSuperview()

        // Notify Child View Controller
        viewController.removeFromParent()
    }
}
