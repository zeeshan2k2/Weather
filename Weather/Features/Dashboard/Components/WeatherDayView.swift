import SwiftUI

struct WeatherDayView: View {

    var dayOfWeek: String
    var imageName: String

    var highTemperature: Int
    var lowTemperature: Int?
    var unit: String = "F"

    var stripCompact: Bool = false

    private var chromeCornerRadius: CGFloat {
        stripCompact ? 12 : 14
    }

    private var cellShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: chromeCornerRadius, style: .continuous)
    }

    private var vStackSpacing: CGFloat {
        stripCompact ? 4 : 5
    }

    private var verticalPadding: CGFloat {
        stripCompact ? 8 : 10
    }

    private var horizontalPadding: CGFloat {
        stripCompact ? 8 : 12
    }

    var body: some View {
        VStack(spacing: vStackSpacing) {
            Text(dayOfWeek)
                .font(.system(size: stripCompact ? 12 : 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            WeatherSkyConditionSymbol.resizableImage(systemName: imageName)
                .frame(width: stripCompact ? 32 : 38, height: stripCompact ? 32 : 38)

            Group {
                if let lowTemperature {
                    HStack(alignment: .firstTextBaseline, spacing: stripCompact ? 3 : 4) {
                        Text("\(highTemperature)°\(unit)")
                            .font(.system(size: stripCompact ? 17 : 21, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("/")
                            .font(.system(size: stripCompact ? 11 : 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                        Text("\(lowTemperature)°\(unit)")
                            .font(.system(size: stripCompact ? 14 : 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                } else {
                    Text("\(highTemperature)°\(unit)")
                        .font(.system(size: stripCompact ? 17 : 21, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background {
            cellShape
                .fill(
                    LinearGradient(
                        colors: stripCompact
                            ? [
                                Color.white.opacity(0.34),
                                Color.white.opacity(0.12)
                            ]
                            : [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.08)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            cellShape
                .strokeBorder(
                    Color.white.opacity(stripCompact ? 0.52 : 0.45),
                    lineWidth: stripCompact ? 1.1 : 1
                )
        }
        .shadow(
            color: .black.opacity(stripCompact ? 0.28 : 0),
            radius: stripCompact ? 5 : 0,
            y: stripCompact ? 3 : 0
        )
    }
}

struct DayCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.64, blendDuration: 0.15), value: configuration.isPressed)
    }
}
