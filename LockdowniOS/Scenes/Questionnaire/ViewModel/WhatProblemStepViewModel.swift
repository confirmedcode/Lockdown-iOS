//
//  WhatProblemStepViewModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 23.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class WhatProblemStepViewModel: BaseStepViewModel, StepViewModelProtocol {
    private let isUserPremium: Bool
    let step: Steps = .whatsProblem

    private let problemList = [
        NSLocalizedString("Internet connection is blocked", comment: ""),
        NSLocalizedString("VPN not connecting", comment: ""),
        NSLocalizedString("Blocking not working", comment: ""),
        NSLocalizedString("Battery Drain", comment: ""),
        NSLocalizedString("Other", comment: "")
    ]
    
    private var selectedProblemIndex = -1
    private var otherInput: String? {
        didSet {
            didChangeReady?(isFilled)
        }
    }
    
    private var selectedProblem: String? {
        if (0..<problemList.count).contains(selectedProblemIndex) {
            return problemList[selectedProblemIndex]
        }
        return nil
    }
    
    private var otherDescription: String? {
        if selectedProblemIndex == problemList.count - 1 {
            return otherInput
        }
        return nil
    }

    var message: String? {
        guard selectedProblemIndex >= 0 else { return nil }
        var result = ""
        result.append(problemList[selectedProblemIndex])
        if isSelectedOther(),
           let otherInput {
            result.append("\n")
            result.append(otherInput)
        }
        result.append("\n")
        return result
    }
    
    var isFilled: Bool {
        guard selectedProblemIndex >= 0 else {
            return false
        }
        if isSelectedOther() {
            return !(otherInput?.isEmpty ?? true)
        }
        return true
    }
    
    var didChangeReady: ((Bool) -> Void)?
    
    init(isUserPremium: Bool, didChangeReady: ((Bool) -> Void)?) {
        self.isUserPremium = isUserPremium
        self.didChangeReady = didChangeReady
    }
    
    override func updateRows() {
        staticTableView?.clear()

        staticTableView?.addRowCell { cell in
            let titleView = ImageBannerWithTitleView()
            titleView.imageView.image = isUserPremium ? UIImage(named: "feedback") : UIImage(named: "feedback-promo")
            titleView.titleLabel.text = isUserPremium ? NSLocalizedString("How can we assist you?", comment: "") : NSLocalizedString("Get a promo Discount", comment: "")
            titleView.subtitleLabel.text = isUserPremium ?
                NSLocalizedString("Your feedback is valuable to us. By selecting the issue you're facing, we can guide you through troubleshooting or escalate the problem to our support team.", comment: "") :
                NSLocalizedString("Let us know your opinion, and as a thank you for your feedback, we’ll have a special offer waiting for you at the end!", comment: "")
            titleView.subtitleLabel.textAlignment = isUserPremium ? .left : .center
            self.setupClear(cell)
            cell.addSubview(titleView)
            titleView.anchors.edges.pin(insets: .init(top: 0, left: 0, bottom: 30, right: 0))
        }
        staticTableView?.addRowCell { cell in
            let titleView = SectionTitleView()
            titleView.titleLabel.text = NSLocalizedString("Select your problem", comment: "")
            self.setupClear(cell)
            cell.addSubview(titleView)
            titleView.anchors.edges.pin(insets: .init(top: 0, left: 0, bottom: 5, right: 0))

        }

        for index in 0..<problemList.count {
            staticTableView?.addRowCell { [unowned self] cell in
                let view = SelectableRadioSwitcherWithTitle()
                view.titleLabel.text = problemList[index]
                view.isSelected = self.selectedProblemIndex == index
                view.didSelect = { [weak self] in
                    self?.updateForSelect(problemIndex: index, isSelected: $0)
                }
                self.setupClear(cell)
                cell.addSubview(view)
                view.anchors.edges.pin(insets: .init(top: 0, left: 2, bottom: 0, right: 2))
            }
        }
        
        if isSelectedOther() {
            addTextViewRow(
                text: otherInput,
                placeholder: NSLocalizedString("Write here...", comment: "")
            ) { [weak self] text in
                self?.otherInput = text

            }
        }
        staticTableView?.reloadData()
    }
    
    private func isSelectedOther() -> Bool {
        selectedProblemIndex == problemList.count - 1
    }
    
    private func updateForSelect(problemIndex: Int, isSelected: Bool) {
        if isSelected {
            selectedProblemIndex = problemIndex
        } else {
            selectedProblemIndex = -1
        }
        if !isSelectedOther() {
            otherInput = nil
        }
        updateRows()
        didChangeReady?(isFilled)
    }
}
