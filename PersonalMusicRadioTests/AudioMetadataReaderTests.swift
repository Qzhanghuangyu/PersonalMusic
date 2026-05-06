import XCTest
@testable import PersonalMusicRadio

final class AudioMetadataReaderTests: XCTestCase {
    func testTrackUsesEmbeddedMetadataWhenAvailable() {
        let reader = AudioMetadataReader { _ in
            AudioMetadataSnapshot(title: "Believer", artist: "Imagine Dragons")
        }

        let track = reader.track(for: URL(fileURLWithPath: "/tmp/01 - Unknown.mp3"))

        XCTAssertEqual(track.title, "Believer")
        XCTAssertEqual(track.artist, "Imagine Dragons")
        XCTAssertEqual(track.detailsText, "Imagine Dragons · Local file · MP3")
    }

    func testTrackFallsBackToFilenameWhenMetadataIsMissing() {
        let reader = AudioMetadataReader { _ in
            AudioMetadataSnapshot(title: nil, artist: "   ")
        }

        let track = reader.track(for: URL(fileURLWithPath: "/tmp/Night Drive.m4a"))

        XCTAssertEqual(track.title, "Night Drive")
        XCTAssertNil(track.artist)
        XCTAssertEqual(track.detailsText, "Local file · M4A")
    }
}
