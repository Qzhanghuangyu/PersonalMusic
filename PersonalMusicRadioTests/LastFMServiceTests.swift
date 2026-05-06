import Foundation
import XCTest
@testable import PersonalMusicRadio

final class LastFMServiceTests: XCTestCase {
    func testFetchInsightParsesTrackMetricsAndTopTags() async {
        let service = LastFMService(
            apiKeyProvider: { "test-key" },
            dataLoader: { url in
                let query = url.query ?? ""
                let json: String

                if query.contains("method=track.getInfo") {
                    json = """
                    {"track":{"listeners":"69572","playcount":"281445"}}
                    """
                } else {
                    json = """
                    {"toptags":{"tag":[{"name":"pop"},{"name":"dance"},{"name":"electropop"}]}}
                    """
                }

                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (Data(json.utf8), response)
            }
        )

        let result = await service.fetchInsight(
            for: Track(
                url: URL(fileURLWithPath: "/tmp/Believe.mp3"),
                title: "Believe",
                artist: "Cher"
            )
        )

        XCTAssertEqual(
            result,
            .insight(
                LastFMInsight(
                    listeners: 69_572,
                    playcount: 281_445,
                    topTags: ["pop", "dance", "electropop"]
                )
            )
        )
    }

    func testFetchInsightReturnsNotConfiguredWithoutKey() async {
        let probe = DataLoaderProbe()
        let service = LastFMService(
            apiKeyProvider: { nil },
            dataLoader: { url in
                probe.markCalled()
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (Data(), response)
            }
        )

        let result = await service.fetchInsight(
            for: Track(
                url: URL(fileURLWithPath: "/tmp/Believe.mp3"),
                title: "Believe",
                artist: "Cher"
            )
        )

        XCTAssertEqual(result, .notConfigured)
        XCTAssertFalse(probe.didLoadData)
    }

    func testFetchInsightReturnsMissingMetadataWithoutArtist() async {
        let service = LastFMService(
            apiKeyProvider: { "test-key" },
            dataLoader: { _ in
                XCTFail("Data loader should not be called without usable metadata.")
                throw URLError(.badURL)
            }
        )

        let result = await service.fetchInsight(
            for: Track(
                url: URL(fileURLWithPath: "/tmp/Unknown.mp3"),
                title: "Unknown",
                artist: nil
            )
        )

        XCTAssertEqual(result, .missingMetadata)
    }

    func testFetchInsightReturnsNoMatchWhenResponsesContainNoUsableData() async {
        let service = LastFMService(
            apiKeyProvider: { "test-key" },
            dataLoader: { url in
                let query = url.query ?? ""
                let json: String

                if query.contains("method=track.getInfo") {
                    json = #"{"track":{}}"#
                } else {
                    json = #"{"toptags":{"tag":[]}}"#
                }

                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (Data(json.utf8), response)
            }
        )

        let result = await service.fetchInsight(
            for: Track(
                url: URL(fileURLWithPath: "/tmp/DeepCut.mp3"),
                title: "Deep Cut",
                artist: "Unknown Artist"
            )
        )

        XCTAssertEqual(result, .noMatch)
    }

    func testFetchInsightReturnsRequestFailedWhenLookupFails() async {
        let service = LastFMService(
            apiKeyProvider: { "test-key" },
            dataLoader: { url in
                let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
                return (Data(), response)
            }
        )

        let result = await service.fetchInsight(
            for: Track(
                url: URL(fileURLWithPath: "/tmp/Believe.mp3"),
                title: "Believe",
                artist: "Cher"
            )
        )

        XCTAssertEqual(result, .requestFailed)
    }
}

private final class DataLoaderProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var called = false

    var didLoadData: Bool {
        lock.lock()
        defer { lock.unlock() }
        return called
    }

    func markCalled() {
        lock.lock()
        called = true
        lock.unlock()
    }
}
