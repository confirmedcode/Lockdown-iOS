//
//  TextBox.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/3/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

internal final class TextBox: UIView {
    
    private let leftTextMargin: CGFloat = 16

    private(set) var state = TextInputState.placeholder

    var title: String? {
        didSet {
            titleLabel.text = title
            titlePlaceholderLabel.text = title
        }
    }

    var titleColor: UIColor? {
        didSet {
            titleLabel.textColor = titleColor
            titlePlaceholderLabel.textColor = titleColor
        }
    }

    var placeholderFont: UIFont? = .regularLockdownFont(size: 17) {
        didSet {
            titlePlaceholderLabel.font = placeholderFont
            placeholderLabel.font = placeholderFont
        }
    }

    let titleLabel: UILabel = TextBoxLabel(fontSize: UIFont.smallSystemFontSize)
    let titlePlaceholderLabel: UILabel = TextBoxLabel()
    let placeholderLabel: UILabel = TextBoxLabel()

    private let titleBottomSpace: CGFloat = 2
    private let placeholderBottom: CGFloat = 6

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    // MARK: - Internal

    var editingTextInsets: UIEdgeInsets {
        return UIEdgeInsets(
            top: titleLabel.font.lineHeight + titleBottomSpace,
            left: leftTextMargin,
            bottom: 0,
            right: leftTextMargin)
    }

    func setState(_ newState: TextInputState, animated: Bool) {
        let oldSate = state
        state = newState
        let isAnimated = animated && window != nil && frame != .zero

        switch (oldSate, newState, isAnimated) {
        case (_, .empty, true):
            moveTitleDown()
        case (.empty, .placeholder, true):
            moveTitleUp()
        default:
            stateDidUpdate()
        }
    }

    // MARK: - Private

    private func commonInit() {
        isUserInteractionEnabled = false
        let subviews = [
            titleLabel,
            titlePlaceholderLabel,
            placeholderLabel
        ]
        for subview in subviews {
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.isUserInteractionEnabled = false
            addSubview(subview)
        }
        setupConstraints()
        // debug()
    }

    private func setupConstraints() {
        layoutMargins = .zero

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: leftTextMargin),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),

            titlePlaceholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titlePlaceholderLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: leftTextMargin),
            titlePlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),

            placeholderLabel.topAnchor.constraint(equalTo: titlePlaceholderLabel.topAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func stateDidUpdate() {
        updateTitle()
        updatePlaceholder()
    }

    private func updateTitle() {
        switch state {
        case .empty:
            titleLabel.isHidden = true
            titlePlaceholderLabel.isHidden = false
        case .text, .placeholder, .textInput:
            titleLabel.isHidden = false
            titlePlaceholderLabel.isHidden = true
        }
    }

    private func updatePlaceholder() {
        placeholderLabel.alpha = (state == .placeholder) ? 1 : 0
    }

    private func moveTitleDown() {
        titlePlaceholderLabel.transform = transform(
            from: titleLabel.frame,
            to: titlePlaceholderLabel.frame)
        animateTitles()
    }

    private func moveTitleUp() {
        titleLabel.transform = transform(
            from: titlePlaceholderLabel.frame,
            to: titleLabel.frame)
        animateTitles()
    }

    private func animateTitles() {
        updateTitle()
        UIView.animate(withDuration: 0.25) {
            self.titleLabel.transform = .identity
            self.titlePlaceholderLabel.transform = .identity
            self.updatePlaceholder()
        }
    }

    private func transform(from source: CGRect, to destination: CGRect) -> CGAffineTransform {
        let scaleX = source.width / destination.width
        let scaleY = source.height / destination.height

        let translationX = source.origin.x - destination.origin.x - (destination.width * (1.0 - scaleX) / 2)
        let translationY = source.origin.y - destination.origin.y - (destination.height * (1.0 - scaleY) / 2)

        return CGAffineTransform(translationX: translationX, y: translationY).scaledBy(x: scaleX, y: scaleY)
    }
}
