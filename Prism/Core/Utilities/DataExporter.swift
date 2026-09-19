// Summary: Local JSON export of profile, collections, and saved items for user data portability.

import Foundation

enum DataExporter {
    struct ExportPayload: Codable {
        var exportedAt: Date
        var profile: UserProfile
        var collections: [PrismCollection]
        var items: [SavedItem]
        var note: String
    }

    static func exportJSON(
        profile: UserProfile,
        collections: [PrismCollection],
        items: [SavedItem]
    ) async throws -> URL {
        let payload = ExportPayload(
            exportedAt: .now,
            profile: profile,
            collections: collections,
            items: items,
            note: "Prism local export. Confirmed prices are user-entered. Estimates are not savings."
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("prism-export-\(UUID().uuidString).json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
