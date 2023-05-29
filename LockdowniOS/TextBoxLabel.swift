//
//  TextBoxLabel.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/3/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

final class TextBoxLabel: UILabel {

    private var savesHeight = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    convenience init(fontSize: CGFloat, savesHeight: Bool = true) {
        self.init(frame: .zero)
        font = .systemFont(ofSize: fontSize)
        self.savesHeight = savesHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        adjustsFontForContentSizeCategory = true
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize

        if savesHeight {
            return CGSize(width: size.width, height: font.lineHeight)
        }
        return size
    }
}
