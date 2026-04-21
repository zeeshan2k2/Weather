import SwiftUI

struct CitySearchScreenGradient: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "243B55"), location: 0),
                    .init(color: Color(hex: "152232"), location: 0.42),
                    .init(color: Color(hex: "0A1018"), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color(hex: "5B8FC7").opacity(0.14),
                    Color.clear,
                    Color(hex: "1E3D5C").opacity(0.22)
                ],
                startPoint: UnitPoint(x: 0.1, y: 0),
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.white.opacity(0.08), Color.clear],
                center: UnitPoint(x: 0.2, y: 0),
                startRadius: 0,
                endRadius: 320
            )

            RadialGradient(
                colors: [Color.black.opacity(0.35), Color.clear],
                center: .bottom,
                startRadius: 80,
                endRadius: 520
            )
        }
    }
}

struct CitySearchEmptyState: View {
    var icon: String
    var title: String
    var subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.68))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct CitySearchResultCard: View {
    let place: WeatherPlace
    let searchQuery: String

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CitySearchHighlightedName(name: place.name, query: searchQuery)

            Text(place.displayLine)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.72))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            cardShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            cardShape
                .strokeBorder(Color.white.opacity(0.38), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 10, y: 4)
    }
}

struct CitySearchHighlightedName: View {
    let name: String
    let query: String

    var body: some View {
        highlightedName(name: name, query: query)
            .font(.system(size: 18, weight: .medium, design: .rounded))
    }

    private func highlightedName(name: String, query: String) -> Text {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let dim = Color.white.opacity(0.55)
        guard !q.isEmpty else {
            return Text(name).foregroundColor(.white)
        }

        let nsName = name as NSString
        let range = nsName.range(of: q, options: [.caseInsensitive, .diacriticInsensitive])
        guard range.location != NSNotFound else {
            return Text(name).foregroundColor(dim)
        }

        let prefix = nsName.substring(to: range.location) as String
        let match = nsName.substring(with: range) as String
        let suffix = nsName.substring(from: range.location + range.length) as String

        return (Text(prefix).foregroundColor(dim)
            + Text(match).foregroundColor(.white).fontWeight(.semibold)
            + Text(suffix).foregroundColor(dim))
    }
}

struct CitySearchRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
