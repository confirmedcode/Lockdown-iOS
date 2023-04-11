//
//  CustomTableView.swift
//
//  Created by Aliaksandr Dvoineu on 16.03.23.
//

import UIKit

class TableViewHeader: UIView {
    
    lazy var view: UIView = {
        let view = UIView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        addSubview(view)
        view.anchors.edges.pin()
    }
}

class CustomTableViewCell: UITableViewCell {
    var selectionCallback: () -> () = { }
    var deletionCallback: (() -> ())?
    
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
    func onSwipeToDelete(callback: @escaping () -> ()) -> Self {
        deletionCallback = callback
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

final class CustomTableView: UITableView {
    
    // Resizing UITableView to fit content
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
    
    var rows: [CustomTableViewCell] = []
    var deselectsCellsAutomatically: Bool = false
    var headerView = TableViewHeader()
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: .insetGrouped)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    func addHeader(_ configure: (UIView) -> ()) -> TableViewHeader {
        let header = headerView
        configure(header.view)
        return header
    }
    
    @discardableResult
    func addRow(insert: Insert = .last, _ configure: (UIView) -> ()) -> CustomTableViewCell {
        let cell = CustomTableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = nil
        configure(cell.contentView)
        self.insert(cell: cell, insert: insert)
        return cell
    }
    
    @discardableResult
    func addRowCell(insert: Insert = .last, _ configure: (UITableViewCell) -> ()) -> CustomTableViewCell {
        let cell = CustomTableViewCell()
        cell.selectionStyle = .none
        configure(cell)
        self.insert(cell: cell, insert: insert)
        return cell
    }
    
    @discardableResult
    func addCell(insert: Insert = .last, _ cell: CustomTableViewCell) -> CustomTableViewCell {
        self.insert(cell: cell, insert: insert)
        return cell
    }
    
    @discardableResult
    func addRow(insert: Insert = .last, view: UIView, insets: UIEdgeInsets = .zero) -> CustomTableViewCell {
        return addRow(insert: insert) { (row) in
            row.addSubview(view)
            view.anchors.edges.pin(axis: .vertical)
            view.anchors.edges.marginsPin(insets: insets, axis: .horizontal)
        }
    }
    
    private func insert(cell: CustomTableViewCell, insert: Insert) {
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
    
}

extension CustomTableView: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = headerView
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return rows[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let cell = rows[indexPath.row]
        return cell.deletionCallback != nil
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let cell = rows[indexPath.row]
        guard cell.deletionCallback != nil else {
            return
        }
        cell.deletionCallback?()
        self.rows.removeAll(where: { $0 === cell })
        self.deleteRows(at: [indexPath], with: .fade)
    }
}

extension CustomTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if let cell = tableView.cellForRow(at: indexPath) as? CustomTableViewCell {
            return cell.selectionStyle != .none
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? CustomTableViewCell {
            cell.selectionCallback()
            if deselectsCellsAutomatically {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}
