import SwiftUI
import CoreLocation

struct AtlasView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var path = NavigationPath()

    private var visibleCityMarkers: [CityPoint] {
        let visitedCities = Set(env.confirmedVisits().map { $0.city })
        return JapanGeography.cityPoints().filter { point in
            visitedCities.contains(point.nameEn) || visitedCities.contains(point.nameJa)
        }
    }

    private var isInJapan: Bool {
        if let components = env.currentComponents {
            return components.isInJapan || components.hasJapanAdmin
        }
        return true
    }

    /// Prefecture id → distinct visited cities, from confirmed visits.
    private var visitedPrefectureCounts: [String: Int] {
        var citiesByPrefecture: [String: Set<String>] = [:]
        for visit in env.confirmedVisits() {
            guard let id = Self.prefectureID(matching: visit.prefecture) else { continue }
            citiesByPrefecture[id, default: []].insert(visit.city)
        }
        return citiesByPrefecture.mapValues { $0.count }
    }

    /// Match a reverse-geocoded prefecture name ("Kyoto", "Hokkaido",
    /// "Tokyo Prefecture"…) to a GeoJSON shape ("Kyoto Fu", "Hokkai Do"…).
    private static func prefectureID(matching name: String) -> String? {
        let visitName = normalize(name)
        guard !visitName.isEmpty else { return nil }
        return JapanGeography.prefectures().first { shape in
            let shapeName = normalizeShape(shape.nameEn)
            guard !shapeName.isEmpty else { return false }
            return visitName == shapeName
                || visitName.hasPrefix(shapeName)
                || shapeName.hasPrefix(visitName)
        }?.id
    }

    private static func normalize(_ name: String) -> String {
        // Strip diacritics first (CLGeocoder returns "Hyōgo", "Ōita", "Kyōto").
        let folded = name.folding(
            options: [.diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        return folded
            .lowercased()
            .replacingOccurrences(of: "prefecture", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    /// Like `normalize`, plus strips one trailing kanji suffix
    /// (Ken / Fu / To / Do) — applied only to shape names.
    private static func normalizeShape(_ name: String) -> String {
        var s = normalize(name)
        for suffix in ["ken", "fu", "to", "do"] where s.hasSuffix(suffix) && s.count > suffix.count {
            s = String(s.dropLast(suffix.count))
            break
        }
        return s
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header

                IllustratedJapanMapView(
                    visitedCities: visibleCityMarkers,
                    visitedPrefectureCounts: visitedPrefectureCounts,
                    currentCoordinate: env.currentSample.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    },
                    isInJapan: isInJapan,
                    onSelectPrefecture: { shape in
                        path.append(PrefectureRoute(
                            id: shape.id,
                            nameEn: shape.nameEn,
                            nameJa: shape.nameJa
                        ))
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Clear the bottom navigation — the map remains the page.
                .padding(.bottom, 72)
            }
            .washiBackground()
            .navigationDestination(for: PrefectureRoute.self) { route in
                PrefectureDetailView(route: route, path: $path)
            }
            .navigationDestination(for: CityRoute.self) { route in
                CityDetailView(route: route, path: $path)
            }
            .navigationDestination(for: PlaceRoute.self) { route in
                PlaceDetailView(route: route)
            }
            .task {
                await env.refreshCurrentLocation()
            }
        }
    }

    /// Quiet journal title — no decoration, no cards.
    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text("旅")
                    .font(TABiFont.title(28))
                    .foregroundStyle(TABiColor.sumi)

                Text("TABI")
                    .font(TABiFont.placeEnglish(15, weight: .semibold))
                    .tracking(6)
                    .foregroundStyle(TABiColor.sumi.opacity(0.7))
            }

            Text(env.atlasStats.caption)
                .font(TABiFont.caption(12))
                .foregroundStyle(TABiColor.sumi.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }
}

struct PrefectureRoute: Hashable {
    let id: String
    let nameEn: String
    let nameJa: String
}

struct CityRoute: Hashable {
    let prefectureID: String
    let prefectureEn: String
    let prefectureJa: String
    let city: String
}

struct PlaceRoute: Hashable {
    let prefectureID: String
    let prefectureEn: String
    let prefectureJa: String
    let city: String
    let place: String
}
