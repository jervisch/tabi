import Foundation
import SwiftData

@MainActor
final class MemoryStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func insert(_ memory: Memory) throws {
        context.insert(memory)
        try context.save()
    }

    func all() throws -> [Memory] {
        try context.fetch(FetchDescriptor<Memory>(sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]))
    }

    func byPrefecture() throws -> [String: [Memory]] {
        Dictionary(grouping: try all()) { $0.prefecture ?? "Unknown" }
    }

    func delete(_ memory: Memory) throws {
        context.delete(memory)
        try context.save()
    }
}
