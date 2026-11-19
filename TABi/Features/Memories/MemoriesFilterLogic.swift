import Foundation

enum MemoriesFilterLogic {
    static func filter(
        _ memories: [Memory],
        prefecture: String?,
        city: String?,
        from: Date?,
        to: Date?
    ) -> [Memory] {
        memories.filter { m in
            if let prefecture, m.prefecture != prefecture { return false }
            if let city, m.city != city { return false }
            if let from, m.capturedAt < from { return false }
            if let to, m.capturedAt > to { return false }
            return true
        }
    }
}
