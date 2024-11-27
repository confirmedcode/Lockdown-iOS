//
//  SpecialOfferPaywallView.swift
//  LockdowniOS
//
//  Created by George Apostu on 26/11/24.
//  Copyright © 2024 Confirmed Inc. All rights reserved.
//

import SwiftUI

struct SpecialOfferPaywallView: View {
    @StateObject var model: SpecialOfferPaywallModel
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea()
            
            HStack {
                Button {
                    model.closeAction?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {

                Spacer()

                Image("banner_70_percent")

                Spacer()

                Text("Paywall.Onetime.BlackFriday")
                    .multilineTextAlignment(.center)
                    .font(.custom("Juana-SemiBold", size: 36))
                    .foregroundColor(.white)
                
                Spacer()
                    .frame(maxHeight: 30)
                    .layoutPriority(-1)
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Paywall.Onetime.perYear \(model.yearlyPrice)")
                        .strikethrough()
                        .foregroundColor(.white)
                        .font(.custom("KumbhSans-Regular", size: 18))
                    
                    Text("Paywall.Onetime.perYear \(model.offerPrice)")
                        .foregroundColor(Color(hex: 0xFF004B))
                        .font(.custom("KumbhSans-Bold", size: 28))
                        .fontWeight(.bold)
                }
                
                Spacer()
                    .frame(maxHeight: 30)
                    .layoutPriority(-1)
                
                VStack(alignment: .leading) {
                    Group {
                        Text("Tap")
                            .foregroundColor(.white)
                        + Text("Paywall.Onetime.Continue")
                            .foregroundColor(Color("Confirmed Blue"))
                        + Text("Paywall.Onetime.ToActivate")
                            .foregroundColor(.white)
                    }
                    .font(.custom("SF Pro Rounded Semibold", size: 28))
                    
                    Text("Paywall.Onetime.PrivateBrowse")
                        .foregroundColor(.white)
                        .font(.custom("Montserrat-Regular", size: 14))

                    
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
                    .padding(.top, 5)
                    .padding(.leading, 10)
                }
                .padding(.horizontal, 10)
                
                Spacer()
                
                Button(action: {
                    model.purchase()
                }, label: {
                    Text("Paywall.Onetime.Continue")
                        .font(.custom("Montserrat-SemiBold", size: 20))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth:.infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 55)
                                .fill(Color("Confirmed Blue"))
                            )
                })
                .padding(.horizontal, 20)

                Spacer()
            }
            .frame(maxHeight: UIScreen.main.bounds.size.height)
            .padding(.horizontal, 20)
            
            ProgressView()
                .offset(y: 60)
                .scaleEffect(3)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .opacity(model.showProgress ? 1 : 0)
        }
        .allowsHitTesting(model.showProgress ? false : true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    SpecialOfferPaywallView(model: SpecialOfferPaywallModel(products: VPNSubscription.specialOfferProducts, infos: [.mockYearlyBF]))
}
