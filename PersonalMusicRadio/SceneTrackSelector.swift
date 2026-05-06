import Foundation

struct SceneTrackSelector {
    private let keywordsByScene: [ListeningScene: [String]]

    init(
        keywordsByScene: [ListeningScene: [String]] = [
            .morning: ["morning", "sunrise", "wake", "coffee", "light", "breeze", "soft"],
            .work: ["focus", "study", "work", "coding", "instrumental", "ambient", "concentration"],
            .lunch: ["lunch", "cafe", "coffee", "bossa", "acoustic", "jazz", "brunch"],
            .nap: ["sleep", "nap", "calm", "soft", "ambient", "piano", "rain", "quiet"],
            .happy: ["happy", "upbeat", "dance", "pop", "sun", "bright", "groove"]
        ]
    ) {
        self.keywordsByScene = keywordsByScene
    }

    func orderedTracks(from tracks: [Track], for scene: ListeningScene) -> [Track] {
        tracks.enumerated()
            .sorted { left, right in
                let leftScore = score(for: left.element.title, scene: scene)
                let rightScore = score(for: right.element.title, scene: scene)

                if leftScore != rightScore {
                    return leftScore > rightScore
                }

                return left.offset < right.offset
            }
            .map(\.element)
    }

    func orderedTracks(from urls: [URL], for scene: ListeningScene) -> [URL] {
        urls.enumerated()
            .sorted { left, right in
                let leftScore = score(for: left.element.deletingPathExtension().lastPathComponent, scene: scene)
                let rightScore = score(for: right.element.deletingPathExtension().lastPathComponent, scene: scene)

                if leftScore != rightScore {
                    return leftScore > rightScore
                }

                return left.offset < right.offset
            }
            .map(\.element)
    }

    private func score(for title: String, scene: ListeningScene) -> Int {
        let normalizedTitle = title.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        return keywordsByScene[scene, default: []].reduce(into: 0) { score, keyword in
            if normalizedTitle.localizedCaseInsensitiveContains(keyword) {
                score += 1
            }
        }
    }
}
