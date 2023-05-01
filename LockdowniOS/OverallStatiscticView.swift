//
//  OverallStatiscticView.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 18.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

struct OverallStatiscticViewModel {
    let enabled: Int
    let disabled: Int
    let requests: Int
    let blocked: Int
}

final class BoxLabelView: UIView {
    
    // MARK: - Properties

    lazy var boxView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 1
        view.anchors.height.equal(65)
        return view
    }()
    
    lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontBold24
        label.textAlignment = .center
        return label
    }()
    
    lazy var boxTitle: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontRegular14
        label.textAlignment = .center
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(boxView)
        stackView.addArrangedSubview(boxTitle)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 8
        return stackView
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    private func configureUI() {
        addSubview(stackView)
        stackView.anchors.edges.pin()
        
        boxView.addSubview(numberLabel)
        numberLabel.anchors.centerX.align()
        numberLabel.anchors.centerY.align()
    }
}

final class OverallStatiscticView: UIView {
    
    // MARK: - Properties
    
    private let enabledBoxView: BoxLabelView = {
        let box = BoxLabelView()
        box.numberLabel.text = "7"
        box.boxTitle.text = "Enabled"
        return box
    }()
    
    private let disabledBoxView: BoxLabelView = {
        let box = BoxLabelView()
        box.numberLabel.text = "3"
        box.boxTitle.text = "Disabled"
        return box
    }()
    
    private let requestsBoxView: BoxLabelView = {
        let box = BoxLabelView()
        box.numberLabel.text = "0.9K"
        box.boxTitle.text = "Requests"
        return box
    }()
    
    private let blockedBoxView: BoxLabelView = {
        let box = BoxLabelView()
        box.numberLabel.text = "0.2K"
        box.boxTitle.text = "Blocked"
        return box
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(enabledBoxView)
        stackView.addArrangedSubview(disabledBoxView)
        stackView.addArrangedSubview(requestsBoxView)
        stackView.addArrangedSubview(blockedBoxView)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    private func configureUI() {
        
        addSubview(stackView)
        stackView.anchors.top.marginsPin()
        stackView.anchors.bottom.marginsPin()
        stackView.anchors.leading.pin()
        stackView.anchors.trailing.pin()
    }
    
    func configure(with model: OverallStatiscticViewModel) {

    }
}
