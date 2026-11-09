import SwiftUI

struct PrefectureDetailView: View {
    @Environment(AppEnvironment.self) private var env
    let route: PrefectureRoute
    @Binding var path: NavigationPath

    private var cities: [String] {
        env.cities(inPrefecture: route.nameEn)
    }

    var body: some View {
        List {
            Section {
                ForEach(cities, id: \.self) { city in
                    Button {
                        path.append(CityRoute(
                            prefectureID: route.id,
                            prefectureEn: route.nameEn,
                            prefectureJa: route.nameJa,
                            city: city
                        ))
                    } label: {
                        HStack {
                            Text(city)
                                .font(TABiFont.body(17))
                                .foregroundStyle(TABiColor.sumi)
                            Spacer()
                            Text("\(env.memories(prefecture: route.nameEn, city: city).count)")
                                .font(TABiFont.caption())
                                .foregroundStyle(TABiColor.sumi.opacity(0.45))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(TABiColor.sumi.opacity(0.3))
                        }
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.nameEn.uppercased())
                        .font(TABiFont.title(26))
                        .foregroundStyle(TABiColor.sumi)
                    Text(route.nameJa)
                        .font(TABiFont.placeJapanese(16))
                        .foregroundStyle(TABiColor.sumi.opacity(0.6))
                    Text("\(cities.count) cities remembered")
                        .font(TABiFont.caption())
                        .foregroundStyle(TABiColor.sumi.opacity(0.5))
                        .padding(.top, 4)
                }
                .padding(.vertical, TABiSpacing.sm)
                .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(TABiColor.washi)
        .navigationBarTitleDisplayMode(.inline)
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
        List {
            Section {
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
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.uppercased())
                                    .font(TABiFont.placeEnglish(15))
                                    .foregroundStyle(TABiColor.sumi)
                                Text(place)
                                    .font(TABiFont.placeJapanese(13))
                                    .foregroundStyle(TABiColor.sumi.opacity(0.5))
                            }
                            Spacer()
                            Text("\(env.memories(prefecture: route.prefectureEn, city: route.city, place: place).count)")
                                .font(TABiFont.caption())
                                .foregroundStyle(TABiColor.sumi.opacity(0.45))
                        }
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.city.uppercased())
                        .font(TABiFont.title(26))
                        .foregroundStyle(TABiColor.sumi)
                    Text(route.city)
                        .font(TABiFont.placeJapanese(15))
                        .foregroundStyle(TABiColor.sumi.opacity(0.55))
                    Text("\(env.memories(prefecture: route.prefectureEn, city: route.city).count) memories")
                        .font(TABiFont.caption())
                        .foregroundStyle(TABiColor.sumi.opacity(0.5))
                        .padding(.top, 4)
                }
                .padding(.vertical, TABiSpacing.sm)
                .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(TABiColor.washi)
        .navigationBarTitleDisplayMode(.inline)
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.place.uppercased())
                        .font(TABiFont.title(28))
                        .foregroundStyle(TABiColor.sumi)
                    Text(route.place)
                        .font(TABiFont.placeJapanese(16))
                        .foregroundStyle(TABiColor.sumi.opacity(0.55))
                    Text("\(memories.count) memories · \(route.city)")
                        .font(TABiFont.caption())
                        .foregroundStyle(TABiColor.sumi.opacity(0.5))
                }
                .padding(.horizontal, TABiSpacing.md)
                .padding(.top, TABiSpacing.sm)

                MemoryGridView(memories: memories)
            }
        }
        .background(TABiColor.washi.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
