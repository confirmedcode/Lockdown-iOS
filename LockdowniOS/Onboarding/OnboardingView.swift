//
//  OnboardingView.swift
//  LockdowniOS
//
//  Created by George Apostu on 13/2/25.
//  Copyright © 2025 Confirmed Inc. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {

    @StateObject var paywallModel: OneTimePaywallModel
    
    @State var selectedTab: Int = {
        if #available(iOS 17, *) {
            2
        } else {
            0
        }
    }()
    
    func selectNextTab() {
        guard let step = OnboardingStep(rawValue: selectedTab) else { return }
        if step == .first {
            selectedTab = OnboardingStep.second.rawValue
        } else if step == .second {
            selectedTab = OnboardingStep.paywall.rawValue
        }
    }
    
    let steps: [OnboardingStep] = [.first, .second]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Group {
                ForEach(steps) { step in
                    OnboardingStepView(step: step) {
                        withAnimation {
                            selectNextTab()
                        }
                    }
                    .tag(step.rawValue)
                }
                OneTimePaywallView(model: paywallModel)
                    .tag(OnboardingStep.paywall.rawValue)
            }
            .onAppear {
                selectedTab = 1
                selectedTab = 0
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: selectedTab)
        .onAppear {
            UIScrollView.appearance().bounces = false
            UIScrollView.appearance().isScrollEnabled = false
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingView(paywallModel: OneTimePaywallModel(products: VPNSubscription.oneTimeProducts, infos: [.mockWeekly, .mockWeeklyTrial, .mockYearly, .mockWeeklyTrial]))
}

struct OnboardingStepView: View {
    
    let step: OnboardingStep
    
    @State private var arrowOffset: CGFloat = -3.125

    var continueAction: () -> Void = { }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Image(step.backgroundImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
            
            VStack(alignment: .leading, spacing: 25.0) {
                Text(step.title)
                    .foregroundColor(.white)
                    .font(.system(size: 28, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    
                Text(step.subtitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .font(.custom("SFPro", size: 20))
                    .padding(.horizontal, 25)
                    .padding(.bottom, 25)
                
                VStack(alignment: .leading, spacing: 25) {
                    ForEach(step.items, id: \.self) { item in
                        HStack(spacing: 12) {
                            Image("onboardingCheckmark")
                            Text(item)
                                .lineLimit(nil)
                                .foregroundColor(.white)
                        }
                    }
                }
                .font(.custom("SFPro", size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                
                
                Button(action: {
                    continueAction()
                }, label: {
                    ZStack(alignment: .trailing) {
                        Text("Onboarding.Continue")
                            .font(.custom("Montserrat-SemiBold", size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .padding(.vertical, 3)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(Color("Confirmed Blue"))
                            )
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .padding(20)
                            .offset(x: arrowOffset)
                            .animation(Animation.easeInOut(duration: 0.39).repeatForever(autoreverses: true), value: arrowOffset)
                            .onAppear {
                                arrowOffset = 3.125
                            }
                    }
                })
                .padding(.bottom, 30)
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let subtitle: String
    var isFirst: Bool = false
    var isLast: Bool = false
}

enum OnboardingStep: Int {
    
    case first = 0
    case second = 1
    case paywall = 2
    
    var backgroundImageName: String {
        switch self {
        case .first:
            return "onboardingStep1"
        case .second:
            return "onboardingStep2"
        case .paywall:
            return "onboardingPaywall"
        }
    }
    
    var title: String {
        switch self {
        case .first:
            return NSLocalizedString("Onboarding.Step1.Title", comment: "")
        case .second:
            return NSLocalizedString("Onboarding.Step2.Title", comment: "")
        case .paywall:
            return ""
        }
    }
    
    var subtitle: String {
        switch self {
        case .first:
            return NSLocalizedString("Onboarding.Step1.Subtitle", comment: "")
        case .second:
            return NSLocalizedString("Onboarding.Step2.Subtitle", comment: "")
        case .paywall:
            return ""
        }
    }
    
    var items: [String] {
        switch self {
        case .first:
            return [NSLocalizedString("Onboarding.Step1.Item1", comment: ""),
                    NSLocalizedString("Onboarding.Step1.Item2", comment: ""),
                    NSLocalizedString("Onboarding.Step1.Item3", comment: "")]
        case .second:
            return [NSLocalizedString("Onboarding.Step2.Item1", comment: ""),
                    NSLocalizedString("Onboarding.Step2.Item2", comment: ""),
                    NSLocalizedString("Onboarding.Step2.Item3", comment: "")]
        case .paywall:
            return []
        }
    }
}

extension OnboardingStep: Identifiable {
    var id: RawValue { rawValue }
}
