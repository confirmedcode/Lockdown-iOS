//
//  CustomUISwitch.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 26.04.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

import CoreMotion

final class CustomUISwitch: UIButton {
    
    var status: Bool = false {
        didSet {
            self.update()
        }
    }
    
    var onImage: UIImage?
    var offImage: UIImage?
    
    init(onImage: UIImage, offImage: UIImage) {
        self.onImage = onImage
        self.offImage = offImage
        super.init(frame: CGRect.zero)
        self.setStatus(false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        UIView.transition(with: self, duration: 0.10, options: .transitionCrossDissolve, animations: {
            self.status ? self.setImage(self.onImage, for: .normal) : self.setImage(self.offImage, for: .normal)
        }, completion: nil)
    }
    
    func toggle() {
        self.status ? self.setStatus(false) : self.setStatus(true)
    }
    
    func setStatus(_ status: Bool) {
        self.status = status
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.sendHapticFeedback()
        self.toggle()
    }
    
    func sendHapticFeedback() {
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedbackgenerator.prepare()
        impactFeedbackgenerator.impactOccurred()
    }
}
