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
        textView.font = .regularLockdownFont(size: 16)
        textView.backgroundColor = .clear
        textView.textColor = .label
        textView.isScrollEnabled = false
        return textView
    }()
    
    private(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .regularLockdownFont(size: 16)
        label.textColor = .label
        label.alpha = 0.3
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
        backgroundColor = .tableCellBackground
        layer.cornerRadius = 10
        
        addSubview(textView)
        textView.anchors.edges.pin(insets: .init(top: 10, left: 14, bottom: 10, right: 14))
        textView.anchors.height.greaterThanOrEqual(108)
        
        addSubview(placeholderLabel)
        placeholderLabel.anchors.leading.pin(inset: 18)
        placeholderLabel.anchors.top.pin(inset: 18)
        placeholderLabel.anchors.trailing.pin(inset: 18)
    }
}

extension TextViewWithPlaceholder: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        textDidChanged?(textView.text)
    }
}
