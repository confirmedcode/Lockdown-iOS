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
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    var imgName = UIScreen.main.bounds.height > 700 ? "bg_paywall_onetime" : "bg_paywall_onetime_ss"
    let txtColor = Color.white
    
    var body: some View {
        ZStack(alignment: .center) {
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
            VStack(spacing: 4) {
                VStack(spacing: 0) {
                    ZStack {
                        Image("special_offer_stars")
                            .resizable()
                            .frame(height: screenHeight * 0.3)
                            .edgesIgnoringSafeArea(.top)
                        Image("special_offer_2025")
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, screenWidth * 0.12)
                            .padding(.vertical, screenWidth * 0.07)
                    }
                    Image("banner_70_percent")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight:120)
                        .padding(.top, -20)
                }
                
                if !model.isSmallScreen {
                    Spacer()
                        .frame(maxHeight: 30)
                        .layoutPriority(-1)
                }
                
                Text("Paywall.Onetime.DecemberSale")
                    .multilineTextAlignment(.center)
                    .font(.custom("Juana-SemiBold", size: 36))
                    .foregroundColor(txtColor)
                    .minimumScaleFactor(0.5)
                                
                VStack(alignment: .center, spacing: 4) {
                    Text("Paywall.Onetime.perYear \(model.yearlyPrice)")
                        .strikethrough()
                        .foregroundColor(txtColor)
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
                            .foregroundColor(txtColor)
                    }
                    .font(.custom("SF Pro Rounded Semibold", size: 28))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Paywall.Onetime.PrivateBrowse")
                        .foregroundColor(txtColor)
                        .font(.custom("Montserrat-Regular", size: 14))
                    
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("Confirmed Blue"))
                            Text("Paywall.Onetime.List1")
                                .foregroundColor(txtColor)
                        }
                        HStack {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("Confirmed Blue"))
                            Text("Paywall.Onetime.List2")
                                .foregroundColor(txtColor)
                        }
                        HStack {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("Confirmed Blue"))
                            Text("Paywall.Onetime.List3")
                                .foregroundColor(txtColor)
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
            .edgesIgnoringSafeArea(.top)
            .frame(maxHeight: UIScreen.main.bounds.size.height)
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading) {
                HStack {
                    Button {
                        model.closeAction?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(txtColor)
                    }
                    .padding()
                    .contentShape(Rectangle())
                    Spacer()
                }
                Spacer()
            }
            .padding(.top, screenHeight * 0.02)

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
    var model = SpecialOfferPaywallModel(products: VPNSubscription.specialOfferProducts, infos: [.mockYearlyBF],
                                         closeAction: {
        print("")
    })
    SpecialOfferPaywallView(model: model)
}
