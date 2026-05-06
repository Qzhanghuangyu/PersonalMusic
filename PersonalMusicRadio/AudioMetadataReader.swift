import AVFoundation
import Foundation

struct AudioMetadataSnapshot: Equatable {
    let title: String?
    let artist: String?
}

struct AudioMetadataReader {
    private let metadataLoader: (URL) -> AudioMetadataSnapshot

    init(metadataLoader: @escaping (URL) -> AudioMetadataSnapshot = AudioMetadataReader.loadMetadata) {
        self.metadataLoader = metadataLoader
    }

    func track(for url: URL) -> Track {
        let metadata = metadataLoader(url)
        return Track(url: url, title: metadata.title, artist: metadata.artist)
    }

    private static func loadMetadata(for url: URL) -> AudioMetadataSnapshot {
        let asset = AVURLAsset(url: url)
        let metadata = asset.commonMetadata

        return AudioMetadataSnapshot(
            title: stringValue(for: .commonKeyTitle, in: metadata),
            artist: stringValue(for: .commonKeyArtist, in: metadata)
        )
    }

    private static func stringValue(for key: AVMetadataKey, in metadata: [AVMetadataItem]) -> String? {
        metadata
            .first(where: { $0.commonKey == key })?
            .stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
