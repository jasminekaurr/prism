// Summary: Share Extension entry — accepts URL/image/text into App Group for the main app to import.

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

@objc(ShareViewController)
class ShareViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processIncoming()
    }

    private func processIncoming() {
        let payload = SharePayload()
        let group = DispatchGroup()

        if let items = extensionContext?.inputItems as? [NSExtensionItem] {
            for item in items {
                payload.title = item.attributedContentText?.string
                guard let attachments = item.attachments else { continue }
                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        group.enter()
                        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, _ in
                            if let url = data as? URL {
                                payload.urlString = url.absoluteString
                            }
                            group.leave()
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        group.enter()
                        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, _ in
                            if let text = data as? String {
                                payload.text = text
                            }
                            group.leave()
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        group.enter()
                        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, _ in
                            if let image = data as? UIImage {
                                payload.imageData = image.jpegData(compressionQuality: 0.8)
                            } else if let url = data as? URL, let bytes = try? Data(contentsOf: url) {
                                payload.imageData = bytes
                            }
                            group.leave()
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) {
            ShareInbox.store(payload)
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}

final class SharePayload: Codable {
    var urlString: String?
    var text: String?
    var title: String?
    var imageData: Data?
}

enum ShareInbox {
    static let appGroupID = "group.com.prism.app"

    static func store(_ payload: SharePayload) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            // App Group may be unavailable until provisioning is configured.
            return
        }
        if let data = try? JSONEncoder().encode(payload) {
            defaults.set(data, forKey: "pendingShare")
        }
    }
}
