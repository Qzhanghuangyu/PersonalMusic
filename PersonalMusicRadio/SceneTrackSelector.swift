import Foundation

struct TrackMatchResult: Equatable {
    let currentTrackLine: String
    let upNextTrackLine: String
    let fallbackLine: String?
}

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

    func matchResult(
        currentTrack: Track?,
        upNextTrack: Track?,
        scene: ListeningScene
    ) -> TrackMatchResult {
        let currentDetail = detail(for: currentTrack?.title, scene: scene)
        let upNextDetail = detail(for: upNextTrack?.title, scene: scene)

        let currentTrackLine: String
        if let currentTrack {
            if currentDetail.score > 0 {
                currentTrackLine = "Now on air matches \(sceneLabel(for: scene)) cues: \(keywordList(currentDetail.matchedKeywords))."
            } else {
                currentTrackLine = "Now on air keeps the original order for \(sceneLabel(for: scene)); no local rule matched."
            }
        } else {
            currentTrackLine = "Now on air is waiting for a local track."
        }

        let upNextTrackLine: String
        if let upNextTrack {
            if upNextDetail.score > 0 {
                if currentDetail.score > upNextDetail.score {
                    upNextTrackLine = "Up next stays behind because \(keywordList(upNextDetail.matchedKeywords)) still scored below the current track."
                } else if currentDetail.score == upNextDetail.score, currentTrack != nil {
                    upNextTrackLine = "Up next also matches \(keywordList(upNextDetail.matchedKeywords)); original order keeps it behind the current track."
                } else {
                    upNextTrackLine = "Up next is queued from \(sceneLabel(for: scene)) cues: \(keywordList(upNextDetail.matchedKeywords))."
                }
            } else {
                upNextTrackLine = "Up next keeps the original order and waits for a stronger \(sceneLabel(for: scene)) match."
            }
        } else {
            upNextTrackLine = "Up next will appear after the queue refreshes."
        }

        let fallbackLine: String?
        if currentDetail.score == 0 && upNextDetail.score == 0 {
            fallbackLine = "No scene keywords matched yet, so the queue keeps its original order until the next refresh."
        } else {
            fallbackLine = nil
        }

        return TrackMatchResult(
            currentTrackLine: currentTrackLine,
            upNextTrackLine: upNextTrackLine,
            fallbackLine: fallbackLine
        )
    }

    private func score(for title: String, scene: ListeningScene) -> Int {
        detail(for: title, scene: scene).score
    }

    private func detail(for title: String?, scene: ListeningScene) -> MatchDetail {
        guard let title else {
            return MatchDetail(matchedKeywords: [])
        }

        let normalizedTitle = title.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        let matchedKeywords = keywordsByScene[scene, default: []].filter { keyword in
            normalizedTitle.localizedCaseInsensitiveContains(keyword)
        }

        return MatchDetail(matchedKeywords: matchedKeywords)
    }

    private func keywordList(_ keywords: [String]) -> String {
        keywords.joined(separator: ", ")
    }

    private func sceneLabel(for scene: ListeningScene) -> String {
        switch scene {
        case .morning:
            return "morning"
        case .work:
            return "focus"
        case .lunch:
            return "lunch"
        case .nap:
            return "quiet"
        case .happy:
            return "lift"
        }
    }
}

private struct MatchDetail {
    let matchedKeywords: [String]

    var score: Int {
        matchedKeywords.count
    }
}
