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

    private func url(named name: String) -> URL {
        URL(fileURLWithPath: "/tmp/\(name).mp3")
    }
}
