# Weather

A SwiftUI-based weather application focused on real-time data handling, clean architecture, and a structured multi-screen user experience.

---

## Features

- Real-time weather data integration
- Location-based forecasts
- Daily weather breakdown with detailed view
- AI-generated weather summaries
- Home screen widgets (small and medium)
- Multiple coordinated screens (list, detail, summary)
- State-driven UI updates

---

## Screenshots

### App Screens

<p align="center">
  <img src="https://github.com/zeeshan2k2/Weather/blob/main/screenshots/weather-view.PNG" width="230">
  <img src="https://github.com/zeeshan2k2/Weather/blob/main/screenshots/weather-list-view.PNG" width="230">
  <img src="https://github.com/zeeshan2k2/Weather/blob/main/screenshots/day-detail-view.PNG" width="230">
  <img src="https://github.com/zeeshan2k2/Weather/blob/main/screenshots/ai-summary-view.PNG" width="230">
</p>

### Widgets

<p align="center">
  <img src="https://github.com/zeeshan2k2/Weather/blob/main/screenshots/widget-small.jpg" width="180">
  <img src="https://github.com/zeeshan2k2/Weather/blob/main/screenshots/widget-medium.jpg" width="260">
</p>

---

## Architecture

The app follows a clear separation of concerns using a lightweight MVVM structure:

- **Networking Layer** handles API requests and decoding
- **ViewModels** manage state and transform data for the UI
- **Views** react to state changes and render UI

Data flow is unidirectional and driven by async operations:
