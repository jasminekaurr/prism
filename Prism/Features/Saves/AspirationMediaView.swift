// Summary: Displays saved aspiration media — local file first, otherwise auto link preview image.

import SwiftUI

struct AspirationMediaView: View {
    let item: SavedItem
    var height: CGFloat = 280
    @EnvironmentObject private var container: DependencyContainer

    @State private var localImage: UIImage?
    @State private var previewImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous)
                .fill(PrismColors.violet.opacity(0.3))

            if let image = localImage ?? previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
            } else if isLoading {
                ProgressView()
            } else {
                VStack(spacing: PrismSpacing.xs) {
                    Image(systemName: item.sourceURL == nil ? "photo" : "link")
                        .font(.title)
                        .foregroundStyle(PrismColors.textTertiary)
                    if let domain = item.sourceDomain {
                        Text(domain)
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textSecondary)
                    }
                }
            }

            LinearGradient(
                colors: [.clear, .black.opacity(PrismMaterials.scrimOpacity)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous))
        .task(id: item.id) {
            await loadMedia()
        }
    }

    private func loadMedia() async {
        if let mediaID = item.primaryMediaID,
           let asset = try? await container.mediaRepository.fetch(id: mediaID),
           let url = await container.mediaRepository.localFileURL(for: asset),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            localImage = image
            return
        }

        guard let sourceURL = item.sourceURL else { return }
        isLoading = true
        let result = await LinkPreviewFetcher.fetch(for: sourceURL)
        isLoading = false
        if let data = result.imageData, let image = UIImage(data: data) {
            previewImage = image
        }
    }
}
