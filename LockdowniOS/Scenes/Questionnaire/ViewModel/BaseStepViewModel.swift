//
//  BaseStepViewModel.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 26.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class BaseStepViewModel {
    var staticTableView: StaticTableView?
    var isSkiped = false
    
    func contentView() -> UITableView {
        let staticTableView = StaticTableView()
        self.staticTableView = staticTableView

        staticTableView.backgroundColor = .clear
        staticTableView.deselectsCellsAutomatically = true
        staticTableView.separatorStyle = .none
        
        updateRows()
        return staticTableView
    }
    
    func updateRows() { }
    
    func addTitleRow(
        _ title: String?,
        subtitle: String?,
        bottomSpacing: CGFloat = 29
    ) {
        staticTableView?.addRowCell { cell in
            let titleView = TitleAndSubtitleView()
            titleView.titleLabel.text = title
            titleView.subtitleLabel.text = subtitle
            self.setupClear(cell)
            cell.addSubview(titleView)
            titleView.anchors.edges.pin(insets: .init(top: 0, left: 2, bottom: bottomSpacing, right: 2))
        }
    }
    
    func addTextViewRow(
        text: String?,
        placeholder: String,
        didChangeText: @escaping (String) -> Void
    ) {
        staticTableView?.addRowCell { cell in
            let view = TextViewWithPlaceholder()
            view.textView.text = text
            view.placeholderLabel.text = placeholder
            view.placeholderLabel.isHidden = !(text?.isEmpty ?? true)
            self.setupClear(cell)
            cell.addSubview(view)
            view.anchors.edges.pin(insets: .init(top: 3, left: 2, bottom: 5, right: 2))
            view.textDidChanged = { [weak self] text in
                didChangeText(text)
                self?.staticTableView?.beginUpdates()
                self?.staticTableView?.invalidateIntrinsicContentSize()
                self?.staticTableView?.endUpdates()
            }
        }
    }
    
    func setupClear(_ cell: UITableViewCell) {
        cell.backgroundColor = .clear
        cell.backgroundView?.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }
}
