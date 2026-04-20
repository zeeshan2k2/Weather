import SwiftUI

private enum DashboardAIInsightGlyphShadow {
    static let sparklesStrongHex = "55000000"
    static let sparklesSoftHex = "33000000"
    static let glowPurpleHex = "389B7AE8"
    static let glowCyanHex = "285ECFE8"
}

struct DashboardAIInsightButton: View {
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var ringRotation: Double = 0
    @State private var rainbowRotation: Double = 0
    @State private var shimmerRotation: Double = 0

    private let diameter: CGFloat = 44

    private let rainbowTurnDuration: Double = 6.2
    private let ringTurnDuration: Double = 9.5
    private let shimmerTurnDuration: Double = 3.1

    private var rainbowFill: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: AIInsightChromePalette.rainbowFillHex.map { Color(hex: $0) }),
            center: .center,
            angle: .degrees(0)
        )
    }

    private var iridescentStroke: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: AIInsightChromePalette.ringStrokeHex.map { Color(hex: $0) }),
            center: .center,
            angle: .degrees(0)
        )
    }

    private var shimmerStroke: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: AIInsightChromePalette.shimmerStrokeStops.map {
                Gradient.Stop(color: Color(hex: $0.0), location: $0.1)
            }),
            center: .center,
            angle: .degrees(0)
        )
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(rainbowFill)
                    .rotationEffect(.degrees(rainbowRotation))
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: AIInsightChromePalette.veilCenterHex),
                                Color(hex: AIInsightChromePalette.veilEdgeHex),
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: diameter * 0.72
                        )
                    )
                Circle()
                    .stroke(shimmerStroke, lineWidth: 2.85)
                    .blur(radius: 0.85)
                    .rotationEffect(.degrees(-shimmerRotation))
                    .opacity(reduceMotion ? 0.65 : 1)
                Circle()
                    .stroke(iridescentStroke, lineWidth: 1.85)
                    .rotationEffect(.degrees(-ringRotation))
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.88)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: DashboardAIInsightGlyphShadow.sparklesStrongHex), radius: 1, y: 1)
                    .shadow(color: Color(hex: DashboardAIInsightGlyphShadow.sparklesSoftHex), radius: 3, y: 1)
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .drawingGroup()
            .shadow(color: Color(hex: DashboardAIInsightGlyphShadow.glowPurpleHex), radius: 7, y: 1)
            .shadow(color: Color(hex: DashboardAIInsightGlyphShadow.glowCyanHex), radius: 13, y: 2)
        }
        .buttonStyle(.plain)
        .onAppear {
            ringRotation = 0
            rainbowRotation = 0
            shimmerRotation = 0
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: ringTurnDuration).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.linear(duration: rainbowTurnDuration).repeatForever(autoreverses: false)) {
                rainbowRotation = 360
            }
            withAnimation(.linear(duration: shimmerTurnDuration).repeatForever(autoreverses: false)) {
                shimmerRotation = 360
            }
        }
        .onChange(of: reduceMotion) { shouldReduce in
            guard !shouldReduce else {
                ringRotation = 0
                rainbowRotation = 0
                shimmerRotation = 0
                return
            }
            ringRotation = 0
            rainbowRotation = 0
            shimmerRotation = 0
            withAnimation(.linear(duration: ringTurnDuration).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.linear(duration: rainbowTurnDuration).repeatForever(autoreverses: false)) {
                rainbowRotation = 360
            }
            withAnimation(.linear(duration: shimmerTurnDuration).repeatForever(autoreverses: false)) {
                shimmerRotation = 360
            }
        }
        .accessibilityLabel("AI forecast summary")
        .accessibilityHint("Opens a short outlook for the next few hours.")
    }
}

