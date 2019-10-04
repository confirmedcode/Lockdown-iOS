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
    
    var parentVC: HomeViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // iPhone SE
        if (UIScreen.main.nativeBounds.height < 1200) {
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
            self.parentVC?.toggleVPNBodyView(animate: true, show: true)
            self.parentVC?.performSegue(withIdentifier: "showSignup", sender: self)
        })
    }
    
    @IBAction func learnMoreTapped(_ sender: Any) {
        showVPNDetails()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let s1 = AwesomeSpotlight(withRect: getRectForView(toggleCircle).insetBy(dx: -20.0, dy: -20.0), shape: .circle, text: NSLocalizedString("Tap to see a demo of how Secure Tunnel protects and anonymizes you.", comment: ""))
        let spotlightView = AwesomeSpotlightView(frame: view.frame,
                                                 spotlight: [s1])
        spotlightView.cutoutRadius = 8
        spotlightView.spotlightMaskColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75);
        spotlightView.enableArrowDown = true
        spotlightView.textLabelFont = fontMedium16
        spotlightView.labelSpacing = 24;
        spotlightView.delegate = self
        view.addSubview(spotlightView)
        spotlightView.start()
    }
    
    func setPrivacyState(state: Bool) {
        privacyEnabled = state
        if (state == true) {
            vpnActiveLabel.text = NSLocalizedString("ACTIVATING", comment: "")
            vpnActiveLabel.backgroundColor = .tunnelsBlue
            
            toggleCircle.isHidden = true
            toggleAnimatedCircle.color = .tunnelsBlue
            toggleAnimatedCircle.startAnimating()
            button.tintColor = .tunnelsBlue
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                self.toggleAnimatedCircle.stopAnimating()
                
                self.toggleCircle.isHidden = false
                self.toggleCircle.tintColor = .tunnelsBlue
                
                self.vpnActiveLabel.text = NSLocalizedString("TUNNEL ON", comment: "")
                self.vpnActiveLabel.backgroundColor = .tunnelsBlue
                self.locationLabel.text = NSLocalizedString("Location: 🇯🇵", comment: "")
                self.ipLabel.text = NSLocalizedString("IP: [Anonymized]", comment: "")
                self.dataLabel.text = "AC90BD4B0A53ED74543425B269\n62179C21D8DAF733EB16F4B41F"
                self.dataFlow.primaryColor = .blue
                self.dataFlow.secondaryColor = .tunnelsBlue
                self.descriptionLabel.attributedText = self.add(stringList: [
                    NSLocalizedString("Location changed and hidden", comment: ""),
                    NSLocalizedString("Anonymize IP against trackers", comment: ""),
                    NSLocalizedString("Encrypted, private connections", comment: "")
                    ],
                                                      font: fontSemiBold15_5,
                                                      bulletFont: fontMedium18,
                                                      bullet: "•",
                                                      textColor: .tunnelsBlue,
                                                      bulletColor: .tunnelsBlue)
            })
        }
        else {
            
            vpnActiveLabel.text = NSLocalizedString("TUNNEL OFF", comment: "")
            vpnActiveLabel.backgroundColor = .lightGray
            
            toggleCircle.tintColor = .lightGray
            toggleCircle.isHidden = false
            toggleAnimatedCircle.stopAnimating()
            button.tintColor = .lightGray
            
            locationLabel.text = NSLocalizedString("Location: 🇺🇸", comment: "")
            ipLabel.text = NSLocalizedString("IP: 18.132.2.87", comment: "")
            dataLabel.text = NSLocalizedString("To: joe@email.com\nRe: Q4 2019 Finance Review", comment: "")
            dataFlow.primaryColor = .orange
            dataFlow.secondaryColor = .tunnelsWarning
            vpnActiveLabel.text = NSLocalizedString("TUNNEL OFF", comment: "")
            vpnActiveLabel.backgroundColor = .tunnelsWarning
            descriptionLabel.attributedText = add(stringList: [
                NSLocalizedString("Precise location exposed", comment: ""),
                NSLocalizedString("Unique IP address broadcasted", comment: ""),
                NSLocalizedString("Readable browsing and data", comment: "")
                ],
                                          font: fontSemiBold15_5,
                                          bulletFont: fontMedium18,
                                          bullet: "•",
                                          textColor: .tunnelsWarning,
                                          bulletColor: .tunnelsWarning)
        }
    }
    
    @IBAction func privTapped(_ sender: Any) {
        if(privacyEnabled == true) {
            setPrivacyState(state: false)
        }
        else {
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
        
        let textAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: textColor]
        let bulletAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: bulletFont, NSAttributedString.Key.foregroundColor: bulletColor]
        
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
                [NSAttributedString.Key.paragraphStyle : paragraphStyle],
                range: NSMakeRange(0, attributedString.length))
            
            attributedString.addAttributes(
                textAttributes,
                range: NSMakeRange(0, attributedString.length))
            
            let string:NSString = NSString(string: formattedString)
            let rangeForBullet:NSRange = string.range(of: bullet)
            attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            bulletList.append(attributedString)
        }
        
        return bulletList
    }
    
}

