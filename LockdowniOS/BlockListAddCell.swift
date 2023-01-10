//
//  BlockListAddCell.swift
//  Lockdown
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit

class BlockListAddView: UIView {
    
    let textField = UITextField()
    
    init() {
        super.init(frame: .zero)
        didLoad()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didLoad() {
        textField.font = .regularLockdownFont(size: 17)
        textField.placeholder = "domain-to-block.com"
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .URL
        textField.textContentType = .URL
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no
        textField.smartQuotesType = .no
        textField.spellCheckingType = .no
        textField.returnKeyType = .done

        addSubview(textField)
        textField.anchors.width.equal(280)
        textField.anchors.centerX.align()
        textField.anchors.bottom.marginsPin(inset: 8)
        
        let label = UILabel()
        label.text = .localized("Add a domain to block")
        label.font = .regularLockdownFont(size: 14)
        addSubview(label)
        label.anchors.top.marginsPin()
        label.anchors.bottom.spacing(4, to: textField.anchors.top)
        label.anchors.leading.pin(to: textField)
        label.anchors.trailing.pin(to: textField)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add line to bottom of Add Domain Text Field
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: textField.frame.height + 2, width: textField.frame.width, height: 2)
        bottomLine.backgroundColor = UIColor.tunnelsBlue.cgColor
        textField.layer.addSublayer(bottomLine)
    }
}
