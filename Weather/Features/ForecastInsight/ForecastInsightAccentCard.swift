import SwiftUI

private enum ForecastInsightAccentChrome {
    static let ringInset: CGFloat = 1

    private static func solidBandHex(_ hex: String, alphaPrefix: String) -> String {
        guard hex.count == 8 else { return hex }
        return alphaPrefix + hex.dropFirst(2)
    }

    static var smoothRainbowBandHex: [String] {
        AIInsightChromePalette.rainbowFillHex.flatMap { hex in
            let h = solidBandHex(hex, alphaPrefix: "9A")
            return [h, h]
        }
    }

    static var smoothPearlBandHex: [String] {
        AIInsightChromePalette.ringStrokeHex.flatMap { hex in
            let h = solidBandHex(hex, alphaPrefix: "B0")
            return [h, h]
        }
    }
}

struct ForecastInsightAccentCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var chromeRotation: Double = 0

    private let outerCorner: CGFloat = 22
    private var inset: CGFloat { ForecastInsightAccentChrome.ringInset }
    private var innerCorner: CGFloat { max(14, outerCorner - inset * 1.12) }

    private let chromeTurnDuration: Double = 24

    private var rainbowFill: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: ForecastInsightAccentChrome.smoothRainbowBandHex.map { Color(hex: $0) }),
            center: .center,
            angle: .degrees(0)
        )
    }

    private var ringStroke: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: ForecastInsightAccentChrome.smoothPearlBandHex.map { Color(hex: $0) }),
            center: .center,
            angle: .degrees(0)
        )
    }

    var body: some View {
        ZStack {
            Group {
                if reduceMotion {
                    RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                        .stroke(Color.primary.opacity(0.14), lineWidth: 1.25)
                } else {
                    RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                        .fill(rainbowFill)
                        .rotationEffect(.degrees(chromeRotation))
                    RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                        .stroke(ringStroke, lineWidth: 1.2)
                        .rotationEffect(.degrees(chromeRotation))
                }
            }
            .drawingGroup()

            RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 0.75)
                )
                .padding(inset)

            content()
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: outerCorner, style: .continuous))
        .shadow(color: Color(hex: "229B7AE8"), radius: 10, y: 3)
        .shadow(color: Color(hex: "163ECFE8"), radius: 18, y: 5)
        .onAppear { startMotionIfNeeded() }
        .onChange(of: reduceMotion) { reduced in
            if reduced {
                chromeRotation = 0
            } else {
                startMotionIfNeeded()
            }
        }
    }

    private func startMotionIfNeeded() {
        guard !reduceMotion else { return }
        chromeRotation = 0
        withAnimation(.linear(duration: chromeTurnDuration).repeatForever(autoreverses: false)) {
            chromeRotation = 360
        }
    }
}
