//
//  WhatIsVpnViewController.swift
//  Lockdown
//
//  Created by Johnny Lin on 08/23/19.
//  Copyright © 2019 Confirmed. All rights reserved.
//

import Foundation
import UIKit
import AwesomeSpotlightView
import NicoProgress

class WhatIsVpnViewController: BaseViewController, AwesomeSpotlightViewDelegate {
    
    var is4InchIphone = UIDevice.is4InchIphone
    
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var dataFlow: NicoProgressBar!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet var descriptionLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var vpnActiveLabel: UILabel!
    var privacyEnabled = false
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var toggleCircle: UIButton!
    @IBOutlet weak var toggleAnimatedCircle: NVActivityIndicatorView!
    @IBOutlet weak var button: UIButton!
    
    var parentVC: HomeViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // iPhone SE
        if self.is4InchIphone {
            descriptionLabelHeight.constant = 0
        }
        
        if VPNController.shared.status() != .invalid {
            self.getStartedButton.alpha = 0
        }
        
        setPrivacyState(state: false)

        dataFlow.primaryColor = .orange
        dataFlow.secondaryColor = .tunnelsWarning
    }
    
    @IBAction func getStartedTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            guard let parentVC = self.parentVC else { return }
            BasePaywallService.shared.showPaywall(on: parentVC)
        })
    }
    
    @IBAction func learnMoreTapped(_ sender: Any) {
        showVPNDetails()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let spotlightRect = getRectForView(toggleCircle).insetBy(dx: -20.0, dy: -20.0)
        let spotlightText: String = .localized("Tap to see a demo of how Secure Tunnel protects and anonymizes you.")
        let s1 = AwesomeSpotlight(withRect: spotlightRect, shape: .circle, text: spotlightText)
        let spotlightView = AwesomeSpotlightView(frame: view.frame,
                                                 spotlight: [s1])
        spotlightView.cutoutRadius = 8
        spotlightView.spotlightMaskColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        spotlightView.enableArrowDown = true
        spotlightView.textLabelFont = .mediumLockdownFont(size: 16)
        spotlightView.labelSpacing = 24
        spotlightView.delegate = self
        view.addSubview(spotlightView)
        spotlightView.start()
    }
    
    func setPrivacyState(state: Bool) {
        privacyEnabled = state
        if state == true {
            vpnActiveLabel.text = .localized("Activating").uppercased()
            vpnActiveLabel.backgroundColor = .tunnelsBlue
            
            toggleCircle.isHidden = true
            toggleAnimatedCircle.color = .tunnelsBlue
            toggleAnimatedCircle.startAnimating()
            button.tintColor = .tunnelsBlue
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                self.toggleAnimatedCircle.stopAnimating()
                
                self.toggleCircle.isHidden = false
                self.toggleCircle.tintColor = .tunnelsBlue
                
                self.vpnActiveLabel.text = .localized("Tunnel On").uppercased()
                self.vpnActiveLabel.backgroundColor = .tunnelsBlue
                self.locationLabel.text = .localized("Location: 🇯🇵")
                self.ipLabel.text = .localized("IP: [Anonymized]")
                self.dataLabel.text = "AC90BD4B0A53ED74543425B269\n62179C21D8DAF733EB16F4B41F"
                self.dataFlow.primaryColor = .blue
                self.dataFlow.secondaryColor = .tunnelsBlue
                self.descriptionLabel.attributedText = self.add(stringList: [
                    .localized("Location changed and hidden"),
                    .localized("Anonymize IP against trackers"),
                    .localized("Encrypted, private connections")
                    ],
                                                                font: .semiboldLockdownFont(size: 15.5),
                                                                bulletFont: .mediumLockdownFont(size: 18),
                                                      bullet: "•",
                                                      textColor: .tunnelsBlue,
                                                      bulletColor: .tunnelsBlue)
            })
        } else {
            
            toggleCircle.tintColor = .lightGray
            toggleCircle.isHidden = false
            toggleAnimatedCircle.stopAnimating()
            button.tintColor = .lightGray
            
            locationLabel.text = .localized("Location: 🇺🇸")
            ipLabel.text = .localized("IP: 18.132.2.87")
            dataLabel.text = .localized("To: joe@email.com\nRe: Q4 2019 Finance Review")
            dataFlow.primaryColor = .orange
            dataFlow.secondaryColor = .tunnelsWarning
            vpnActiveLabel.text = .localized("Tunnel Off").uppercased()
            vpnActiveLabel.backgroundColor = .tunnelsWarning
            descriptionLabel.attributedText = add(stringList: [
                .localized("Precise location exposed"),
                .localized("Unique IP address broadcasted"),
                .localized("Readable browsing and data")
                ],
                                                  font: .semiboldLockdownFont(size: 15.5),
                                                  bulletFont: .mediumLockdownFont(size: 18),
                                          bullet: "•",
                                          textColor: .tunnelsWarning,
                                          bulletColor: .tunnelsWarning)
        }
    }
    
    @IBAction func privTapped(_ sender: Any) {
        if privacyEnabled == true {
            setPrivacyState(state: false)
        } else {
            setPrivacyState(state: true)
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func add(stringList: [String],
             font: UIFont,
             bulletFont: UIFont,
             bullet: String = "\u{2022}",
             indentation: CGFloat = 17,
             lineSpacing: CGFloat = 1.35,
             paragraphSpacing: CGFloat = 6,
             textColor: UIColor = .darkGray,
             bulletColor: UIColor = .darkGray) -> NSAttributedString {
        
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let bulletAttributes: [NSAttributedString.Key: Any] = [.font: bulletFont, .foregroundColor: bulletColor]
        
        let paragraphStyle = NSMutableParagraphStyle()
        let nonOptions = [NSTextTab.OptionKey: Any]()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: indentation, options: nonOptions)]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        
        let bulletList = NSMutableAttributedString()
        for string in stringList {
            let formattedString = "\(bullet)\t\(string)\n"
            let attributedString = NSMutableAttributedString(string: formattedString)
            
            attributedString.addAttributes(
                [NSAttributedString.Key.paragraphStyle: paragraphStyle],
                range: NSRange(location: 0, length: attributedString.length))
            
            attributedString.addAttributes(
                textAttributes,
                range: NSRange(location: 0, length: attributedString.length))
            
            let string: NSString = NSString(string: formattedString)
            let rangeForBullet: NSRange = string.range(of: bullet)
            attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            bulletList.append(attributedString)
        }
        
        return bulletList
    }
    
}
