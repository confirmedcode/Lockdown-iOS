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
            Color.white
                .ignoresSafeArea()
            
            HStack {
                Button {
                    model.closeAction?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                
                VStack(spacing: -40) {
                    if model.isSmallScreen {
                        Image("december_banner")
                            .padding(.top, -40)
                    } else {
                        Image("december_banner")
                    }
                    Image("banner_70_percent")
                }
                
                if !model.isSmallScreen {
                    Spacer()
                        .frame(maxHeight: 30)
                        .layoutPriority(-1)
                }
                
                Text("Paywall.Onetime.DecemberSale")
                    .multilineTextAlignment(.center)
                    .font(.custom("Juana-SemiBold", size: 36))
                    .foregroundColor(.black)
                                
                VStack(alignment: .center, spacing: 4) {
                    Text("Paywall.Onetime.perYear \(model.yearlyPrice)")
                        .strikethrough()
                        .foregroundColor(.black)
                        .font(.custom("KumbhSans-Regular", size: 18))
                    
                    Text("Paywall.Onetime.perYear \(model.offerPrice)")
                        .foregroundColor(Color(hex: 0xFF004B))
                        .font(.custom("KumbhSans-Bold", size: 28))
                        .fontWeight(.bold)
                }
                
                if !model.isSmallScreen {
                    Spacer()
                        .frame(maxHeight: 30)
                        .layoutPriority(-1)
                }
                
                VStack(alignment: .leading) {
                    Group {
                        Text("Tap")
                            .foregroundColor(.black)
                        + Text("Paywall.Onetime.Continue")
                            .foregroundColor(Color("Confirmed Blue"))
                        + Text("Paywall.Onetime.ToActivate")
                            .foregroundColor(.black)
                    }
                    .font(.custom("SF Pro Rounded Semibold", size: 28))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Paywall.Onetime.PrivateBrowse")
                        .foregroundColor(.black)
                        .font(.custom("Montserrat-Regular", size: 14))
                    
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("Confirmed Blue"))
                            Text("Paywall.Onetime.List1")
                                .foregroundColor(.black)
                        }
                        HStack {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("Confirmed Blue"))
                            Text("Paywall.Onetime.List2")
                                .foregroundColor(.black)
                        }
                        HStack {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("Confirmed Blue"))
                            Text("Paywall.Onetime.List3")
                                .foregroundColor(.black)
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
                .frame(height: 58)
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
