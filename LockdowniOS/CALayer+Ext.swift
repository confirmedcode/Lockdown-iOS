//
//  CALayer+Ext.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 12/2/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import UIKit

extension CALayer {
    
    // MARK: - Animations
    
    func pause() {
        let pausedTime: CFTimeInterval = convertTime(CACurrentMediaTime(), from: nil)
        speed = 0.0
        timeOffset = pausedTime
    }
    
    func resume() {
        let pausedTime: CFTimeInterval = timeOffset
        speed = 1.0
        timeOffset = 0.0
        beginTime = 0.0
        let timeSincePause: CFTimeInterval = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        beginTime = timeSincePause
    }
}
