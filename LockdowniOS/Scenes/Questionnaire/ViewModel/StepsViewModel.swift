//
//  StepsViewModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 23.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

protocol StepsViewProtocol: AnyObject {
    func changeContent()
    func updateNextButton()
    func close(completion: (() -> Void)?)
    func showSelectCountry(with viewModel: SelectCountryViewModelProtocol)
    func showAlert(_ title: String?, message: String?)
}

protocol StepViewModelProtocol {
    func contentView() -> UITableView
    var step: Steps { get }
    var message: String? { get }
    var isFilled: Bool { get }
}

class StepsViewModel {
    private let isUserPremium: Bool

    private lazy var steps: [StepViewModelProtocol] = [
        whatProblemStep,
        questionsStep
    ]
    
    private lazy var whatProblemStep: WhatProblemStepViewModel = {
        let viewModel = WhatProblemStepViewModel(isUserPremium: isUserPremium) { [weak self] _ in
            self?.view?.updateNextButton()
        }
        return viewModel
    }()
    
    private lazy var questionsStep: QuestionsStepViewModel = {
        let viewModel = QuestionsStepViewModel()
        viewModel.selectCountry = { [weak self] in self?.selectCountry(viewModel: $0) }
        return viewModel
    }()
    
    private weak var view: StepsViewProtocol?
    
    var stepsCount: Int {
        steps.count
    }
    
    var actionTitle: String {
        stepViewModel.step.actionTitle
    }
    
    var currentStepIndex = 0
    
    var stepViewModel: StepViewModelProtocol {
        steps[currentStepIndex]
    }
    
    var isStepReady: Bool {
        steps[currentStepIndex].isFilled
    }
    
    private var sendMessage: ((String) -> Void)?
    private var isReadyToSend: Bool {
        steps.reduce(true) { $0 && $1.isFilled }
    }
    
    init(isUserPremium: Bool, sendMessage: ((String) -> Void)?) {
        self.isUserPremium = isUserPremium
        self.sendMessage = sendMessage
    }
    
    func bind(_ view: StepsViewProtocol) {
        self.view = view
        view.changeContent()
    }
    
    func performStepAction() {
        guard currentStepIndex != steps.count - 1 else {
            finishFlow()
            return
        }
        
        currentStepIndex += 1
        view?.changeContent()
    }
    
    func backPressed() {
        guard currentStepIndex > 0 else {
            view?.close(completion: nil)
            return
        }
        
        currentStepIndex -= 1
        view?.changeContent()
    }
    
    func selectCountry(viewModel: SelectCountryViewModelProtocol) {
        view?.showSelectCountry(with: viewModel)
    }
    
    private func finishFlow() {
        guard isReadyToSend else {
            view?.showAlert(
                NSLocalizedString("Empty answers!", comment: ""),
                message: NSLocalizedString("Could you answer all questions?", comment: "")
            )
            return
        }
        let sendMessage = sendMessage
        let message = message()
        view?.close {
            if let message {
                sendMessage?(message)
            }
        }
    }
    
    private func message() -> String? {
        steps
            .compactMap { $0.message }
            .reduce("") { partialResult, message in
                partialResult + "\n" + message
            }
        
    }
}
