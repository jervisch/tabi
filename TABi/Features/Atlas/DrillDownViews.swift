import SwiftUI

// Editorial atlas drill-down — art heroes + card rows (design kit).

/// Deterministic thumbnail picker for list rows.
enum TabiThumb {
    static let all = [
        "thumb_pagoda", "thumb_lantern", "thumb_mountain", "thumb_torii",
        "thumb_house", "thumb_train", "thumb_bamboo", "thumb_sakura"
    ]

    static func name(for key: String) -> String {
        let h = key.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 9973 }
        return all[h % all.count]
    }
}

private struct RowThumb: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 34, height: 34)
            .frame(width: 44, height: 44)
            .background(Circle().fill(TABiColor.washi))
            .overlay(Circle().stroke(TABiColor.sumi.opacity(0.12), lineWidth: 1))
    }
}

private struct RowChevron: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 6, y: 6))
            path.addLine(to: CGPoint(x: 0, y: 12))
        }
        .stroke(TABiColor.sumi.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        .frame(width: 12, height: 12)
    }
}

private struct HeroBanner: View {
    let imageName: String
    var height: CGFloat = 150

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
    }
}

struct PrefectureDetailView: View {
    @Environment(AppEnvironment.self) private var env
    let route: PrefectureRoute
    @Binding var path: NavigationPath

    private var cities: [String] {
        env.cities(inPrefecture: route.nameEn)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HeroBanner(imageName: "hero_prefecture", height: 160)
                hero
                if cities.isEmpty {
                    emptyState
                } else {
                    cityRows
                }
            }
            .padding(.bottom, 100)
        }
        .background(TABiColor.washi.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TABiColor.washi, for: .navigationBar)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(route.nameJa)
                .font(TABiFont.title(36))
                .foregroundStyle(TABiColor.sumi)
            Text(route.nameEn.uppercased())
                .font(TABiFont.placeEnglish(15, weight: .semibold))
                .tracking(3)
                .foregroundStyle(TABiColor.sumi.opacity(0.65))
            Text("\(cities.count) cities remembered")
                .font(TABiFont.caption())
                .foregroundStyle(TABiColor.sumi.opacity(0.5))
        }
        .padding(.horizontal, TABiSpacing.lg)
        .padding(.top, TABiSpacing.sm)
        .padding(.bottom, TABiSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .bottomLeading) {
                TABiColor.washi
                PaperGrainOverlay(opacity: 0.03)
            }
        )
    }

    private var cityRows: some View {
        VStack(spacing: 10) {
            ForEach(cities, id: \.self) { city in
                Button {
                    path.append(CityRoute(
                        prefectureID: route.id,
                        prefectureEn: route.nameEn,
                        prefectureJa: route.nameJa,
                        city: city
                    ))
                } label: {
                    HStack(spacing: 12) {
                        RowThumb(imageName: TabiThumb.name(for: city))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city)
                                .font(TABiFont.placeEnglish(17, weight: .semibold))
                                .foregroundStyle(TABiColor.sumi)
                            Text("\(env.memories(prefecture: route.nameEn, city: city).count) memories")
                                .font(TABiFont.caption(11))
                                .foregroundStyle(TABiColor.sumi.opacity(0.5))
                        }
                        Spacer()
                        RowChevron()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, TABiSpacing.lg)
            }
        }
        .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No cities remembered here yet")
                .font(TABiFont.body())
                .foregroundStyle(TABiColor.sumi.opacity(0.6))
            Text("Take a photo while visiting — your atlas will fill in.")
                .font(TABiFont.caption())
                .foregroundStyle(TABiColor.sumi.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, TABiSpacing.lg)
    }
}

struct CityDetailView: View {
    @Environment(AppEnvironment.self) private var env
    let route: CityRoute
    @Binding var path: NavigationPath

    private var places: [String] {
        env.places(inCity: route.city, prefecture: route.prefectureEn)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HeroBanner(imageName: "hero_city", height: 150)
                hero
                if places.isEmpty {
                    emptyState
                } else {
                    placeRows
                }
            }
            .padding(.bottom, 100)
        }
        .background(TABiColor.washi.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TABiColor.washi, for: .navigationBar)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(route.city)
                .font(TABiFont.title(32))
                .foregroundStyle(TABiColor.sumi)
            Text("\(route.prefectureJa) / \(route.prefectureEn)")
                .font(TABiFont.placeJapanese(14))
                .foregroundStyle(TABiColor.sumi.opacity(0.6))
            Text("\(env.memories(prefecture: route.prefectureEn, city: route.city).count) memories")
                .font(TABiFont.caption())
                .foregroundStyle(TABiColor.sumi.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(.horizontal, TABiSpacing.lg)
        .padding(.top, TABiSpacing.sm)
        .padding(.bottom, TABiSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TABiColor.washi)
    }

    private var placeRows: some View {
        VStack(spacing: 10) {
            ForEach(places, id: \.self) { place in
                Button {
                    path.append(PlaceRoute(
                        prefectureID: route.prefectureID,
                        prefectureEn: route.prefectureEn,
                        prefectureJa: route.prefectureJa,
                        city: route.city,
                        place: place
                    ))
                } label: {
                    HStack(spacing: 12) {
                        RowThumb(imageName: TabiThumb.name(for: place))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place)
                                .font(TABiFont.placeEnglish(17, weight: .semibold))
                                .foregroundStyle(TABiColor.sumi)
                            Text("\(env.memories(prefecture: route.prefectureEn, city: route.city, place: place).count) memories")
                                .font(TABiFont.caption(11))
                                .foregroundStyle(TABiColor.sumi.opacity(0.5))
                        }
                        Spacer()
                        RowChevron()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, TABiSpacing.lg)
            }
        }
        .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No places remembered here yet")
                .font(TABiFont.body())
                .foregroundStyle(TABiColor.sumi.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct PlaceDetailView: View {
    @Environment(AppEnvironment.self) private var env
    let route: PlaceRoute

    private var memories: [Memory] {
        env.memories(
            prefecture: route.prefectureEn,
            city: route.city,
            place: route.place
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TABiSpacing.md) {
                HeroBanner(imageName: "hero_place", height: 150)

                VStack(alignment: .leading, spacing: 6) {
                    Text(route.place)
                        .font(TABiFont.title(32))
                        .foregroundStyle(TABiColor.sumi)
                    Text("\(route.city) · \(route.prefectureEn)")
                        .font(TABiFont.placeJapanese(14))
                        .foregroundStyle(TABiColor.sumi.opacity(0.55))
                    Text("\(memories.count) memories")
                        .font(TABiFont.caption())
                        .foregroundStyle(TABiColor.sumi.opacity(0.5))
                        .padding(.top, 2)
                }
                .padding(.horizontal, TABiSpacing.lg)

                MemoryGridView(memories: memories)
            }
            .padding(.bottom, 100)
        }
        .background(TABiColor.washi.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TABiColor.washi, for: .navigationBar)
    }
}
