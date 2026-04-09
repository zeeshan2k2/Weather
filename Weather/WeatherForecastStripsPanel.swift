
import SwiftUI

/// One frosted rectangle wrapping the hourly strip and the multi-day strip together (not per-cell chrome).
struct WeatherForecastStripsPanel<Content: View>: View {
    var cornerRadius: CGFloat = 20

    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.26),
                                Color.white.opacity(0.07)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                shape.strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
            }
    }
}
