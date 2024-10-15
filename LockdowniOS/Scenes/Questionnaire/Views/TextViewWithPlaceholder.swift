//
//  TextViewWithPlaceholder.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 23.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

class TextViewWithPlaceholder: UIView {
    
    var textDidChanged: ((String) -> Void)?
    
    private(set) lazy var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.font = .regularLockdownFont(size: 12)
        textView.backgroundColor = .clear
        textView.textColor = .label
        textView.isScrollEnabled = false
        return textView
    }()
    
    private(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .regularLockdownFont(size: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .tableCellBackground
        backgroundView.layer.cornerRadius = 8
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = UIColor.secondaryLabel.cgColor
        addSubview(backgroundView)
        backgroundView.anchors.edges.pin(insets: .init(top: 10, left: 23, bottom: 0, right: 23))

        addSubview(textView)
        textView.anchors.edges.pin(insets: .init(top: 15, left: 32, bottom: 0, right: 23))
        textView.anchors.height.greaterThanOrEqual(95)
        
        addSubview(placeholderLabel)
        placeholderLabel.anchors.leading.pin(inset: 36)
        placeholderLabel.anchors.top.pin(inset: 18 + 5)
        placeholderLabel.anchors.trailing.pin(inset: 36)
    }
}

extension TextViewWithPlaceholder: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        textDidChanged?(textView.text)
    }
}
