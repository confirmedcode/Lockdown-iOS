//
//  FeedbackFlow.swift
//  Lockdown
//
//  Created by Fabian Mistoiu on 15.10.2024.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import Foundation

protocol PurchaseHandler: AnyObject {
    func purchase(productId: String)
}

class FeedbackFlow {

    weak var presentingViewController: BaseViewController?
    weak var purchaseHandler: PurchaseHandler?

    init(presentingViewController: BaseViewController, purchaseHandler: PurchaseHandler) {
        self.presentingViewController = presentingViewController
        self.purchaseHandler = purchaseHandler
    }

    func startFlow() {
        let isPremiumUser = BaseUserService.shared.user.currentSubscription != nil
        let viewModel = StepsViewModel(isUserPremium: isPremiumUser) { [weak self] message in
            Task { @MainActor [weak self] in
                if !isPremiumUser {
                    await self?.showFeedbackPaywall()
                }
                self?.presentingViewController?.sendMessage(
                    message,
                    subject: "Lockdown Error Reporting Form (iOS \(Bundle.main.versionString))"
                )
            }
        }
        let stepsViewController = StepsViewController()
        stepsViewController.viewModel = viewModel
        stepsViewController.modalPresentationStyle = .fullScreen
        presentingViewController?.present(stepsViewController, animated: true)
    }

    @MainActor
    private func showFeedbackPaywall() async {
        guard let presentingViewController,
              let productInfos = await VPNSubscription.shared.loadSubscriptions(productIds: Set(VPNSubscription.feedbackProducts.toList())) else {
            return
        }

        let viewModel = FeedbackPaywallViewModel(products: VPNSubscription.feedbackProducts, subscriptionInfo: productInfos)
        viewModel.onCloseHandler = { vc in vc.dismiss(animated: true) }
        viewModel.onPurchaseHandler = { [weak self] _, pid in
            guard let purchaseHandler = self?.purchaseHandler else { return  }
            purchaseHandler.purchase(productId: pid)
        }
        let paywallVC = FeedbackPaywallViewController(viewModel: viewModel)
        presentingViewController.present(paywallVC, animated: true)
    }
}
