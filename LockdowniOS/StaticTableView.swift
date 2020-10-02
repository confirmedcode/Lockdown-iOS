//
//  StaticTableView.swift
//  Private Analytics
//
//  Created by Oleg Dreyman on 21.08.2020.
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import UIKit

final class StaticTableView: UITableView {
    
    var rows: [SelectableTableViewCell] = []
    var deselectsCellsAutomatically: Bool = false
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setup()
    }
    
    func setup() {
        dataSource = self
        delegate = self
        separatorStyle = .none
    }
    
    enum Insert {
        case last
        case dontInsert
    }
    
    @discardableResult
    func addRow(insert: Insert = .last, _ configure: (UIView) -> ()) -> SelectableTableViewCell {
        let cell = SelectableTableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = nil
        configure(cell.contentView)
        self.insert(cell: cell, insert: insert)
        return cell
    }
    
    @discardableResult
    func addRowCell(insert: Insert = .last, _ configure: (UITableViewCell) -> ()) -> SelectableTableViewCell {
        let cell = SelectableTableViewCell()
        cell.selectionStyle = .none
        configure(cell)
        self.insert(cell: cell, insert: insert)
        return cell
    }
    
    @discardableResult
    func addCell(insert: Insert = .last, _ cell: SelectableTableViewCell) -> SelectableTableViewCell {
        self.insert(cell: cell, insert: insert)
        return cell
    }
    
    @discardableResult
    func addRow(insert: Insert = .last, view: UIView, insets: UIEdgeInsets = .zero) -> SelectableTableViewCell {
        return addRow(insert: insert) { (row) in
            row.addSubview(view)
            view.anchors.edges.pin(axis: .vertical)
            view.anchors.edges.marginsPin(insets: insets, axis: .horizontal)
        }
    }
    
    private func insert(cell: SelectableTableViewCell, insert: Insert) {
        switch insert {
        case .dontInsert:
            break
        case .last:
            rows.append(cell)
        }
    }
    
    func clear() {
        rows = []
    }
    
//    override func touchesShouldCancel(in view: UIView) -> Bool {
//        if view is UIControl {
//            return true
//        }
//        return super.touchesShouldCancel(in: view)
//    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SelectableTableViewCell: UITableViewCell {
    var selectionCallback: () -> () = { }
    
    enum Action {
        case toggleCheckmark
    }
    
    @discardableResult
    func onSelect(callback: @escaping () -> ()) -> Self {
        selectionStyle = .default
        selectionCallback = callback
        return self
    }
    
    @discardableResult
    func onSelect(_ action: Action, callback: @escaping () -> () = { }) -> Self {
        selectionCallback = { [unowned self] in
            switch action {
            case .toggleCheckmark:
                if self.accessoryType == .checkmark {
                    self.accessoryType = .none
                } else {
                    self.accessoryType = .checkmark
                }
            }
            callback()
        }
        return self
    }
}

extension StaticTableView: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return rows[indexPath.row]
    }
}

extension StaticTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if let cell = tableView.cellForRow(at: indexPath) as? SelectableTableViewCell {
            return cell.selectionStyle != .none
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? SelectableTableViewCell {
            cell.selectionCallback()
            if deselectsCellsAutomatically {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}
