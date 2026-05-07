import XCTest
@testable import PersonalMusicRadio

final class SceneTrackSelectorTests: XCTestCase {
    private let selector = SceneTrackSelector()

    func testOrderedTracksPrefersMorningKeywords() {
        let neutral = url(named: "Night Bus")
        let morning = url(named: "Sunrise Coffee Breeze")
        let work = url(named: "Deep Focus Coding Session")

        let ordered = selector.orderedTracks(from: [neutral, work, morning], for: .morning)

        XCTAssertEqual(ordered.first, morning)
    }

    func testOrderedTracksPrefersWorkKeywords() {
        let neutral = url(named: "Morning Walk")
        let work = url(named: "Deep Focus Coding Session")
        let lunch = url(named: "Cafe Bossa Break")

        let ordered = selector.orderedTracks(from: [neutral, lunch, work], for: .work)

        XCTAssertEqual(ordered.first, work)
    }

    func testOrderedTracksPrefersNapKeywords() {
        let happy = url(named: "Happy Dance Floor")
        let nap = url(named: "Quiet Rain Piano")
        let work = url(named: "Focus Notes")

        let ordered = selector.orderedTracks(from: [happy, work, nap], for: .nap)

        XCTAssertEqual(ordered.first, nap)
    }

    func testOrderedTracksKeepsOriginalOrderWithoutKeywordMatches() {
        let first = url(named: "Alpha")
        let second = url(named: "Beta")
        let third = url(named: "Gamma")

        let ordered = selector.orderedTracks(from: [first, second, third], for: .lunch)

        XCTAssertEqual(ordered, [first, second, third])
    }


    func testMatchResultIncludesCurrentAndUpNextReasons() {
        let current = track(named: "Deep Focus Coding Session")
        let upNext = track(named: "Instrumental Flow")

        let result = selector.matchResult(currentTrack: current, upNextTrack: upNext, scene: .work)

        XCTAssertTrue(result.currentTrackLine.contains("focus"))
        XCTAssertTrue(result.currentTrackLine.contains("focus, coding"))
        XCTAssertTrue(result.upNextTrackLine.contains("scored below the current track"))
        XCTAssertNil(result.fallbackLine)
    }

    func testMatchResultFallsBackToOriginalOrderWhenNothingMatches() {
        let current = track(named: "Night Bus")
        let upNext = track(named: "Side Street")

        let result = selector.matchResult(currentTrack: current, upNextTrack: upNext, scene: .lunch)

        XCTAssertTrue(result.currentTrackLine.contains("original order"))
        XCTAssertTrue(result.upNextTrackLine.contains("original order"))
        XCTAssertEqual(
            result.fallbackLine,
            "No scene keywords matched yet, so the queue keeps its original order until the next refresh."
        )
    }

    private func track(named name: String) -> Track {
        Track(url: url(named: name), title: name)
    }

    private func url(named name: String) -> URL {
        URL(fileURLWithPath: "/tmp/\(name).mp3")
    }
}
