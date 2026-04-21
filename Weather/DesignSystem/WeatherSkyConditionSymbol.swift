import SwiftUI

enum WeatherSkyConditionSymbol {

    @ViewBuilder
    static func image(systemName: String) -> some View {
        if WeatherPresentation.usesCloudMoonHierarchicalSymbol(systemName: systemName) {
            Image(systemName: systemName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.95), .white.opacity(0.48))
        } else {
            Image(systemName: systemName)
                .symbolRenderingMode(.multicolor)
        }
    }

    @ViewBuilder
    static func resizableImage(systemName: String, contentMode: ContentMode = .fit) -> some View {
        if WeatherPresentation.usesCloudMoonHierarchicalSymbol(systemName: systemName) {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.95), .white.opacity(0.48))
        } else {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .symbolRenderingMode(.multicolor)
        }
    }
}
