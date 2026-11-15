import SwiftUI

struct MemoriesView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var prefectureFilter: String?
    @State private var cityFilter: String?
    @State private var fromDate: Date?
    @State private var toDate: Date?
    @State private var showFilters = false
    @State private var selected: Memory?

    private var filtered: [Memory] {
        env.allMemories().filter { m in
            if let prefectureFilter, m.prefecture != prefectureFilter { return false }
            if let cityFilter, m.city != cityFilter { return false }
            if let fromDate, m.capturedAt < fromDate { return false }
            if let toDate, m.capturedAt > toDate { return false }
            return true
        }
    }

    private var tripsByYear: [(year: Int, trips: [Trip])] {
        let trips = TripGrouper.group(filtered)
        let grouped = Dictionary(grouping: trips, by: \.year)
        return grouped.keys.sorted(by: >).map { year in
            (year: year, trips: grouped[year] ?? [])
        }
    }

    private var prefectureOptions: [String] {
        Array(Set(env.allMemories().compactMap(\.prefecture))).sorted()
    }

    private var cityOptions: [String] {
        Array(Set(env.allMemories().compactMap(\.city))).sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TABiSpacing.lg) {
                    filterBar

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        ForEach(tripsByYear, id: \.year) { section in
                            VStack(alignment: .leading, spacing: TABiSpacing.md) {
                                Text(String(section.year))
                                    .font(TABiFont.title(32))
                                    .foregroundStyle(TABiColor.sumi)
                                    .padding(.horizontal, TABiSpacing.md)

                                ForEach(section.trips) { trip in
                                    tripSection(trip)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, TABiSpacing.md)
            }
            .background(TABiColor.washi.ignoresSafeArea())
            .navigationTitle("思い出 Memories")
            .toolbarBackground(TABiColor.washi, for: .navigationBar)
            .sheet(item: $selected) { memory in
                PhotoDetailView(memory: memory)
            }
            .sheet(isPresented: $showFilters) {
                MemoriesFilterView(
                    prefectures: prefectureOptions,
                    cities: cityOptions,
                    prefecture: $prefectureFilter,
                    city: $cityFilter,
                    from: $fromDate,
                    to: $toDate
                )
            }
        }
    }

    private var filterBar: some View {
        HStack {
            if prefectureFilter != nil || cityFilter != nil || fromDate != nil || toDate != nil {
                Button {
                    prefectureFilter = nil
                    cityFilter = nil
                    fromDate = nil
                    toDate = nil
                } label: {
                    Label("Clear", systemImage: "xmark.circle.fill")
                        .font(TABiFont.caption())
                        .foregroundStyle(TABiColor.sumi.opacity(0.6))
                }
            }
            Spacer()
            Button {
                showFilters = true
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    .font(TABiFont.caption())
                    .foregroundStyle(TABiColor.sumi)
            }
        }
        .padding(.horizontal, TABiSpacing.md)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(TABiColor.sumi.opacity(0.3))
            Text("No memories yet")
                .font(TABiFont.body())
                .foregroundStyle(TABiColor.sumi.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func tripSection(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.title.uppercased())
                    .font(TABiFont.placeEnglish(15))
                    .foregroundStyle(TABiColor.sumi)
                Spacer()
                Text(dateRangeLabel(trip))
                    .font(TABiFont.monoDate(11))
                    .foregroundStyle(TABiColor.sumi.opacity(0.5))
            }
            .padding(.horizontal, TABiSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(trip.memories) { memory in
                        Button {
                            selected = memory
                        } label: {
                            MemoryThumb(memory: memory)
                                .frame(width: 160, height: 160)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, TABiSpacing.md)
            }
        }
    }

    private func dateRangeLabel(_ trip: Trip) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yy"
        if Calendar.current.isDate(trip.startDate, inSameDayAs: trip.endDate) {
            return f.string(from: trip.startDate)
        }
        return "\(f.string(from: trip.startDate)) – \(f.string(from: trip.endDate))"
    }
}

struct MemoriesFilterView: View {
    @Environment(\.dismiss) private var dismiss
    let prefectures: [String]
    let cities: [String]
    @Binding var prefecture: String?
    @Binding var city: String?
    @Binding var from: Date?
    @Binding var to: Date?

    @State private var fromDate = Date().addingTimeInterval(-90 * 24 * 3600)
    @State private var toDate = Date()
    @State private var useFrom = false
    @State private var useTo = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("Prefecture", selection: $prefecture) {
                        Text("Any").tag(String?.none)
                        ForEach(prefectures, id: \.self) { name in
                            Text(name).tag(String?.some(name))
                        }
                    }
                    Picker("City", selection: $city) {
                        Text("Any").tag(String?.none)
                        ForEach(cities, id: \.self) { name in
                            Text(name).tag(String?.some(name))
                        }
                    }
                }
                Section("Time") {
                    Toggle("From", isOn: $useFrom)
                    if useFrom {
                        DatePicker("Start", selection: $fromDate, displayedComponents: .date)
                    }
                    Toggle("To", isOn: $useTo)
                    if useTo {
                        DatePicker("End", selection: $toDate, displayedComponents: .date)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(TABiColor.washi)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TABiColor.washi, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        from = useFrom ? fromDate : nil
                        to = useTo ? toDate : nil
                        dismiss()
                    }
                }
            }
        }
    }
}
