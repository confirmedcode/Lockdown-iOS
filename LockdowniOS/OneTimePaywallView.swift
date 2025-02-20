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
    @State private var arrowOffset: CGFloat = -3.125
    
    var imgName = UIScreen.main.bounds.height > 700 ? "bg_paywall_onetime" : "bg_paywall_onetime_ss"
    
    var body: some View {
        ZStack {
            Image(imgName)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            LinearGradient(stops:
                            [Gradient.Stop(color: Color.black.opacity(0.0), location: 0.0),
                             Gradient.Stop(color: Color.black.opacity(0.0), location: 0.2),
                             Gradient.Stop(color: Color.black.opacity(0.6), location: 0.5),
                             Gradient.Stop(color: Color.black.opacity(0.6), location: 1.0),
                            ], startPoint: .top, endPoint: .bottom)
            
            VStack(alignment: .leading, spacing: 8) {
                closeButton
                
                Spacer()
                    .frame(minHeight: 10)
                    .layoutPriority(-1)
                
                title
                subtitle
                detailItems
                
                trialToggle
                
                yearlyProduct
                weeklyProduct
                
                purchaseButton
                
                noPaymentFooter

                Spacer()
                    .frame(maxHeight: 30)
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
    
    private var purchaseButton: some View {
        Button(action: {
            model.purchase()
        }, label: {
            ZStack(alignment: .trailing) {
                Text("Paywall.Onetime.Continue")
                    .font(.custom("Montserrat-SemiBold", size: 20))
                    .foregroundColor(.white)
                    .padding()
                    .padding(.vertical, 2)
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
    }
    
    private var title: some View {
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
        .minimumScaleFactor(0.75)
    }
    
    private var subtitle: some View {
        Text("Paywall.Onetime.PrivateBrowse")
            .foregroundColor(.white)
            .font(.custom("Montserrat-Regular", size: 14))
    }
    
    private var detailItems: some View {
        VStack(alignment: .leading, spacing: 2) {
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
        .padding(.vertical, 5)
        .minimumScaleFactor(0.75)
    }
    
    private var trialToggle: some View {
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
    }
    
    private var yearlyProduct: some View {
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
            .offset(x: 100, y: -30)
        }
        .padding(.top, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            model.activePlan = .yearly
        }
    }
    
    private var weeklyProduct: some View {
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
    }
    
    private var noPaymentFooter: some View {
        HStack {
            Spacer()
            Image("shield_checkmark")
            Text("No payment now")
            Spacer()
        }
        .font(.custom("Montserrat-Bold", size: 12))
        .foregroundColor(.white)
    }
    
    private var closeButton: some View {
        Button {
            model.closeAction?()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.leading, -20)
        .padding(.top, 40)
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
    OneTimePaywallView(model: OneTimePaywallModel(products: VPNSubscription.oneTimeProducts, infos: [.mockWeekly, .mockWeeklyTrial, .mockYearly, .mockWeeklyTrial]))
}
