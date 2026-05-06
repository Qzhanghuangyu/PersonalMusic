import Foundation

enum LastFMFetchResult: Equatable, Sendable {
    case notConfigured
    case missingMetadata
    case noMatch
    case requestFailed
    case insight(LastFMInsight)
}

struct LastFMService: Sendable {
    typealias DataLoader = @Sendable (URL) async throws -> (Data, URLResponse)

    private let apiKeyProvider: @Sendable () -> String?
    private let dataLoader: DataLoader

    init(
        apiKeyProvider: @escaping @Sendable () -> String? = {
            LastFMKeyStore().readKey() ??
                ProcessInfo.processInfo.environment["LASTFM_API_KEY"]?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        },
        dataLoader: @escaping DataLoader = { url in
            try await URLSession.shared.data(from: url)
        }
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.dataLoader = dataLoader
    }

    func fetchInsight(for track: Track) async -> LastFMFetchResult {
        guard let apiKey = apiKeyProvider()?.nilIfEmpty else {
            return .notConfigured
        }

        guard let artist = track.artist?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
              let title = track.title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
              let infoURL = requestURL(
                method: "track.getInfo",
                apiKey: apiKey,
                artist: artist,
                trackTitle: title
              ),
              let tagsURL = requestURL(
                method: "track.getTopTags",
                apiKey: apiKey,
                artist: artist,
                trackTitle: title
              ) else {
            return .missingMetadata
        }

        let trackInfo = await fetchTrackInfo(from: infoURL)
        let topTags = await fetchTopTags(from: tagsURL)
        let insight = LastFMInsight(
            listeners: trackInfo.value?.listeners,
            playcount: trackInfo.value?.playcount,
            topTags: topTags.value
        )

        if insight.hasContent {
            return .insight(insight)
        }

        if trackInfo.didFail || topTags.didFail {
            return .requestFailed
        }

        return .noMatch
    }

    private func requestURL(method: String, apiKey: String, artist: String, trackTitle: String) -> URL? {
        var components = URLComponents(string: "https://ws.audioscrobbler.com/2.0/")
        components?.queryItems = [
            URLQueryItem(name: "method", value: method),
            URLQueryItem(name: "artist", value: artist),
            URLQueryItem(name: "track", value: trackTitle),
            URLQueryItem(name: "autocorrect", value: "1"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json")
        ]
        return components?.url
    }

    private func fetchTrackInfo(from url: URL) async -> (value: TrackInfoResponse?, didFail: Bool) {
        guard let data = try? await validatedData(from: url) else {
            return (nil, true)
        }

        let response = try? JSONDecoder().decode(TrackInfoEnvelope.self, from: data)
        return (response?.track, false)
    }

    private func fetchTopTags(from url: URL) async -> (value: [String], didFail: Bool) {
        guard let data = try? await validatedData(from: url),
              let response = try? JSONDecoder().decode(TopTagsEnvelope.self, from: data) else {
            return ([], true)
        }

        return (
            response.topTags.tag.compactMap {
            $0.name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            },
            false
        )
    }

    private func validatedData(from url: URL) async throws -> Data {
        let (data, response) = try await dataLoader(url)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}

private struct TrackInfoEnvelope: Decodable {
    let track: TrackInfoResponse?
}

private struct TrackInfoResponse: Decodable {
    let listeners: Int?
    let playcount: Int?

    private enum CodingKeys: String, CodingKey {
        case listeners
        case playcount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        listeners = Int(try container.decodeIfPresent(String.self, forKey: .listeners) ?? "")
        playcount = Int(try container.decodeIfPresent(String.self, forKey: .playcount) ?? "")
    }
}

private struct TopTagsEnvelope: Decodable {
    let topTags: TopTagsPayload

    private enum CodingKeys: String, CodingKey {
        case topTags = "toptags"
    }
}

private struct TopTagsPayload: Decodable {
    let tag: [TopTag]
}

private struct TopTag: Decodable {
    let name: String?
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
