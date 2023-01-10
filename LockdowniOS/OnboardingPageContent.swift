//
//  OnboardingPageContent.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 10/31/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation
import UIKit

typealias ImageViewAnimationCompletion = ((UIImageView) -> Void)?

enum OnboardingPageContent {
    case image(title: String, duration: Float, presentationType: OnboardingPageImagePresentationType)
    case video(title: String)
}

enum OnboardingPageImagePresentationType {
    case fadeIn
    case zoomOutAndMoveToLeft
    
    var animation: ImageViewAnimationCompletion {
        switch self {
        case .fadeIn:
            return { imageView in
                imageView.prepareForReuse()
                imageView.fadeIn(duration: 1.2)
            }
        case .zoomOutAndMoveToLeft:
            return { imageView in
                imageView.prepareForReuse()
                imageView.fadeIn(duration: 1.2) {
                    imageView.fadeOutAsDiminished(duration: 1.2, delay: 2) {
                        
                        imageView.changeToAllTweetsImage()
                        imageView.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
                        imageView.fadeIn(duration: 0.8)
                        
                        UIView.animate(withDuration: 5, delay: 0, animations: {
                            imageView.center = .init(x: imageView.center.x - 100, y: imageView.center.y)
                        }, completion: { isContinued in
                            guard isContinued else { return }
                            imageView.fadeOut(duration: 0.6)
                        })
                    }
                }
            }
        }
    }
}

extension UIImageView {
    func prepareForReuse() {
        layer.removeAllAnimations()
        transformToIdentity()
    }
}

private extension UIImageView {
    func changeToAllTweetsImage() {
        if let image = UIImage(named: "Onboarding_tweets") {
            self.image = image
        }
    }
}
