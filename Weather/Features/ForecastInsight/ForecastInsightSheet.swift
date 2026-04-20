import SwiftUI

struct ForecastInsightSheet: View {
    let payload: ForecastInsightPayload

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var entranceOn = false
    @State private var selectedDetent: PresentationDetent = .large
    @State private var summaryBody: String
    @State private var usedOllama = false
    @State private var isOllamaLoading = false

    init(payload: ForecastInsightPayload) {
        self.payload = payload
        _summaryBody = State(initialValue: Self.sanitizeInsightTypography(payload.summaryParagraph))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ForecastInsightAccentCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(payload.cityLine)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)

                        HStack(alignment: .top, spacing: 10) {
                            Group {
                                if reduceMotion {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "DDA8C8FF"),
                                                    Color(hex: "DD7AB8E8"),
                                                    Color(hex: "DD88D8FF"),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                            .font(.system(size: 22, weight: .medium))
                            .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(payload.headlineCondition)
                                    .font(.system(.title3, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.primary)

                                Text("\(payload.headlineTemp)°\(payload.headlineUnit)")
                                    .font(.system(size: 32, weight: .medium, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                            }
                        }

                        if isOllamaLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Local AI…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(summaryBody)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 10) {
                            Label {
                                Text(Self.sanitizeInsightTypography(payload.wearLine))
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.primary.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: "tshirt.fill")
                                    .foregroundStyle(.secondary)
                            }

                            if let carry = payload.carryLine {
                                Label {
                                    Text(Self.sanitizeInsightTypography(carry))
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(.primary.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                } icon: {
                                    Image(systemName: "umbrella.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Text(footerCaption)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 8)
                .opacity(entranceOn ? 1 : 0)
                .offset(y: entranceOn ? 0 : (reduceMotion ? 0 : 8))
            }
            .navigationTitle("Forecast insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                entranceOn = false
                guard !reduceMotion else {
                    entranceOn = true
                    return
                }
                withAnimation(.easeOut(duration: 0.35)) {
                    entranceOn = true
                }
            }
            .task {
                await loadOllamaNarrativeIfAvailable()
            }
        }
        .presentationDetents([.fraction(0.9), .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .modifier(ForecastInsightScrollExpandModifier())
    }

    private var footerCaption: String {
        if usedOllama {
            return "Generated with Ollama using your forecast facts."
        }
        return "Forecast-based summary. Run Ollama on your Mac for local AI (Simulator reaches \(OllamaInsightConfiguration.defaultBaseURLString))."
    }

    private func loadOllamaNarrativeIfAvailable() async {
        isOllamaLoading = true
        defer { isOllamaLoading = false }
        if let text = await ForecastInsightOllamaService.fetchNarrative(payload: payload) {
            summaryBody = Self.sanitizeInsightTypography(text)
            usedOllama = true
        }
    }

    /// Removes em dash / double-hyphen typography that reads like a “double dash” in tight UI copy.
    private static func sanitizeInsightTypography(_ raw: String) -> String {
        var s = raw
        // Em / figure dash (long “double dash” look in UI), not minus or range en dash.
        s = s.replacingOccurrences(of: "\u{2014}", with: ", ")
        s = s.replacingOccurrences(of: "\u{2015}", with: ", ")
        while s.contains("--") {
            s = s.replacingOccurrences(of: "--", with: " ")
        }
        while s.contains(", ,") {
            s = s.replacingOccurrences(of: ", ,", with: ",")
        }
        while s.contains("  ") {
            s = s.replacingOccurrences(of: "  ", with: " ")
        }
        return s
    }
}

private struct ForecastInsightScrollExpandModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationContentInteraction(.scrolls)
        } else {
            content
        }
    }
}
