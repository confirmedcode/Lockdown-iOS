//
//  LoadingCircle.swift
//  Lockdown
//
//  Created by Johnny Lin on 1/21/20.
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import Foundation
import SwiftUI

struct TunnelState {
    var color: Color = Color.gray
    var circleColor: Color = Color.gray
    
    init() {
    }
    
    init(color: Color, circleColor: Color) {
        self.color = color
        self.circleColor = circleColor
    }
}

struct StatusLabel: View {
    
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 7))
            .background(color)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color, lineWidth: 4)
            )
    }
}

struct LoadingCircle: View {
    
    let side: CGFloat
    let tunnelState: TunnelState
    let link: String
    
    init(tunnelState: TunnelState, side: CGFloat, link: String) {
        self.tunnelState = tunnelState
        self.side = side
        self.link = link
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2.5)
                .frame(width: side * 0.4, height: side * 0.4)
                .padding(4)
                .foregroundColor(tunnelState.circleColor)
                .zIndex(10)
            Circle()
                .fill()
                .frame(width: side * 0.4, height: side * 0.4)
                .shadow(color: .powerButtonShadowColor, radius: 8, x: 0, y: 3.5)
                .padding(4)
                .foregroundColor(Color.panelSecondaryBackground)
                .background(Color.panelBackground)
                .zIndex(1)
            Link.init(destination: URL.init(string: self.link)!, label: {
                Image(uiImage: UIImage(named: "power")!.withRenderingMode(.alwaysTemplate).withTintColor(UIColor(tunnelState.circleColor)).resized(toFit: CGSize(width: side * 0.30, height: side * 0.30)))
                    .foregroundColor(tunnelState.circleColor)
                    .zIndex(40)
            })
        }
    }
}

struct BlankButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}

extension Color {
    static let confirmedBlue = Color(red: 0/255.0, green: 173/255.0, blue: 231/255.0)
    static let panelBackground = Color("Panel Background")
    static let panelSecondaryBackground = Color("Panel Secondary Background")
    static let powerButtonShadowColor = Color("Power Button Shadow Color")
    static let mainBackground = Color("Main Background")
    
    static let lightGray = Color(UIColor.lightGray)
    static let flatRed = Color(red: 231/255, green: 76/255, blue: 60/255)
}

extension UIImage {
    func resized(toFit size: CGSize) -> UIImage {
        assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")
        
        let imageAspectRatio = self.size.width / self.size.height
        let canvasAspectRatio = size.width / size.height
        
        var resizeFactor: CGFloat
        
        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.width / self.size.width
        } else {
            resizeFactor = size.height / self.size.height
        }
        
        let scaledSize = CGSize(width: self.size.width * resizeFactor, height: self.size.height * resizeFactor)
        
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}
