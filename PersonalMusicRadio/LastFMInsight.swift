import Foundation

struct LastFMInsight: Equatable, Sendable {
    let listeners: Int?
    let playcount: Int?
    let topTags: [String]

    var hasContent: Bool {
        listeners != nil || playcount != nil || !topTags.isEmpty
    }

    var formattedListeners: String? {
        listeners.map(Self.format)
    }

    var formattedPlaycount: String? {
        playcount.map(Self.format)
    }

    var primaryTag: String? {
        topTags.first
    }

    var tagSummary: String? {
        let tags = Array(topTags.prefix(3))
        guard !tags.isEmpty else {
            return nil
        }

        return tags.joined(separator: ", ")
    }

    private static func format(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
