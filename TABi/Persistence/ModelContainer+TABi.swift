import Foundation
import SwiftData

enum ModelContainerFactory {
    @MainActor
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([Memory.self, Visit.self])
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
