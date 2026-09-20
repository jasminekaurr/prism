// Summary: Local mock AI description for item detail — no network; real generation is Future.

import Foundation

enum MockAIDescription {
    /// Builds a short description from title, domain, and notes for MVP display.
    static func text(for item: SavedItem) -> String {
        if let notes = item.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            return notes
        }
        let domain = item.sourceDomain?.replacingOccurrences(of: "www.", with: "") ?? "the web"
        let hostLabel: String
        if domain.contains("instagram") {
            hostLabel = "An Instagram post"
        } else if domain.contains("tiktok") {
            hostLabel = "A TikTok"
        } else if domain.contains("pinterest") {
            hostLabel = "A Pinterest pin"
        } else {
            hostLabel = "A link from \(domain)"
        }
        return "\(hostLabel) about \(item.title). Saved so you can revisit later — or turn it into a goal when you’re ready."
    }
}
