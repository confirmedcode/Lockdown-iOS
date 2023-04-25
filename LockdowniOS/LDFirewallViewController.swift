//
//  LDFirewallViewController.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 17.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class LDFirewallViewController: UIViewController {
    
    lazy var accessLevelslView: AccessLevelslView = {
        let view = AccessLevelslView()
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.anchors.height.equal(1000)
        return view
    }()
    
    private lazy var firewallTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Get complete protection", comment: "")
        label.font = fontBold24
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private lazy var firewallDescriptionLabel1: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Block as many trackers as you want", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel2: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Import and export your own block lists", comment: "")))
        return label
    }()
    
    private lazy var firewallDescriptionLabel3: DescriptionLabel = {
        let label = DescriptionLabel()
        label.configure(with: DescriptionLabelViewModel(text: NSLocalizedString("Access to new curated lists of trackers", comment: "")))
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(firewallTitle)
        stackView.addArrangedSubview(firewallDescriptionLabel1)
        stackView.addArrangedSubview(firewallDescriptionLabel2)
        stackView.addArrangedSubview(firewallDescriptionLabel3)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var cpTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Only blocked with complete protection", comment: "")
        label.textColor = .label
        label.font = fontBold15
        label.textAlignment = .center
        return label
    }()
    
    private lazy var cpTrackersGroupView1: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#1"
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_game_marketing")!, title: "Game Marketing", number: 4678))
        return view
    }()
    
    private lazy var cpTrackersGroupView2: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#2"
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_marketing_trackers")!, title: "Marketing Trackers", number: 3432))
        return view
    }()
    
    private lazy var cpTrackersGroupView3: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#3"
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_email_trackers")!, title: "Email Trackers", number: 2756))
        return view
    }()
    
    private lazy var cpStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(cpTitle)
        stackView.addArrangedSubview(cpTrackersGroupView1)
        stackView.addArrangedSubview(cpTrackersGroupView2)
        stackView.addArrangedSubview(cpTrackersGroupView3)
        stackView.layer.cornerRadius = 8
        stackView.layer.borderWidth = 2
        stackView.layer.borderColor = UIColor.black.cgColor
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.backgroundColor = .secondarySystemBackground
        return stackView
    }()
    
    private lazy var upgradeButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setTitle(NSLocalizedString("Upgrade", comment: ""), for: .normal)
        button.titleLabel?.font = fontBold18
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        button.anchors.height.equal(56)
        button.addTarget(self, action: #selector(upgrade), for: .touchUpInside)
        return button
    }()
    
    private lazy var maTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Most active this week", comment: "")
        label.textColor = .label
        label.font = fontBold15
        label.textAlignment = .center
        return label
    }()
    
    private lazy var maTrackersGroupView1: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#1"
        view.number.textColor = .label
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_facebook_trackers")!, title: "Facebook Trackers", number: 764))
        return view
    }()
    
    private lazy var maTrackersGroupView2: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#2"
        view.number.textColor = .label
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_data_trackers")!, title: "Data Trackers", number: 330))
        return view
    }()
    
    private lazy var maTrackersGroupView3: TrackersGroupView = {
        let view = TrackersGroupView()
        view.placeNumber.text = "#3"
        view.number.textColor = .label
        view.configure(with: TrackersGroupViewModel(image: UIImage(named: "icn_clickbait_trackers")!, title: "Clickbait", number: 106))
        return view
    }()
    
    private lazy var maStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(maTitle)
        stackView.addArrangedSubview(maTrackersGroupView1)
        stackView.addArrangedSubview(maTrackersGroupView2)
        stackView.addArrangedSubview(maTrackersGroupView3)
        stackView.layer.cornerRadius = 8
        stackView.layer.borderWidth = 1
        stackView.layer.borderColor = UIColor.lightGray.cgColor
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()
    
    lazy var statisitcsView: OverallStatiscticView = {
        let view = OverallStatiscticView()
        return view
    }()
    
    private let segmented: FirewallSegmentedControl = {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .large)
        let image = UIImage()
        let text = "Swipe to Activate Firewall"
        let items = [image, text]
        let control = FirewallSegmentedControl(items: items)
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(accessLevelslView)
        accessLevelslView.anchors.top.safeAreaPin(inset: 18)
        accessLevelslView.anchors.leading.marginsPin()
        accessLevelslView.anchors.trailing.marginsPin()
        
        view.addSubview(scrollView)
        scrollView.anchors.top.spacing(18, to: accessLevelslView.anchors.bottom)
        scrollView.anchors.leading.pin()
        scrollView.anchors.trailing.pin()
        scrollView.anchors.bottom.pin()
        
        scrollView.addSubview(contentView)
        contentView.anchors.top.pin()
        contentView.anchors.centerX.align()
        contentView.anchors.width.equal(scrollView.anchors.width)
        contentView.anchors.bottom.pin()

        contentView.addSubview(stackView)
        stackView.anchors.top.marginsPin()
        stackView.anchors.leading.marginsPin()
        stackView.anchors.trailing.marginsPin()
        
        contentView.addSubview(cpStackView)
        cpStackView.anchors.top.spacing(18, to: stackView.anchors.bottom)
        cpStackView.anchors.leading.marginsPin()
        cpStackView.anchors.trailing.marginsPin()
        
        contentView.addSubview(upgradeButton)
        upgradeButton.anchors.top.spacing(18, to: cpStackView.anchors.bottom)
        upgradeButton.anchors.leading.marginsPin()
        upgradeButton.anchors.trailing.marginsPin()
        
        contentView.addSubview(maStackView)
        maStackView.anchors.top.spacing(18, to: upgradeButton.anchors.bottom)
        maStackView.anchors.leading.marginsPin()
        maStackView.anchors.trailing.marginsPin()
        
        contentView.addSubview(statisitcsView)
        statisitcsView.anchors.top.spacing(18, to: maStackView.anchors.bottom)
        statisitcsView.anchors.leading.marginsPin()
        statisitcsView.anchors.trailing.marginsPin()
        
        view.addSubview(segmented)
        segmented.anchors.bottom.safeAreaPin()
        segmented.anchors.leading.marginsPin()
        segmented.anchors.trailing.marginsPin()
        segmented.anchors.height.equal(56)
    }
}

private extension LDFirewallViewController {
    
    @objc func upgrade() {
        
    }
}
