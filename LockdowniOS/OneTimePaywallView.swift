//
//  OneTimePaywallView.swift
//  Lockdown
//
//  Created by Radu Lazar on 05.08.2024.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import SwiftUI

struct OneTimePaywallView: View {
    @StateObject var model: OneTimePaywallModel
    var body: some View {
        ZStack {
            Image("bg_paywall_onetime")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            LinearGradient(stops:
                            [Gradient.Stop(color: Color.black.opacity(0.0), location: 0.0),
                             Gradient.Stop(color: Color.black.opacity(0.0), location: 0.2),
                             Gradient.Stop(color: Color.black.opacity(0.6), location: 0.5),
                             Gradient.Stop(color: Color.black.opacity(0.6), location: 1.0),
                            ], startPoint: .top, endPoint: .bottom)
            VStack(alignment:.leading, spacing: 8) {
                Button {
                    model.closeAction?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.leading, -20)
                .padding(.top, 40)
                Spacer()
                    .frame(minHeight: 10)
                    .layoutPriority(-1)
                Group {
                    Text("Tap")
                        .foregroundColor(.white)
                    + Text("Paywall.Onetime.Continue")
                        .foregroundColor(Color("Confirmed Blue"))
                    + Text("Paywall.Onetime.ToActivate")
                        .foregroundColor(.white)
                }
                .font(.system(size: 28, weight: .semibold))
                .frame(maxWidth: .infinity)
                Text("Paywall.Onetime.PrivateBrowse")
                    .foregroundColor(.white)
                    .font(.custom("Montserrat-Regular", size: 14))
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color("Confirmed Blue"))
                        Text("Paywall.Onetime.List1")
                            .foregroundColor(.white)
                    }
                    HStack {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color("Confirmed Blue"))
                        Text("Paywall.Onetime.List2")
                            .foregroundColor(.white)
                    }
                    HStack {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color("Confirmed Blue"))
                        Text("Paywall.Onetime.List3")
                            .foregroundColor(.white)
                    }
                }
                .font(.custom("Montserrat-Semibold", size: 12))
                .padding(.bottom, 5)
                
                HStack {
                    Text("Paywall.Onetime.FreeTrialE")
                        .lineLimit(1)
                        .font(.custom("Montserrat-SemiBold", size: 16))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle(isOn: $model.trialEnabled, label: {})
                        .toggleStyle(SwitchToggleStyle(tint: Color("Confirmed Blue")))
                        .frame(maxWidth: 60)
                }
                .modifier(BubbleBg())
                
                ZStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Paywall.Onetime.YearlyPlan")
                                .font(.custom("Montserrat-Medium", size: 12))
                            Text("Paywall.Onetime.Just \(model.yearlyPrice)")
                                .font(.custom("Montserrat-SemiBold", size: 12))
                        }
                        .font(.custom("Montserrat-SemiBold", size: 16))
                        .foregroundColor(.white)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(model.weeklyPrice)")
                                .font(.custom("Montserrat-SemiBold", size: 14))
                            Text("Paywall.Onetime.PerWeek")
                                .font(.custom("Montserrat-Medium", size: 14))
                        }
                        .foregroundColor(.white)
                    }
                    .modifier(BubbleBg(lineColor: model.activePlan == .yearly ? Color("Confirmed Blue") : .gray))
                    HStack {
                        Text("Paywall.Onetime.Save \(String(model.saving))") + Text("%")
                    }
                    .foregroundColor(.white)
                    .font(.custom("Montserrat-Bold", size: 12))
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(stops:
                                                [Gradient.Stop(color: Color(hex: 0xFB923C, alpha: 1), location: 0.0),
                                                 Gradient.Stop(color: Color(hex: 0xEA580C, alpha: 1), location: 1.0),
                                                ], startPoint: .leading, endPoint: .trailing)
                            )
                        
                    )
                    .offset(x: 100, y: -32)
                }
                .padding(.top, 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    model.activePlan = .yearly
                }
                
                HStack {
                    Text("Paywall.Onetime.3DayFT")
                        .font(.custom("Montserrat-SemiBold", size: 16))
                        .foregroundColor(.white)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Paywall.Onetime.Then \(model.trialWeeklyPrice)")
                            .font(.custom("Montserrat-SemiBold", size: 14))
                        Text("Paywall.Onetime.PerWeek")
                            .font(.custom("Montserrat-Medium", size: 14))
                    }
                    .foregroundColor(.white)
                    
                }
                .modifier(BubbleBg(lineColor: model.activePlan == .weekly ? Color("Confirmed Blue") : .gray))
                .contentShape(Rectangle())
                .onTapGesture {
                    model.activePlan = .weekly
                }
                
                Button(action: {
                    model.purchase()
                }, label: {
                    Text("Paywall.Onetime.Continue")
                        .font(.custom("Montserrat-SemiBold", size: 20))
                        .foregroundColor(.white)
                        .padding()
                        .padding(.vertical, 5)
                        .frame(maxWidth:.infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 55)
                                .fill(Color("Confirmed Blue"))
                            )
                })
                
                HStack {
                    Spacer()
                    Image("shield_checkmark")
                    Text("No payment now")
                    Spacer()
                }
                .font(.custom("Montserrat-Bold", size: 12))
                .foregroundColor(.white)

                Spacer()
                    .frame(maxHeight: 40)
            }
            .frame(maxHeight: UIScreen.main.bounds.size.height)
            .padding(.horizontal, 40)
            ProgressView()
                .offset(y: -70)
                .scaleEffect(3)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .opacity(model.showProgress ? 1 : 0)
        }
        .allowsHitTesting(model.showProgress ? false : true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

struct BubbleBg: ViewModifier {
    let lineColor: Color
    init (lineColor: Color = Color("Confirmed Blue")) {
        self.lineColor = lineColor
    }
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 52)
                    .stroke(lineColor, lineWidth: 2)
                    .background(
                        BlurView(style: .dark)
                            .opacity(0.9)
                    )
            )
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    init(style: UIBlurEffect.Style) {
        self.style = style
    }
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    OneTimePaywallView(model: OneTimePaywallModel(products: VPNSubscription.oneTimeProducts, infos:  [InternalSubscription.mockWeekly(), InternalSubscription.mockWeeklyTrial(), InternalSubscription.mockYearly(), InternalSubscription.mockWeeklyTrial()]))
}
