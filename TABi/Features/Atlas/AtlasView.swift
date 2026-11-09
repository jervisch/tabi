import SwiftUI
import MapKit

struct AtlasView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var path = NavigationPath()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.5, longitude: 138.0),
            span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 10)
        )
    )
    @State private var selectedPrefectureID: String?

    private var visitedPrefectureNames: Set<String> {
        Set(env.confirmedVisits().map(\.prefecture))
    }

    private func isVisited(_ shape: PrefectureShape) -> Bool {
        visitedPrefectureNames.contains { name in
            name == shape.nameEn ||
            name == shape.nameJa ||
            name.hasPrefix(shape.nameEn) ||
            shape.nameEn.hasPrefix(name) ||
            name.replacingOccurrences(of: " Fu", with: "") == shape.nameEn.replacingOccurrences(of: " Fu", with: "")
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                map
                bottomBar
            }
            .background(TABiColor.washi.ignoresSafeArea())
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

    private var header: some View {
        Text(env.atlasStats.caption)
            .font(TABiFont.caption())
            .foregroundStyle(TABiColor.sumi.opacity(0.7))
            .padding(.top, TABiSpacing.sm)
            .padding(.bottom, TABiSpacing.xs)
            .frame(maxWidth: .infinity)
    }

    private var map: some View {
        Map(position: $cameraPosition, selection: $selectedPrefectureID) {
            UserAnnotation()

            ForEach(JapanGeography.prefectures()) { shape in
                let visited = isVisited(shape)
                let points = shape.rings.map { ring in
                    ring.map { MKMapPoint($0) }
                }
                ForEach(Array(points.enumerated()), id: \.offset) { _, ringPoints in
                    MapPolygon(coordinates: ringPoints.map(\.coordinate))
                        .foregroundStyle(visited ? TABiColor.moss.opacity(0.35) : TABiColor.sumi.opacity(0.05))
                        .stroke(
                            visited ? TABiColor.moss.opacity(0.85) : TABiColor.sumi.opacity(0.22),
                            lineWidth: visited ? 1.25 : 0.5
                        )
                        .tag(shape.id)
                }
            }

            ForEach(visibleCityMarkers) { marker in
                Annotation(marker.nameEn, coordinate: marker.coordinate) {
                    VStack(spacing: 2) {
                        Circle()
                            .fill(TABiColor.vermilion)
                            .frame(width: 7, height: 7)
                            .shadow(color: TABiColor.vermilion.opacity(0.35), radius: 3)
                        Text(marker.nameEn)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TABiColor.sumi)
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onChange(of: selectedPrefectureID) { _, newValue in
            guard let id = newValue,
                  let shape = JapanGeography.prefecture(id: id)
            else { return }
            path.append(PrefectureRoute(id: shape.id, nameEn: shape.nameEn, nameJa: shape.nameJa))
            selectedPrefectureID = nil
        }
    }

    private var visibleCityMarkers: [CityPoint] {
        let visitedCities = Set(env.confirmedVisits().map { $0.city })
        let markers = JapanGeography.cityPoints()
        let hit = markers.filter { point in
            visitedCities.contains(point.nameEn) || visitedCities.contains(point.nameJa)
        }
        return hit.isEmpty ? [] : hit
    }

    private var bottomBar: some View {
        HStack {
            Text("旅")
                .font(.system(size: 22, design: .serif))
                .foregroundStyle(TABiColor.sumi)
            Spacer()
            locationLabel
        }
        .padding(.horizontal, TABiSpacing.md)
        .padding(.vertical, TABiSpacing.sm)
        .background(TABiColor.washi)
    }

    @ViewBuilder
    private var locationLabel: some View {
        if let components = env.currentComponents, components.isInJapan || components.hasJapanAdmin {
            VStack(alignment: .trailing, spacing: 2) {
                Text(components.city ?? components.prefecture ?? "Japan")
                    .font(TABiFont.placeEnglish())
                if let ja = components.prefecture {
                    Text(ja)
                        .font(TABiFont.placeJapanese())
                        .foregroundStyle(TABiColor.sumi.opacity(0.55))
                }
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(TABiColor.indigo)
                Text("Exploring somewhere else\nin the world")
                    .font(TABiFont.caption())
                    .foregroundStyle(TABiColor.sumi.opacity(0.7))
                    .multilineTextAlignment(.trailing)
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
