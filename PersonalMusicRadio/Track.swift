import Foundation

struct Track: Identifiable, Equatable, Sendable {
    let url: URL
    let title: String
    let artist: String?

    var id: URL { url }

    init(url: URL, title: String? = nil, artist: String? = nil) {
        self.url = url
        self.title = title?.trimmedNonEmpty ?? url.deletingPathExtension().lastPathComponent
        self.artist = artist?.trimmedNonEmpty
    }

    var detailsText: String {
        if let artist {
            return "\(artist) · Local file · \(url.pathExtension.uppercased())"
        }

        return "Local file · \(url.pathExtension.uppercased())"
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
