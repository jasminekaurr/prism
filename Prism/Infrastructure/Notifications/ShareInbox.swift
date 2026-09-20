// Summary: Shared Share inbox helpers used by the main app to import extension payloads.

import Foundation

enum MainAppShareInbox {
    static let appGroupID = "group.com.jasminekaur.prism"

    struct Payload: Codable {
        var urlString: String?
        var text: String?
        var title: String?
        var imageData: Data?
    }

    /// True when the App Group container is actually available (capability + provisioning).
    static var isAppGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }

    /// Suite defaults only when the group container exists — avoids CFPrefs console spam.
    static var sharedDefaults: UserDefaults? {
        guard isAppGroupAvailable else { return nil }
        return UserDefaults(suiteName: appGroupID)
    }

    static func consumePending() -> Payload? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "pendingShare"),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return nil
        }
        defaults.removeObject(forKey: "pendingShare")
        var resolved = payload
        if resolved.urlString == nil, let text = resolved.text {
            resolved.urlString = firstURL(in: text)
        }
        return resolved
    }

    private static func firstURL(in text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector?.firstMatch(in: text, options: [], range: range).flatMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
}
