//
//  OnboardingPage.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/26/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import AVFoundation
import Foundation

struct OnboardingPage {
    let title: String
    let description: String
    let content: OnboardingPageContent
    let gradient: LockdownGradient
    
    var videoDuration: Float {
        guard case .video(let videoTitle) = content else { return 0 }
        guard let videoPath = Bundle.main.path(forResource: videoTitle, ofType: "mp4") else { return 0 }
        
        let videoUrl = URL(fileURLWithPath: videoPath)
        let asset = AVAsset(url: videoUrl)
        let duration = asset.duration
        return Float(CMTimeGetSeconds(duration))
    }
    
    // MARK: - Factory
    
    static let featuredByApple: Self = {
        return OnboardingPage(title: .localized("onboarding_simple_and_powerful"),
                              description: .localized("onboarding_lockdown_stops_trackers"),
                              content: .image(title: "Onboarding_apple_logo", duration: 5, presentationType: .fadeIn),
                              gradient: .onboardingBlue)
    }()
    
    static let installation: Self = {
        return OnboardingPage(title: .localized("onboarding_worlds_first_on_device"),
                              description: .localized("onboarding_firewall_and_vpn_work_across_all_apps"),
                              content: .video(title: "Onboarding_installation"),
                              gradient: .onboardingPurple)
    }()
    
    static let easyProtection: Self = {
        return OnboardingPage(title: .localized("onboarding_staying_protected_is_easy_with_lockdown"),
                              description: .localized("onboarding_firewall_and_vpn_work_across_all_apps"),
                              content: .video(title: "Onboarding_launch_firewall"),
                              gradient: .onboardingPurple)
    }()
    
    static let anonymousWithVPN: Self = {
        return OnboardingPage(title: .localized("onboarding_remain_anonymous_with_secure_tunnel_vpn"),
                              description: .localized("onboarding_no_logs_fast_and_fully_audited"),
                              content: .video(title: "Onboarding_showcase_vpn"),
                              gradient: .onboardingBlue)
    }()
    
    static let blocklists: Self = {
        return OnboardingPage(title: .localized("onboarding_take_control_of_who_you_block"),
                              description: .localized("onboarding_when_using_our_intuitive_blocklists"),
                              content: .video(title: "Onboarding_blocklists"),
                              gradient: .onboardingPurple)
    }()
    
    static let summaryAndUpdates: Self = {
        return OnboardingPage(title: .localized("onboarding_stay_protected"),
                              description: .localized("onboarding_get_weekly_summary_and_blocklist_updates"),
                              content: .video(title: "Onboarding_notifications"),
                              gradient: .onboardingBlue)
    }()
    
    static let manyTrackersBlocked: Self = {
        return OnboardingPage(title: .localized("onboarding_over_1_billion_trackers_blocked"),
                              description: .localized("onboarding_used_by_more_than_1_million"),
                              content: .image(title: "Onboarding_blocked_tweet", duration: 10, presentationType: .zoomOutAndMoveToLeft),
                              gradient: .onboardingPurple)
    }()
}

extension Array where Element == OnboardingPage {
    static let defaultPages: Self = {
        return [
            .featuredByApple,
            .installation,
            .easyProtection,
            .anonymousWithVPN,
            .blocklists,
            .summaryAndUpdates,
            .manyTrackersBlocked
        ]
    }()
}
