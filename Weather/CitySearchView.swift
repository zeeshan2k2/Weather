
import SwiftUI

struct CitySearchView: View {

    @Environment(\.dismiss) private var dismiss
    var onSelectPlace: (GeocodingPlace) -> Void

    @State private var searchText = ""
    @State private var results: [GeocodingPlace] = []
    @State private var isSearching = false
    /// Last completed search failed due to connectivity (don’t show “No matches”).
    @State private var lastSearchFailedOffline = false

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showHint: Bool {
        trimmedQuery.count < 2 && !isSearching
    }

    private var showNoResults: Bool {
        trimmedQuery.count >= 2 && !isSearching && results.isEmpty && !lastSearchFailedOffline
    }

    private var showOfflineSearch: Bool {
        trimmedQuery.count >= 2 && !isSearching && lastSearchFailedOffline
    }

    var body: some View {
        NavigationStack {
            ZStack {
                searchScreenGradient
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if isSearching {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.05)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                        }

                        if showHint {
                            CitySearchEmptyState(
                                icon: "magnifyingglass",
                                title: "Find a place",
                                subtitle: "Enter at least two letters to search cities and towns worldwide."
                            )
                            .padding(.top, 32)
                        } else if showOfflineSearch {
                            CitySearchEmptyState(
                                icon: "wifi.slash",
                                title: "No internet connection",
                                subtitle: "Connect to Wi‑Fi or mobile data to search for places, then try again."
                            )
                            .padding(.top, 28)
                        } else if showNoResults {
                            CitySearchEmptyState(
                                icon: "location.slash",
                                title: "No matches",
                                subtitle: "Try another spelling or a nearby larger city."
                            )
                            .padding(.top, 28)
                        }

                        ForEach(results) { place in
                            Button {
                                onSelectPlace(place)
                                dismiss()
                            } label: {
                                CitySearchResultCard(place: place, searchQuery: searchText)
                            }
                            .buttonStyle(CitySearchRowPressStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                    .animation(.spring(response: 0.45, dampingFraction: 0.86), value: results.count)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "City, town, or region")
            .tint(.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task(id: searchText) {
            await runDebouncedSearch()
        }
    }

    private var searchScreenGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "1E3A5F"),
                Color(hex: "0F1B2E"),
                Color(hex: "0A1628")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func runDebouncedSearch() async {
        let trimmed = trimmedQuery
        if trimmed.count < 2 {
            results = []
            lastSearchFailedOffline = false
            isSearching = false
            return
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
        let latest = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard latest == trimmed, latest.count >= 2 else { return }

        isSearching = true
        defer { isSearching = false }
        do {
            results = try await WeatherService.searchPlaces(name: latest)
            lastSearchFailedOffline = false
        } catch {
            if error is CancellationError { return }
            if (error as? URLError)?.code == .cancelled { return }
            results = []
            lastSearchFailedOffline = WeatherService.isLikelyConnectivityFailure(error)
        }
    }
}

// MARK: - Empty state

private struct CitySearchEmptyState: View {
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

// MARK: - Result card

private struct CitySearchResultCard: View {
    let place: GeocodingPlace
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

// MARK: - Match highlight

private struct CitySearchHighlightedName: View {
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

// MARK: - Row press

private struct CitySearchRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
