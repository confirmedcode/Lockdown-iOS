//
//  AccessLevelView.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 19.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

final class AccessLevelView: UIView {
    
    // MARK: - Properties
    
    private lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var accessLevelIv: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.layer.masksToBounds = true
        return image
    }()
    
    lazy var accessLevelName: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontBold11
        label.textAlignment = .center
        return label
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
        addSubview(containerView)
        containerView.anchors.edges.pin()
        
        containerView.addSubview(accessLevelIv)
        accessLevelIv.anchors.centerX.align()
        accessLevelIv.anchors.centerY.align()
        
        containerView.addSubview(accessLevelName)
        accessLevelName.anchors.centerX.align()
        accessLevelName.anchors.centerY.align()
    }
}

final class AccessLevelslView: UIView {
    
    // MARK: - Properties
    
    private lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let basicView: AccessLevelView = {
        let view = AccessLevelView()
        view.accessLevelIv.image = UIImage(named: "basic")
        view.accessLevelName.text = "Basic"
        return view
    }()
    
    private let advancedView: AccessLevelView = {
        let view = AccessLevelView()
        view.accessLevelIv.image = UIImage(named: "advanced")
        view.accessLevelName.text = "Advanced"
        return view
    }()
    
    let anonymousView: AccessLevelView = {
        let view = AccessLevelView()
        view.accessLevelIv.image = UIImage(named: "anonymous")
        view.accessLevelName.text = "Anonymous"
        return view
    }()
    
    private let universalView: AccessLevelView = {
        let view = AccessLevelView()
        view.accessLevelIv.image = UIImage(named: "universal")
        view.accessLevelName.text = "Universal"
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(basicView)
        stackView.addArrangedSubview(advancedView)
        stackView.addArrangedSubview(anonymousView)
        stackView.addArrangedSubview(universalView)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 0
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
        
        stackView.insertSubview(advancedView, belowSubview: basicView)
        stackView.insertSubview(anonymousView, belowSubview: advancedView)
        stackView.insertSubview(universalView, belowSubview: anonymousView)
    }
}

