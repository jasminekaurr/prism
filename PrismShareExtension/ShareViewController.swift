// Summary: Share Extension entry — accepts URL/image/text into App Group, then opens Prism capture.

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
                                if payload.urlString == nil {
                                    payload.urlString = Self.firstURL(in: text)
                                }
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
            self.openMainAppThenFinish()
        }
    }

    private func openMainAppThenFinish() {
        // Share extensions cannot use UIApplication.open; walk the responder chain.
        if let url = URL(string: "prism://share") {
            _ = openURLViaResponderChain(url)
        }
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    @discardableResult
    private func openURLViaResponderChain(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        let openSel = sel_registerName("openURL:")
        while let current = responder {
            if current.responds(to: openSel) {
                current.perform(openSel, with: url)
                return true
            }
            responder = current.next
        }
        return false
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

final class SharePayload: Codable {
    var urlString: String?
    var text: String?
    var title: String?
    var imageData: Data?
}

enum ShareInbox {
    static let appGroupID = "group.com.jasminekaur.prism"

    static func store(_ payload: SharePayload) {
        // Skip suite access when the App Group container isn't provisioned —
        // UserDefaults(suiteName:) otherwise logs CFPrefs "kCFPreferencesAnyUser" noise.
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil,
              let defaults = UserDefaults(suiteName: appGroupID) else {
            return
        }
        if let data = try? JSONEncoder().encode(payload) {
            defaults.set(data, forKey: "pendingShare")
        }
    }
}
