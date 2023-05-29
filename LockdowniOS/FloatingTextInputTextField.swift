//
//  FloatingTextField.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/3/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

open class FloatingTextInputTextField: UITextField {

    /// Container with additional labels
    let textBox = TextBox()

    private var rightViews = [TextInputState: UIView]()
    private var borderLayer: CALayer?

    @IBInspectable open var title: String? {
        get { return textBox.title }
        set { textBox.title = newValue }
    }

    open var titleFont: UIFont? {
        get { return textBox.titleLabel.font }
        set { textBox.titleLabel.font = newValue }
    }

    @IBInspectable open var titleColor: UIColor? {
        get { return textBox.titleColor }
        set { textBox.titleColor = newValue }
    }

    open var placeholderFont: UIFont? {
        get { return textBox.placeholderFont }
        set { textBox.placeholderFont = newValue }
    }

    @IBInspectable open var placeholderColor: UIColor? {
        get { return textBox.placeholderLabel.textColor }
        set { textBox.placeholderLabel.textColor = newValue }
    }

    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    open func commonInit() {
        if let text = super.placeholder {
            super.placeholder = nil
            placeholder = text
        }
        setUpTextBoxConstraints()
        setupActions()
        updateState(animated: false)
        adjustsFontForContentSizeCategory = true
        rightViewMode = .always
        layer.masksToBounds = true
        layer.borderColor = UIColor.fromHex("#00ADE7").cgColor
        corners = .continuous(8)
    }

    // MARK: - Public

    @objc open func clear() {
        if delegate?.textFieldShouldClear?(self) == false { return }
        super.text = nil // в `self.text` обновление текста происходит без анимации
        updateState(animated: true)
        sendActions(for: .editingChanged)
    }

    open func setRigthView(_ view: UIView?, for state: TextInputState) {
        rightViews[state] = view
        updateState(animated: false)
    }

    open func rigthView(for state: TextInputState) -> UIView? {
        return rightViews[state]
    }

    // MARK: - UITextInput

    // If font size of placeholder and of text in UITextField are different,
    // the caret height (and hence that of the whole textField) will be changing.
    // To avoid this, we equal the caret height to placeholderLabel font size.
    override open func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        rect.size.height = textBox.placeholderLabel.font.lineHeight
        return rect
    }

    // MARK: - UITextField

    override open var text: String? {
        didSet { updateState(animated: false) }
    }

    override open var placeholder: String? {
        get { return textBox.placeholderLabel.text }
        set { textBox.placeholderLabel.text = newValue }
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textBox.editingTextInsets).integral
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textBox.editingTextInsets).integral
    }

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textBox.editingTextInsets).integral
    }

    override open func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return super.rightViewRect(forBounds: bounds.inset(by: layoutMargins))
    }

    // MARK: - UIView

    override open func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        textBox.layoutMargins = layoutMargins
    }

    // MARK: - Private

    private func setupActions() {
        [.editingDidBegin, .editingChanged, .editingDidEnd].forEach {
            addTarget(self, action: #selector(textDidEditing), for: $0)
        }
    }

    @objc private func textDidEditing() {
        updateState(animated: true)
    }

    private func updateState(animated: Bool) {
        let state = TextInputState(hasText: hasText, firstResponder: isFirstResponder)
        rightView = rigthView(for: state)
        textBox.setState(state, animated: animated)
    }

    private func setUpTextBoxConstraints() {
        addSubview(textBox)
        textBox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textBox.topAnchor.constraint(equalTo: topAnchor),
            textBox.leadingAnchor.constraint(equalTo: leadingAnchor),
            textBox.trailingAnchor.constraint(equalTo: trailingAnchor),
            textBox.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
