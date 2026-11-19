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

    /// Okinawa inset only appears once the traveler has visited Okinawa.
    private var hasVisitedOkinawa: Bool {
        guard let okinawaID = Self.prefectureID(matching: "Okinawa") else { return false }
        return env.confirmedVisits().contains {
            Self.prefectureID(matching: $0.prefecture) == okinawaID
        }
    }

/// Match a reverse-geocoded prefecture name ("Kyoto", "Hokkaido",
/// "Tokyo Prefecture"…) to a GeoJSON shape ("Kyoto Fu", "Hokkai Do"…).
    private static func prefectureID(matching name: String) -> String? {
        let visitName = normalize(name)
        guard !visitName.isEmpty else { return nil }
        // Try matching with both the normalized name and the raw shape name
        // (some GeoJSON have suffixes like "-fu", "-ken" that get stripped)
        return JapanGeography.prefectures().first { shape in
            let shapeName = shape.nameEn.lowercased()
                .replacingOccurrences(of: "prefecture", with: "")
                .replacingOccurrences(of: " ", with: "")
            // Try normalized visit name vs raw shape name
            return visitName == shapeName
                || visitName == normalizeShape(shape.nameEn)
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
        return folded.lowercased()
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

    /// Computed distinct cities visited per prefecture from confirmed visits.
    private var visitedPrefectureCounts: [String: Int] {
        Dictionary(grouping: env.confirmedVisits(), by: {
            Self.prefectureID(matching: $0.prefecture) ?? "unknown"
        }).mapValues { visits in
            Set(visits.map { $0.city }).count
        }
    }

    /// Progress note on a translucent washi wash — readable over any part
    /// of the map without becoming a floating card.
    private var statsAnnotation: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(env.atlasStats.prefectures) / 47")
                    .font(TABiFont.placeEnglish(20, weight: .medium))
                    .foregroundStyle(TABiColor.sumi.opacity(0.7))
                Text("PREFECTURES")
                    .font(TABiFont.caption(8, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(TABiColor.sumi.opacity(0.4))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\(env.atlasStats.cities)")
                    .font(TABiFont.placeEnglish(20, weight: .medium))
                    .foregroundStyle(TABiColor.sumi.opacity(0.7))
                Text("CITIES")
                    .font(TABiFont.caption(8, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(TABiColor.sumi.opacity(0.4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(TABiColor.washi.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(TABiColor.sumi.opacity(0.08), lineWidth: 0.5)
                )
        )
        .allowsHitTesting(false)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .topLeading) {
                IllustratedJapanMapView(
                    visitedPrefectureCounts: visitedPrefectureCounts,
                    showsOkinawaInset: hasVisitedOkinawa,
                    onSelectPrefecture: { shape in
                        path.append(PrefectureRoute(
                            id: shape.id,
                            nameEn: shape.nameEn,
                            nameJa: shape.nameJa
                        ))
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Full-bleed: the map flows behind the bottom navigation.
                .washiBackground()

                statsAnnotation
                    .padding(.leading, 20)
                    .padding(.top, 170)
            }
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
