
import SwiftUI

struct CitySearchView: View {

    @StateObject private var model: CitySearchModel
    @Environment(\.dismiss) private var dismiss
    var onSelectPlace: (WeatherPlace) -> Void

    init(
        forecastRepository: any ForecastRepository = RemoteForecastRepository(),
        onSelectPlace: @escaping (WeatherPlace) -> Void
    ) {
        _model = StateObject(wrappedValue: CitySearchModel(forecastRepository: forecastRepository))
        self.onSelectPlace = onSelectPlace
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CitySearchScreenGradient()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if model.isSearching {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.05)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                        }

                        if model.showHint {
                            CitySearchEmptyState(
                                icon: "magnifyingglass",
                                title: "Find a place",
                                subtitle: "Enter at least two letters to search cities and towns worldwide."
                            )
                            .padding(.top, 32)
                        } else if model.showOfflineSearch {
                            CitySearchEmptyState(
                                icon: "wifi.slash",
                                title: "No internet connection",
                                subtitle: "Connect to Wi‑Fi or mobile data to search for places, then try again."
                            )
                            .padding(.top, 28)
                        } else if model.showNoResults {
                            CitySearchEmptyState(
                                icon: "location.slash",
                                title: "No matches",
                                subtitle: "Try another spelling or a nearby larger city."
                            )
                            .padding(.top, 28)
                        }

                        ForEach(model.results) { place in
                            Button {
                                onSelectPlace(place)
                                dismiss()
                            } label: {
                                CitySearchResultCard(place: place, searchQuery: model.searchText)
                            }
                            .buttonStyle(CitySearchRowPressStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                    .animation(.spring(response: 0.45, dampingFraction: 0.86), value: model.results.count)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $model.searchText, prompt: "City, town, or region")
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
        .task(id: model.searchText) {
            await model.runDebouncedSearch()
        }
    }
}
