//
//  EnableNotificationsViewController.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 11/9/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import CocoaLumberjackSwift
import UIKit

final class EnableNotificationsViewController: UIViewController {
    
    @IBOutlet private var stayInLoopLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    
    @IBOutlet private var imageBackgroundView: UIView!
    @IBOutlet private var enableNotificationsButton: UIButton!
    @IBOutlet private var maybeLaterButton: UIButton!
    
    private var onAgreed: (() -> Void)?
    
    init(onAgreed: (() -> Void)? = nil) {
        self.onAgreed = onAgreed
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTexts()
        updateImageBackgroundView()
        
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        navigationController?.navigationBar.tintColor = .label
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        enableNotificationsButton.applyGradient(.lightBlue, corners: .continuous(enableNotificationsButton.bounds.midY))
    }
    
    @IBAction private func didTapEnableNotifications(_ sender: Any) {
        OneTimeActions.markAsSeen(.newEnableNotificationsController)
        
        enableNotificationsButton.showAnimatedPress { [weak self] in
            self?.askForNotificationsPermission()
        }
    }
    
    @IBAction private func didTapMaybeLater(_ sender: Any) {
        OneTimeActions.markAsSeen(.newEnableNotificationsController)
        
        if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            switchToMainAppScreen()
        }
    }
    
    private func setupTexts() {
        stayInLoopLabel.text = .localized("stay_in_the_loop")
        descriptionLabel.text = .localized("once_a_week_helpful_reminders")
        
        enableNotificationsButton.setTitle(.localized("enable_notifications"), for: .normal)
        maybeLaterButton.setTitle(.localized("maybe_later"), for: .normal)
    }
    
    private func updateImageBackgroundView() {
        imageBackgroundView.corners = .continuous(26)
        imageBackgroundView.backgroundColor = .fromHex("0366DA").withAlphaComponent(isDarkMode ? 0.15 : 0.05)
    }
}

extension EnableNotificationsViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateImageBackgroundView()
    }
}

extension EnableNotificationsViewController {
    private func askForNotificationsPermission() {
        PushNotifications.Authorization.setUserWantsNotificationsEnabled(true, forCategory: .weeklyUpdate)
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized, .notDetermined:
                
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (isSuccess, error) in
                    if let error {
                        DDLogWarn(error.localizedDescription)
                    } else if isSuccess {
                        DDLogInfo("Successfully authorized notifications.")
                    }
                    
                    // If we have a presenting view controller, then it was shown from Account Tab.
                    // Otherwise, it was shown from onboarding/signup.
                    DispatchQueue.main.async {
                        if self.presentingViewController != nil {
                            self.dismiss(animated: true) {
                                if isSuccess {
                                    self.onAgreed?()
                                } else {
                                    PushNotifications.Authorization.setUserWantsNotificationsEnabled(false, forCategory: .weeklyUpdate)
                                }
                            }
                        } else {
                            self.switchToMainAppScreen()
                            
                            if isSuccess {
                                self.onAgreed?()
                            } else {
                                PushNotifications.Authorization.setUserWantsNotificationsEnabled(false, forCategory: .weeklyUpdate)
                            }
                        }
                    }
                }
            case .denied:
                PushNotifications.Authorization.setUserWantsNotificationsEnabled(false, forCategory: .weeklyUpdate)
                DispatchQueue.main.async {
                    PushNotifications.Authorization.showGoToSettingsPopup(on: self) {}
                }
            default:
                break
            }
        }
    }
    
    private func switchToMainAppScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            guard let keyWindow else { return }
            self.transition(with: keyWindow, duration: 1, options: [.preferredFramesPerSecond60, .transitionFlipFromLeft]) {
                keyWindow.rootViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "MainTabBarController")
                keyWindow.makeKeyAndVisible()
            }
        }
    }
}
