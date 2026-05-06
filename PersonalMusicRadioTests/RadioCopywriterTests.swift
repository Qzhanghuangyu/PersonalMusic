import XCTest
@testable import PersonalMusicRadio

final class RadioCopywriterTests: XCTestCase {
    private let copywriter = RadioCopywriter()

    func testMorningReasonUsesWarmupLanguage() {
        let program = RadioProgram(scene: .morning, name: "Morning Warmup", subtitle: "", tone: "light")

        let reason = copywriter.recommendationReason(
            program: program,
            currentTrack: track(named: "Sunrise Coffee"),
            upNextTrack: track(named: "Soft Start")
        )

        XCTAssertTrue(reason.contains("warmup"))
        XCTAssertTrue(reason.contains("before the heavier work block"))
    }

    func testWorkIntroMentionsCurrentAndUpNextTrack() {
        let program = RadioProgram(scene: .work, name: "Workday Focus", subtitle: "", tone: "calm")
        let current = track(named: "Deep Focus")
        let next = track(named: "Instrumental Flow")

        let intro = copywriter.djIntro(program: program, currentTrack: current, upNextTrack: next)

        XCTAssertTrue(intro.contains("Deep Focus"))
        XCTAssertTrue(intro.contains("Instrumental Flow"))
        XCTAssertTrue(intro.contains("Workday Focus"))
    }

    func testLunchReasonUsesLunchSpecificTone() {
        let program = RadioProgram(scene: .lunch, name: "Lunch Table", subtitle: "", tone: "warm")

        let reason = copywriter.recommendationReason(
            program: program,
            currentTrack: track(named: "Cafe Break"),
            upNextTrack: track(named: "Soft Bossa")
        )

        XCTAssertTrue(reason.contains("lunch-table"))
        XCTAssertTrue(reason.contains("softer"))
    }

    func testHappyUpNextCueMentionsLift() {
        let program = RadioProgram(scene: .happy, name: "Afternoon Lift", subtitle: "", tone: "bright")
        let cue = copywriter.upNextCue(program: program, upNextTrack: track(named: "Sunlight Drive"))

        XCTAssertTrue(cue.contains("Sunlight Drive"))
        XCTAssertTrue(cue.contains("afternoon lift"))
    }

    func testEmptyRecommendationReasonKeepsTuneInMessage() {
        let program = RadioProgram(scene: .nap, name: "Light Nap", subtitle: "", tone: "quiet")

        let reason = copywriter.recommendationReason(program: program, currentTrack: nil, upNextTrack: nil)

        XCTAssertTrue(reason.contains("Pick a local music folder first"))
    }

    func testWorkProgrammingFlowConnectsTrackMatchingCopyAndPrivacyMessaging() {
        let program = RadioProgram(scene: .work, name: "Workday Focus", subtitle: "", tone: "calm")
        let selector = SceneTrackSelector()
        let neutral = track(named: "Night Bus")
        let current = track(named: "Deep Focus Coding Session")
        let next = track(named: "Instrumental Flow")

        let ordered = selector.orderedTracks(from: [neutral, next, current], for: .work)

        XCTAssertEqual(ordered.first?.title, current.title)
        XCTAssertEqual(ordered.dropFirst().first?.title, next.title)

        let intro = copywriter.djIntro(program: program, currentTrack: ordered.first, upNextTrack: ordered.dropFirst().first)
        let reason = copywriter.recommendationReason(
            program: program,
            currentTrack: ordered.first,
            upNextTrack: ordered.dropFirst().first
        )

        XCTAssertTrue(intro.contains("Deep Focus Coding Session"))
        XCTAssertTrue(intro.contains("Instrumental Flow"))
        XCTAssertTrue(intro.contains("Workday Focus"))
        XCTAssertTrue(reason.contains("authorized folder"))
        XCTAssertTrue(reason.contains("without touching account-level data"))
    }

    func testLastFMInsightLinesIncludeMetricsAndTags() {
        let lines = copywriter.lastFMInsightLines(
            track: track(named: "Believe", artist: "Cher"),
            insight: LastFMInsight(
                listeners: 69_572,
                playcount: 281_445,
                topTags: ["pop", "dance", "electropop"]
            )
        )

        XCTAssertEqual(lines.count, 10)
        XCTAssertTrue(lines.contains { $0.contains("69,572") })
        XCTAssertTrue(lines.contains { $0.contains("281,445") })
        XCTAssertTrue(lines.contains { $0.contains("pop") })
    }

    private func track(named name: String, artist: String? = nil) -> Track {
        Track(url: URL(fileURLWithPath: "/tmp/\(name).mp3"), title: name, artist: artist)
    }
}
