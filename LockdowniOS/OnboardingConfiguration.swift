//
//  OnboardingConfiguration.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/28/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation

struct OnboardingConfiguration {
    
    /// How often the onboarding page progress bar is updated.
    let timerInterval: TimeInterval
    
    /// How long the onboarding page text and gradient are updated.
    let contentAnimationDuration: Double
    
    init(timerInterval: TimeInterval = 0.05, contentAnimationDuration: Double = 0.3) {
        self.timerInterval = timerInterval
        self.contentAnimationDuration = contentAnimationDuration
    }
}
