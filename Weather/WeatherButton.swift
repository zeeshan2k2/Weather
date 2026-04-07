//
//  WeatherButton.swift
//  Weather
//
//  Created by Zeeshan Waheed on 25/03/2026.
//

import Foundation
import SwiftUI

struct WeatherButton: View {
    
    var title: String
    var textColor: Color
    var backgroundColor: Color
    
    var body: some View {
        // What the button looks like
        Text(title)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .frame(minWidth: 200)
            .background(backgroundColor.gradient)
            .clipShape(Capsule())
            .contentShape(Capsule())
    }
    
}

struct WeatherButton_Previews: PreviewProvider {
    static var previews: some View {
        WeatherButton(
            title: "Hello",
            textColor: .white,
            backgroundColor: .blue
        )
    }
}
