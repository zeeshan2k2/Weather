import SwiftUI

enum AIInsightChromePalette {
    static let rainbowFillHex: [String] = [
        "59FF7A9E",
        "59FF9A7A",
        "59FFDD55",
        "5955E8A8",
        "5955C8FF",
        "59A090FF",
        "59E888F0",
        "59FF7A9E",
    ]

    static let ringStrokeHex: [String] = [
        "A5B8A0FF",
        "A592C8FF",
        "A575E8D8",
        "A58FF0A0",
        "A5FFCC80",
        "A5FFB0E0",
        "A5B8A0FF",
    ]

    static let veilCenterHex = "12FFFFFF"
    static let veilEdgeHex = "06FFFFFF"

    static let shimmerStrokeStops: [(String, CGFloat)] = [
        ("00FFFFFF", 0.0),
        ("8EFFFFFF", 0.06),
        ("72F0FAFF", 0.14),
        ("62FFD8F5", 0.24),
        ("10FFFFFF", 0.38),
        ("48FFFFFF", 0.48),
        ("7AFFFFFF", 0.62),
        ("18FFFFFF", 0.78),
        ("00FFFFFF", 1.0),
    ]
}
