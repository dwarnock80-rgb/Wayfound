import Foundation

protocol WayfoundPersistence: Sendable {
    func load() -> AppState?
    func save(_ state: AppState)
}

struct FileWayfoundPersistence: WayfoundPersistence {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = baseURL.appendingPathComponent("Wayfound", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("state.json")
    }

    func load() -> AppState? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder.wayfound.decode(AppState.self, from: data)
    }

    func save(_ state: AppState) {
        guard let data = try? JSONEncoder.wayfound.encode(state) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}

struct InMemoryWayfoundPersistence: WayfoundPersistence {
    func load() -> AppState? { nil }
    func save(_ state: AppState) {}
}
