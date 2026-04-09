
import SwiftUI

struct CityTextView: View {
    
    var cityName: String
    
    var body: some View {
        Text(cityName)
            .font(.system(size: 30, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
            .padding()
    }
}
