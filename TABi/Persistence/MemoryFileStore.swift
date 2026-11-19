import Foundation

enum MemoryFileStore {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Memories", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func write(_ data: Data, id: UUID) throws -> String {
        let name = "\(id.uuidString).jpg"
        let url = directory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return name
    }

    static func read(fileName: String) -> Data? {
        let url = directory.appendingPathComponent(fileName)
        return try? Data(contentsOf: url)
    }
}
