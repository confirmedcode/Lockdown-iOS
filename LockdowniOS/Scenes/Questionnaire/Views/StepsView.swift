//
//  StepsView.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 21.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class StepsView: UIView {
    
    var steps = 0 {
        didSet {
            if oldValue != steps {
                resetupStepsView()
            }
        }
    }
    var currentStep = 0 {
        didSet {
            updateCurrentStep()
        }
    }
    
    var filledColor = UIColor.tunnelsBlue
    var unfilledColor = UIColor.tableCellBackground

    private var views = [UIView]()
    
    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        backgroundColor = .clear
        
        addSubview(stackView)
        stackView.anchors.top.pin()
        stackView.anchors.trailing.pin()
        stackView.anchors.bottom.pin()
        stackView.anchors.leading.pin()
        
        resetupStepsView()
    }

    private func resetupStepsView() {
        views.forEach { stackView.removeArrangedSubview($0) }
        views = (0..<steps).map { _ in stepView() }
        views.forEach { stackView.addArrangedSubview($0) }
        updateCurrentStep()
    }
    
    private func stepView() -> UIView {
        let view = UIView()
        view.backgroundColor = unfilledColor
        view.anchors.height.equal(4)
        view.layer.cornerRadius = 2
        return view
    }
    
    private func updateCurrentStep() {
        for index in 0..<views.count {
            views[index].backgroundColor = index <= currentStep ? filledColor : unfilledColor
        }
    }
}
