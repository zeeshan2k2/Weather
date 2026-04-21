import SwiftUI

struct CitySearchView: View {

    @ObservedObject private var model: CitySearchModel
    @Environment(\.dismiss) private var dismiss
    var onSelectPlace: (WeatherPlace) -> Void

    @State private var isSearchPresented = false

    init(model: CitySearchModel, onSelectPlace: @escaping (WeatherPlace) -> Void) {
        self.model = model
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
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .citySearchSearchable(text: $model.searchText, isPresented: $isSearchPresented, prompt: "City, town, or region")
            .tint(.white)
            .toolbar {
                if #available(iOS 17.5, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isSearchPresented = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel("Focus search")
                    }
                }
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
        .onAppear {
            if #available(iOS 17.5, *) {
                DispatchQueue.main.async {
                    isSearchPresented = true
                }
            }
        }
        .onChange(of: model.searchText) { _ in
            model.scheduleSearchFromTextChange()
        }
    }
}

private extension View {
    @ViewBuilder
    func citySearchSearchable(text: Binding<String>, isPresented: Binding<Bool>, prompt: String) -> some View {
        if #available(iOS 17.5, *) {
            self.searchable(text: text, isPresented: isPresented, prompt: prompt)
        } else {
            self.searchable(text: text, prompt: prompt)
        }
    }
}
