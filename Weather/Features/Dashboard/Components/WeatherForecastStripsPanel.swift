import SwiftUI

enum WeatherForecastStripsPanelLayout {
    static let horizontalContentPadding: CGFloat = 12
}

struct WeatherForecastStripsPanel<Content: View>: View {
    var cornerRadius: CGFloat = 20

    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .padding(.vertical, 14)
            .padding(.horizontal, WeatherForecastStripsPanelLayout.horizontalContentPadding)
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
