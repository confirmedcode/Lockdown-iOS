//
//  QuestionsStepViewModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 26.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class QuestionsStepViewModel: BaseStepViewModel, StepViewModelProtocol {
    var step: Steps = .questions
    var message: String? {
        model.generateMessage(
            firewallInput: firewallInput,
            vpnInput: vpnInput,
            otherDetailsInput: otherDetailsInput
        )
    }
    
    var isFilled: Bool {
        model.isAllRequiredQuestionsAnswered
    }
    
    private var model = QuestionModel() {
        didSet {
            updateRows()
        }
    }
    
    var firewallInput: String?
    var vpnInput: String?
    var otherDetailsInput: String?
    
    var selectCountry: ((SelectCountryViewModelProtocol) -> Void)?
    
    override func updateRows() {
        staticTableView?.clear()
        addTitleRow(
            NSLocalizedString("Questions", comment: ""),
            subtitle: NSLocalizedString("Please fill questions answer", comment: ""),
            bottomSpacing: 2
        )
        
        addYesNoRow(
            title: NSLocalizedString("1. Is the firewall on? (optional)", comment: ""),
            initialValue: model.isFirewallOn,
            didSelect: { [weak self] in self?.model.isFirewallOn = $0 }
        )
        
        addTextViewRow(
            text: firewallInput,
            placeholder: NSLocalizedString("Write more information...", comment: ""),
            didChangeText: { [weak self] in self?.firewallInput = $0 }
        )
        
        addYesNoRow(
            title: NSLocalizedString("2. Is the VPN on? (optional)", comment: ""),
            initialValue: model.isVPNOn,
            didSelect: { [weak self] in self?.model.isVPNOn = $0 }
        )
        
        addTextViewRow(
            text: vpnInput,
            placeholder: NSLocalizedString("Write more information...", comment: ""),
            didChangeText: { [weak self] in self?.vpnInput = $0 }
        )
        
        if model.isVPNOn ?? false {
            addQuestionTitleRow(
                NSLocalizedString("If the VPN is on, which region is it set to?", comment: "")
            )
            addNavigationLinkRow(
                placeholder: NSLocalizedString("Select region", comment: ""),
                country: model.vpnRegion
            ) { [weak self] in
                self?.selectCountry?(
                    SelectRegionViewModel(
                        selectedCountry: self?.model.vpnRegion,
                        didSelectCountry: { self?.model.vpnRegion = $0 }
                    )
                )
            }
        }
        
        addQuestionTitleRow(
            NSLocalizedString("3. Where are you contacting us from?", comment: "")
        )
        addNavigationLinkRow(
            placeholder: NSLocalizedString("Select country", comment: ""),
            country: model.fromCountry
        ) { [weak self] in
            self?.selectCountry?(
                SelectCountryViewModel(
                    selectedCountry: self?.model.fromCountry,
                    didSelectCountry: { self?.model.fromCountry = $0 }
                )
            )
        }
        
        addYesNoRow(
            title: NSLocalizedString("4. Is the issue happening on WiFi?", comment: ""),
            initialValue: model.isHappeningWifiIssue,
            didSelect: { [weak self] in self?.model.isHappeningWifiIssue = $0 }
        )
        addYesNoRow(
            title: NSLocalizedString("5. Is the issue happening on cellular data?", comment: ""),
            initialValue: model.isHappenningCellularIssue,
            didSelect: { [weak self] in self?.model.isHappenningCellularIssue = $0 }
        )
        addYesNoRow(
            title: NSLocalizedString("6. Do you have other firewall apps installed?", comment: ""),
            initialValue: model.haveOtherFirewall,
            didSelect: { [weak self] in self?.model.haveOtherFirewall = $0 }
        )
        addYesNoRow(
            title: NSLocalizedString("7. Do you have other VPN apps installed?", comment: ""),
            initialValue: model.haveOtherVPN,
            didSelect: { [weak self] in self?.model.haveOtherVPN = $0 }
        )
        
        addQuestionTitleRow(
            NSLocalizedString("8. Additional details. (optional)", comment: "")
        )
        addTextViewRow(
            text: otherDetailsInput,
            placeholder: NSLocalizedString("Write additional details here...", comment: ""),
            didChangeText: { [weak self] in self?.otherDetailsInput = $0 }
        )
        
        staticTableView?.reloadData()
    }
    
    private func addYesNoRow(
        title: String,
        initialValue: Bool?,
        didSelect: ((Bool?) -> Void)?
    ) {
        staticTableView?.addRowCell { [unowned self] cell in
            let switcher = YesNoRadioSwitcherView()
            switcher.titleLabel.text = title
            switcher.isSelected = initialValue
            switcher.didSelect = didSelect
            self.setupClear(cell)
            cell.addSubview(switcher)
            switcher.anchors.edges.pin(insets: .init(top: 37, left: 2, bottom: 15, right: 2))
        }
    }
    
    private func addQuestionTitleRow(_ title: String) {
        staticTableView?.addRowCell { [unowned self] cell in
            let view = QuestionTitleView()
            view.titleLabel.text = title
            self.setupClear(cell)
            cell.addSubview(view)
            view.anchors.edges.pin(insets: .init(top: 20, left: 2, bottom: 10, right: 2))
        }
    }
    
    private func addNavigationLinkRow(
        placeholder: String,
        country: Country?,
        perform: (() -> Void)?
    ) {
        staticTableView?.addRowCell { [unowned self] cell in
            let view = NavigationLinkView()
            let isEmpty = country == nil
            view.placeholderLabel.text = placeholder
            view.placeholderLabel.isHidden = !isEmpty
            view.titleLabel.text = country?.title
            view.titleLabel.isHidden = isEmpty
            view.emojiLabel.text = country?.emojiSymbol
            view.emojiLabel.isHidden = isEmpty
            view.didSelect = perform
            self.setupClear(cell)
            cell.addSubview(view)
            view.anchors.edges.pin(insets: .init(top: 20, left: 2, bottom: 10, right: 2))
        }
    }
}
