//
//  StripScrollHintChevron.swift
//  Weather
//
//  Trailing hint for horizontal forecast strips (non-interactive).
//

import SwiftUI

/// Soft fade + animated chevron when a strip has more content off-screen to the right.
struct StripScrollHintChevron: View {
    let isVisible: Bool
    /// Horizontal padding **inside** a parent chrome (e.g. `WeatherForecastStripsPanel`). Shifts the hint so `trailingMarginFromOuter` is measured from the **outer** edge of that panel. Use `0` when the strip already fills the same width as the visible container (e.g. day detail).
    var parentHorizontalContentInset: CGFloat = 0
    /// Trailing space from the **outer** edge of the shared container (frosted panel, day-detail column, etc.).
    var trailingMarginFromOuter: CGFloat = 3

    /// Fade only; chevron sits to the right in clear space (better contrast than stacking).
    private static let highlightBarWidth: CGFloat = 48
    private static let chevronGap: CGFloat = 0
    private static let hintCornerRadius: CGFloat = 14
    private static let fadeEndOpacity: Double = 0.038

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0),
                Color.black.opacity(Self.fadeEndOpacity)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        if isVisible {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(alignment: .center, spacing: Self.chevronGap) {
                    RoundedRectangle(cornerRadius: Self.hintCornerRadius, style: .continuous)
                        .fill(highlightGradient)
                        .frame(width: Self.highlightBarWidth)
                        .frame(maxHeight: .infinity)
                        .allowsHitTesting(false)

                    chevron
                }
                .padding(.trailing, trailingMarginFromOuter)
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .offset(x: parentHorizontalContentInset)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var chevron: some View {
        let base = Image(systemName: "chevron.compact.right")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.1), radius: 1, y: 0.5)
            .symbolRenderingMode(.hierarchical)

        if #available(iOS 17.0, *) {
            base.symbolEffect(.pulse, options: .repeating.speed(0.55), isActive: true)
        } else {
            base.modifier(LegacyChevronOpacityPulse())
        }
    }
}

private struct LegacyChevronOpacityPulse: ViewModifier {
    @State private var bright = false

    func body(content: Content) -> some View {
        content
            .opacity(bright ? 1 : 0.42)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    bright = true
                }
            }
    }
}
