//
//  CountdownDisplayService.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import CocoaLumberjackSwift
import Foundation
import UIKit

@objc protocol CountdownDisplayDelegate: AnyObject {
    func didFinishCountdown()
}

protocol CountdownDisplayService: AnyObject {
    
    var seconds: TimeInterval { get set }
    
    var delegates: [WeakObject<CountdownDisplayDelegate>?] { get set }
    
    func startUpdating(hourLabel: UILabel?, minuteLabel: UILabel?, secondLabel: UILabel)
    
    func startUpdating(button: UIButton)
    
    func pauseUpdating()
    
    func stopAndRemoveLTO()
}

final class BaseCountdownDisplayService: CountdownDisplayService {
    
    static let shared: CountdownDisplayService = BaseCountdownDisplayService(seconds: 60)
    
    private weak var button: UIButton?
    private weak var hourLabel: UILabel?
    private weak var minuteLabel: UILabel?
    private weak var secondLabel: UILabel?
    
    var seconds: TimeInterval
    
    var delegates: [WeakObject<CountdownDisplayDelegate>?] = []
    
    private var timer: Timer?
    
    private init(seconds: TimeInterval) {
        self.seconds = seconds
    }
    
    func startUpdating(hourLabel: UILabel? = nil, minuteLabel: UILabel? = nil, secondLabel: UILabel) {
        self.hourLabel = hourLabel
        self.minuteLabel = minuteLabel
        self.secondLabel = secondLabel
        
        timer?.invalidate()
        runTimer {
            DDLogInfo("Started updating LTO labels.")
            self.updateLabels()
        }
    }
    
    func startUpdating(button: UIButton) {
        self.button = button
        
        timer?.invalidate()
        runTimer {
            DDLogInfo("Started updating LTO button.")
            DispatchQueue.main.async {
                self.updateButton()
            }
        }
    }
    
    func pauseUpdating() {
        timer?.invalidate()
        timer = nil
    }
    
    func stopAndRemoveLTO() {
        BasePaywallService.shared.context = .normal
        DDLogInfo("Finished countdown. Changing context to \(BasePaywallService.shared.context).")
        
        DDLogInfo("Notifying all delegates.")
        self.delegates.forEach { $0?.object?.didFinishCountdown() }
        
        DDLogInfo("Clearing singleton references.")
        self.clearAllData()
    }
    
    private func runTimer(updateUI: @escaping () -> Void) {
        forceUpdate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            
            if self.seconds > 0 {
                self.seconds -= 1
                updateUI()
            } else {
                self.stopAndRemoveLTO()
            }
        }
    }
    
    private func forceUpdate() {
        updateLabels()
        updateButton()
    }
    
    private func updateButton() {
        let minutes = self.timeString(for: .minute)
        let seconds = self.timeString(for: .second)
        
        let timeString = minutes + ":" + seconds
        
        button?.setTitle(timeString, for: .normal)
    }
    
    private func updateLabels() {
        DispatchQueue.main.async {
            self.hourLabel?.text = self.timeString(for: .hour)
            self.minuteLabel?.text = self.timeString(for: .minute)
            self.secondLabel?.text = self.timeString(for: .second)
        }
    }
    
    private func timeString(for component: CountdownDisplayComponent) -> String {
        let time: Int
        
        switch component {
        case .hour:
            time = Int(seconds) / 3600
        case .minute:
            time = Int(seconds) / 60 % 60
        case .second:
            time = Int(seconds) % 60
        }
        
        return String(format:"%02i", time)
    }
    
    private func clearAllData() {
        pauseUpdating()
        
        delegates = []
        button = nil
        hourLabel = nil
        minuteLabel = nil
        secondLabel = nil
    }
}

enum CountdownDisplayComponent {
    case hour, minute, second
}
