//
//  ProgressView.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/28/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

final class ProgressView: UIView {

    var progress: Float = 0 {
        didSet {
            updateProgressView()
        }
    }
    
    var progressTintColor: UIColor = .white {
        didSet {
            updateProgressView()
        }
    }
    
    var progressBackgroundColor: UIColor = .white.withAlphaComponent(0.25) {
        didSet {
            updateProgressView()
        }
    }

    private let progressView = UIView()
    private var progressViewWidthConstraint: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)

        clipsToBounds = true

        addSubview(progressView)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        progressView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        progressViewWidthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)
        progressViewWidthConstraint?.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateProgressView()
        corners = .continuous(bounds.midY)
    }

    func updateProgressView() {
        backgroundColor = progressBackgroundColor
        progressView.backgroundColor = progressTintColor
        
        progressViewWidthConstraint?.constant = bounds.width * CGFloat(progress)
    }
    
    private func updateColors() {
        backgroundColor = progressBackgroundColor
    }
}
