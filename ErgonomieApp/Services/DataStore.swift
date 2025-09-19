import Foundation

actor DataStore {
    static let shared = DataStore()

    private let fileManager = FileManager.default
    private let storeURL: URL

    private init() {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        storeURL = directory.appendingPathComponent("sessions.json")
    }

    func save(session: PoseSession) async throws {
        var sessions = try await fetchSessions()
        sessions.append(session)
        try persist(sessions: sessions)
    }

    func fetchSessions() async throws -> [PoseSession] {
        guard fileManager.fileExists(atPath: storeURL.path) else {
            return []
        }
        let data = try Data(contentsOf: storeURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PoseSession].self, from: data)
    }

    private func persist(sessions: [PoseSession]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(sessions)
        try data.write(to: storeURL, options: .atomic)
    }
}
