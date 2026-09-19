// Summary: Fetches link title/image via Apple LinkPresentation (Open Graph) — no custom scraping.

import Foundation
import LinkPresentation
import UIKit
import UniformTypeIdentifiers

struct LinkPreviewResult: Sendable {
    var title: String?
    var domain: String?
    var imageData: Data?
}

enum LinkPreviewFetcher {
    /// Uses system Link Presentation metadata only. Never bypasses platform restrictions.
    static func fetch(for url: URL) async -> LinkPreviewResult {
        let provider = LPMetadataProvider()
        provider.timeout = 12

        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            let title = metadata.title
            let domain = url.host
            var imageData: Data?

            if let imageProvider = metadata.imageProvider {
                imageData = await loadImageData(from: imageProvider)
            } else if let iconProvider = metadata.iconProvider {
                imageData = await loadImageData(from: iconProvider)
            }

            return LinkPreviewResult(title: title, domain: domain, imageData: imageData)
        } catch {
            return LinkPreviewResult(title: nil, domain: url.host, imageData: nil)
        }
    }

    private static func loadImageData(from itemProvider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { continuation in
            var resumed = false
            let finish: (Data?) -> Void = { data in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: data)
            }

            itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                if let data, UIImage(data: data) != nil {
                    finish(data)
                    return
                }
                itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    let image = object as? UIImage
                    finish(image?.jpegData(compressionQuality: 0.85))
                }
            }
        }
    }
}
