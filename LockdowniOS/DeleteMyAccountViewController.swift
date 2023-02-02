//
//  DeleteMyAccountViewController.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 10/17/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation
import MessageUI
import UIKit

final class DeleteMyAccountViewController: BaseViewController {
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var bodyLabel: UILabel!
    
    @IBOutlet private var proceedButton: UIButton!
    @IBOutlet private var exitButton: UIButton!
    
    private let userEmail: String
    
    init(userEmail: String) {
        self.userEmail = userEmail
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTexts()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        proceedButton.corners = .continuous(proceedButton.bounds.midY)
    }
    
    override func actionUponEmailComposeClosure() {
        dismiss(animated: true)
    }
    
    private func setupTexts() {
        titleLabel.text = .localized("delete_my_account")
        bodyLabel.text = .localized("by_proceeding_you_will_submit_request_for_deleting_account")
        
        proceedButton.setTitle(.localized("proceed"), for: .normal)
        exitButton.setTitle(.localizedCancel, for: .normal)
    }
    
    @IBAction private func didTapProceed(_ sender: Any) {
        let userId = keychain[kVPNCredentialsId] ?? "No userId"
        composeEmail(.deleteAccount(email: userEmail, userId: userId))
    }
    
    @IBAction private func didTapExit(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension DeleteMyAccountViewController: EmailComposable {}
