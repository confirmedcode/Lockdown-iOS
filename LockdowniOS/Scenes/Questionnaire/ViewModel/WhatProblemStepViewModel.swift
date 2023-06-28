//
//  WhatProblemStepViewModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 23.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class WhatProblemStepViewModel: BaseStepViewModel, StepViewModelProtocol {
    private let problemList = [
        NSLocalizedString("Internet connection is blocked", comment: ""),
        NSLocalizedString("VPN not connecting", comment: ""),
        NSLocalizedString("Blocking not working", comment: ""),
        NSLocalizedString("Battery Drain", comment: ""),
        NSLocalizedString("Other", comment: "")
    ]
    
    private var selectedProblemIndex = -1
    private var otherInput: String?
    
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
    
    var step: Steps = .whatsProblem
    var message: String? {
        guard !isSkiped, selectedProblemIndex >= 0 else { return nil }
        var result = ""
        result.append(problemList[selectedProblemIndex])
        if isSelectedOther(),
           let otherInput {
            result.append("\n")
            result.append(otherInput)
        }
        return result
    }
    
    override func updateRows() {
        staticTableView?.clear()
        addTitleRow(
            NSLocalizedString("What problem are you experiencing?", comment: ""),
            subtitle: NSLocalizedString("Select your problem", comment: "")
        )
        
        for index in 0..<problemList.count {
            staticTableView?.addRowCell { [unowned self] cell in
                let view = SelectableRadioSwitcherWithTitle()
                view.titleLabel.text = problemList[index]
                view.isSelected = self.selectedProblemIndex == index
                view.didSelect = { self.updateForSelect(problemIndex: index, isSelected: $0) }
                self.setupClear(cell)
                cell.addSubview(view)
                view.anchors.edges.pin(insets: .init(top: 5, left: 2, bottom: 5, right: 2))
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
    }
}
