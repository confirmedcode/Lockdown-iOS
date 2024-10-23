//
//  FeedbackPaywallViewController.swift
//  Lockdown
//
//  Created by Fabian Mistoiu on 10.10.2024.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import UIKit
import Combine

class FeedbackPaywallViewController: UIViewController {

    private let viewModel: FeedbackPaywallViewModel
    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: FeedbackPaywallViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .feedbackText
        button.setTitle(Copy.close, for: .normal)
        button.titleLabel?.font = .close
        button.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                self.viewModel.onCloseHandler?(self)
            },
            for: .touchUpInside)
        return button
    }()

    private lazy var bannerView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "feedback-paywall-banner"))
        imageView.translatesAutoresizingMaskIntoConstraints = false

        imageView.addSubview(bannerArrowImageView)
        NSLayoutConstraint.activate([
            bannerArrowImageView.centerYAnchor.constraint(equalTo: imageView.bottomAnchor),
            bannerArrowImageView.centerXAnchor.constraint(equalTo: imageView.rightAnchor, constant: -10),
            bannerArrowImageView.widthAnchor.constraint(equalToConstant: 92),
            bannerArrowImageView.heightAnchor.constraint(equalToConstant: 92),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1072 / 687),
            imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 420)
        ])

        return imageView
    }()

    private lazy var bannerArrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "feedback-paywall-arrow"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .feedbackText

        let continueRange = (Copy.title as NSString).range(of: Copy.titleHighlight)
        let attributedString = NSMutableAttributedString(
            string: Copy.title,
            attributes: [.font:  UIFont.title as Any])
        attributedString.addAttribute(.foregroundColor, value: UIColor.feedbackBlue as Any, range: continueRange)

        label.attributedText = attributedString
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .feedbackText
        label.font = .description
        label.text = Copy.description
        return label
    }()

    private lazy var bulletPointContainer: UIView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 5

        [Copy.bulletPoint1, Copy.bulletPoint2, Copy.bulletPoint3]
            .map { createBulletPointView(copy: $0) }
            .forEach { stackView.addArrangedSubview($0) }
        return stackView
    }()


    private lazy var bottomContainer: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [continueButton, linksContainer])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.setCustomSpacing(17, after: continueButton)

        return stackView
    }()

    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setTitle(Copy.continue, for: .normal)
        button.titleLabel?.font = .ctaButton
        button.backgroundColor = .feedbackBlue
        button.layer.cornerRadius = 29
        button.anchors.height.equal(58)
        button.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                let pID = viewModel.paywallPlans[viewModel.selectedPlanIndex].id
                viewModel.onPurchaseHandler?(self, pID)
            },
            for: .touchUpInside)
        return button
    }()

    private lazy var linksContainer: UIView = {
        let linkButtons = [
            createLinkButton(title: Copy.terms, url: URL(string: "https://lockdownprivacy.com/terms")!),
            createLinkButton(title: Copy.privacy, url: URL(string: "https://lockdownprivacy.com/privacy")!)
        ]

        let stackView = UIStackView(arrangedSubviews: linkButtons)
        stackView.distribution = .fillEqually
        return stackView
    }()

    private var planButtons: [PlanContainer] = []

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background

        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            closeButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 17)
        ])

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 28 + 16),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        let bannerImageContainer = UIView()
        bannerImageContainer.translatesAutoresizingMaskIntoConstraints = false
        bannerImageContainer.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: bannerImageContainer.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: bannerImageContainer.bottomAnchor),
            bannerView.centerXAnchor.constraint(equalTo: bannerImageContainer.centerXAnchor)
        ])
        let bannerWidthConstraint = bannerView.widthAnchor.constraint(equalTo: bannerImageContainer.widthAnchor, multiplier: 0.8)
        bannerWidthConstraint.priority = .init(rawValue: 999)
        bannerWidthConstraint.isActive = true

        let copyStackView = UIStackView(arrangedSubviews: [bannerImageContainer, titleLabel, descriptionLabel, bulletPointContainer])
        copyStackView.translatesAutoresizingMaskIntoConstraints = false
        copyStackView.axis = .vertical
        copyStackView.alignment = .fill
        copyStackView.distribution = .fill
        copyStackView.spacing = 0
        copyStackView.setCustomSpacing(22, after: bannerImageContainer)
        copyStackView.setCustomSpacing(17, after: descriptionLabel)
        scrollView.addSubview(copyStackView)
        NSLayoutConstraint.activate([
            copyStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0),
            copyStackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            copyStackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 39),
            copyStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        view.addSubview(bottomContainer)
        NSLayoutConstraint.activate([
            bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            bottomContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomContainer.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 45),
            bottomContainer.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 10)
        ])

        viewModel.$paywallPlans.sink(receiveValue: { [weak self] plans in
            guard let self else { return }
            planButtons.forEach { $0.removeFromSuperview() }

            planButtons = plans.map { self.createPlanButton(title: $0.name, price: $0.price, period: $0.pricePeriod, promo: $0.promo) }
            planButtons.reversed().forEach { self.bottomContainer.insertArrangedSubview($0, at: 0) }
            if let lastButton = planButtons.last {
                bottomContainer.setCustomSpacing(30, after: lastButton)
            }

            selectButton(at: viewModel.selectedPlanIndex)
        }).store(in: &subscriptions)

        viewModel.$selectedPlanIndex.sink(receiveValue: { [weak self] selectedPlanIndex in
            guard let self else { return }
            selectButton(at: selectedPlanIndex)
        }).store(in: &subscriptions)
    }

    func selectButton(at selectedIndex: Int) {
        for (index, button) in planButtons.map(\.button).enumerated() {
            let selected = index == selectedIndex

            button.backgroundColor = selected ? .selectedPlanBackground : .clear
            button.titleLabel?.font = selected ? .selectedPlanTitle: .unselectedPlanTitle
            button.layer.borderColor = selected ? UIColor.feedbackBlue.cgColor : UIColor.smallGrey.cgColor
        }
    }

    // MARK: - UI helper

    private func createBulletPointView(copy: String) -> UIView {
        let bulletPointImageView = UIImageView(image: UIImage(named: "feedback-checkmark"))
        bulletPointImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bulletPointImageView.widthAnchor.constraint(equalToConstant: 9),
            bulletPointImageView.heightAnchor.constraint(equalToConstant: 6),
        ])
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = copy
        label.textColor = .feedbackText
        label.font = .bulletPoint

        let spacer = UIView()
        spacer.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalToConstant: 5),
            spacer.heightAnchor.constraint(equalToConstant: 5),
        ])

        let stackView = UIStackView(arrangedSubviews: [spacer, bulletPointImageView, label])
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }

    private func createPlanButton(title: String, price: String, period: String?, promo: String?) -> PlanContainer {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        button.layer.cornerRadius = 27
        button.layer.borderWidth = 1
        button.tintColor = .feedbackText
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .center
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 21, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(planSelected), for: .touchUpInside)

        let priceLabel = UILabel()
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.textColor = .feedbackText
        priceLabel.font = .planPrice
        priceLabel.text = price

        let pricePeriodLabel: UILabel? = if period != nil { UILabel() } else { nil }
        pricePeriodLabel?.translatesAutoresizingMaskIntoConstraints = false
        pricePeriodLabel?.textColor = .feedbackText
        pricePeriodLabel?.font = .planPeriod
        pricePeriodLabel?.text = period

        let stackView = UIStackView(arrangedSubviews: [priceLabel, pricePeriodLabel].compactMap { $0 })
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .trailing
        button.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            stackView.rightAnchor.constraint(equalTo: button.rightAnchor, constant: -18)
        ])

        var promoView: UIView?
        if let promo {
            let gradientView = GradientView()
            gradientView.translatesAutoresizingMaskIntoConstraints = false
            gradientView.gradient = .custom([UIColor.promoGradientStart.cgColor, UIColor.promoGradientStart.cgColor], .horizontal)
            gradientView.layer.cornerRadius = 11.5
            gradientView.clipsToBounds = true

            let promoLabel = UILabel()
            promoLabel.translatesAutoresizingMaskIntoConstraints = false
            promoLabel.textColor = .feedbackText
            promoLabel.font = .selectedPlanTitle
            promoLabel.text = promo

            gradientView.addSubview(promoLabel)
            NSLayoutConstraint.activate([
                promoLabel.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
                promoLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
                promoLabel.leftAnchor.constraint(equalTo: gradientView.leftAnchor, constant: 7),
                gradientView.heightAnchor.constraint(equalToConstant: 23)
            ])
            promoView = gradientView
        }

        return PlanContainer(button: button, promoLabel: promoView)
    }

    private func createLinkButton(title: String, url: URL) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = fontMedium13
        button.setTitle(title, for: .normal)
        button.tintColor = .feedbackText
        button.addAction(
            UIAction { _ in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            },
            for: .touchUpInside)
        return button
    }

    @objc func planSelected(_ sender: UIButton) {
        guard let index = planButtons.map(\.button).firstIndex(of: sender) else { return }
        viewModel.selectPlan(at: index)
    }
}

private class PlanContainer: UIView {
    let button: UIButton
    let promoLabel: UIView?

    init(button: UIButton, promoLabel: UIView?) {
        self.button = button
        self.promoLabel = promoLabel
        super.init(frame: .zero)

        addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leftAnchor.constraint(equalTo: leftAnchor),
            button.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        if let promoLabel {
            addSubview(promoLabel)
            NSLayoutConstraint.activate([
                promoLabel.centerYAnchor.constraint(equalTo: button.topAnchor),
                promoLabel.rightAnchor.constraint(equalTo: button.rightAnchor, constant: -18)
            ])
        }

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Copy {
    static var close: String = NSLocalizedString("CLOSE", comment: "")
    static var title: String = NSLocalizedString("Tap Continue to Activate this ONE TIME Offer", comment: "")
    static var titleHighlight: String = NSLocalizedString("Continue", comment: "")
    static var `continue`: String = NSLocalizedString("Continue", comment: "")
    static let description: String = NSLocalizedString("Private Browsing with Hidden IP and Global Region Switching", comment: "")
    static var bulletPoint1: String = NSLocalizedString("Anonymised browsing", comment: "")
    static var bulletPoint2: String = NSLocalizedString("Location and IP address hidden", comment: "")
    static var bulletPoint3: String = NSLocalizedString("Unlimited bandwidth and data usage & more", comment: "")
    static var terms: String = NSLocalizedString("Terms", comment: "")
    static var privacy: String = NSLocalizedString("Privacy", comment: "")

}

private extension UIFont {
    static let close = UIFont(name: "Montserrat-Bold", size: 13)
    static let title = UIFont(name: "SFProRounded-Semibold", size: 28)
    static let description = UIFont(name: "Montserrat-Regular", size: 14)
    static let bulletPoint = UIFont(name: "Montserrat-SemiBold", size: 12)
    static let ctaButton = UIFont(name: "Montserrat-SemiBold", size: 20)
    static let selectedPlanTitle = UIFont(name: "Montserrat-Bold", size: 12)
    static let unselectedPlanTitle = UIFont(name: "Montserrat-Medium", size: 12)
    static let planPrice = UIFont(name: "Montserrat-SemiBold", size: 14)
    static let planPeriod = UIFont(name: "Montserrat-Medium", size: 14)
}

private extension UIColor {
    static let background = UIColor.panelSecondaryBackground
    static let feedbackText = UIColor.label
    static let feedbackBlue = UIColor.fromHex("#00ADE7")
    static let selectedPlanBackground = feedbackBlue.withAlphaComponent(0.1)
    static let unselectedPlanBorder = UIColor.fromHex("#999999")
    static let promoGradientStart = UIColor.fromHex("#FB923C")
    static let promoGradientEnd = UIColor.fromHex("#EA580C")
}
