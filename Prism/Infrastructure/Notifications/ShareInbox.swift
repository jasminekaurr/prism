// Summary: Shared Share inbox helpers used by the main app to import extension payloads.

import Foundation

enum MainAppShareInbox {
    static let appGroupID = "group.com.prism.app"

    struct Payload: Codable {
        var urlString: String?
        var text: String?
        var title: String?
        var imageData: Data?
    }

    static func consumePending() -> Payload? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "pendingShare"),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return nil
        }
        defaults.removeObject(forKey: "pendingShare")
        return payload
    }
}
