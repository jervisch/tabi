import Foundation
import SwiftData
import Combine
import CoreLocation
import UIKit

@MainActor
@Observable
final class AppEnvironment {
    let container: ModelContainer
    let memoryStore: MemoryStore
    let visitStore: VisitStore
    let locationProvider: any LocationProvider
    let camera: any CameraCapturing
    let placeResolver: PlaceResolver
    let film: TABiFilmProcessor
    let exporter: any PhotoLibraryExporting

    private(set) var atlasStats: AtlasStats = .empty
    private(set) var currentComponents: PlaceComponents?
    private(set) var currentSample: LocationSample?
    private(set) var lastSavedMemory: Memory?
    private(set) var lastSavedImage: UIImage?
    private(set) var showMemorySavedCard = false
    var isCapturing = false

    init(
        container: ModelContainer,
        locationProvider: any LocationProvider = RealLocationProvider(),
        camera: any CameraCapturing = RealCamera(),
        placeResolver: PlaceResolver = PlaceResolver(),
        film: TABiFilmProcessor = TABiFilmProcessor(),
        exporter: any PhotoLibraryExporting = RealPhotoLibraryExporter()
    ) {
        self.container = container
        let context = ModelContext(container)
        self.memoryStore = MemoryStore(context: context)
        self.visitStore = VisitStore(context: context)
        self.locationProvider = locationProvider
        self.camera = camera
        self.placeResolver = placeResolver
        self.film = film
        self.exporter = exporter
        refreshStats()
        if CommandLine.arguments.contains("-seedDemo") {
            try? SeedData.load(into: context)
            refreshStats()
        }
    }

    func refreshStats() {
        atlasStats = (try? visitStore.confirmedStats()) ?? .empty
    }

    func refreshCurrentLocation() async {
        _ = try? await locationProvider.requestWhenInUseAuthorization()
        guard let sample = await locationProvider.currentSample() else { return }
        RecentLocationStore.shared.append(sample)
        currentSample = sample
        currentComponents = await placeResolver.resolve(sample: sample)
    }

    func takePhoto() async throws -> (processedImage: UIImage, components: PlaceComponents?) {
        isCapturing = true
        defer { isCapturing = false }

        let sample = await locationProvider.currentSample()
        let components: PlaceComponents
        if let sample {
            RecentLocationStore.shared.append(sample)
            components = await placeResolver.resolve(sample: sample)
            currentComponents = components
        } else {
            components = PlaceComponents()
        }

        let raw = try await camera.capturePhoto()
        let processed = (try? film.process(raw)) ?? raw
        let uiImage = UIImage(data: processed) ?? UIImage()

        let id = UUID()
        let fileName = try MemoryFileStore.write(processed, id: id)

        return (processedImage: uiImage, components: components)
    }

    func saveMemory(processed: UIImage, components: PlaceComponents?, capturedAt: Date) async throws {
        let processedData = processed.jpegData(compressionQuality: 0.82) ?? processed.pngData() ?? Data()
        let id = UUID()
        let fileName = try MemoryFileStore.write(processedData, id: id)

        let memory = Memory(
            imageData: processedData,
            capturedAt: capturedAt,
            latitude: 0,
            longitude: 0,
            accuracy: 999,
            placeName: components?.placeName ?? "",
            city: components?.city ?? "",
            prefecture: components?.prefecture ?? "",
            country: components?.country ?? "",
            imageFileName: fileName
        )
        try memoryStore.insert(memory)

        if let sample = await locationProvider.currentSample() {
            let dwell = RecentLocationStore.shared.dwellSeconds(
                near: CLLocationCoordinate2D(latitude: sample.latitude, longitude: sample.longitude)
            )
            if let components {
                _ = try VisitDetector.attach(
                    memory: memory,
                    components: components,
                    accuracy: sample.accuracy,
                    dwellSeconds: dwell,
                    store: visitStore
                )
            }
        }
        try? container.mainContext.save()
        refreshStats()

        lastSavedMemory = memory
        lastSavedImage = processed

        showMemorySavedCard = false
    }

    func allMemories() -> [Memory] {
        (try? memoryStore.all()) ?? []
    }

    func confirmedVisits() -> [Visit] {
        (try? visitStore.confirmed()) ?? []
    }

    func memories(prefecture: String? = nil, city: String? = nil, place: String? = nil) -> [Memory] {
        allMemories().filter { m in
            if let prefecture, m.prefecture != prefecture { return false }
            if let city, m.city != city { return false }
            if let place, m.placeName != place { return false }
            return true
        }
    }

    func places(inCity city: String, prefecture: String) -> [String] {
        let names = memories(prefecture: prefecture, city: city).compactMap(\.placeName)
        return Array(Set(names)).sorted()
    }

    func cities(inPrefecture prefecture: String) -> [String] {
        let names = memories(prefecture: prefecture).compactMap(\.city)
        return Array(Set(names)).sorted()
    }

    func exportLastToPhotos() async throws {
        guard let memory = lastSavedMemory else { return }
        guard await exporter.requestAddPermission() else {
            throw CameraError.permissionDenied
        }
        try await exporter.export(jpegData: memory.imageData)
    }

    func dismissSavedCard() {
        showMemorySavedCard = false
        lastSavedMemory = nil
        lastSavedImage = nil
    }
}