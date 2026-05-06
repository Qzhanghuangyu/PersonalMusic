import XCTest
@testable import PersonalMusicRadio

@MainActor
final class AudioPlayerServiceTests: XCTestCase {
    func testLoadTracksSelectsFirstTrackAndSetsReadyState() {
        let service = AudioPlayerService(playerFactory: { _ in FakeAudioPlayer() })
        let first = URL(fileURLWithPath: "/tmp/Beta.mp3")
        let second = URL(fileURLWithPath: "/tmp/Alpha.m4a")

        service.loadTracks(from: [first, second])

        XCTAssertEqual(service.currentTrack?.url, first)
        XCTAssertEqual(service.playbackState, .ready)
        XCTAssertEqual(service.progress, 0)
    }

    func testTogglePlaybackTransitionsBetweenPlayingAndPaused() {
        let fakePlayer = FakeAudioPlayer(duration: 120)
        fakePlayer.currentTime = 30

        let service = AudioPlayerService(playerFactory: { _ in fakePlayer })
        service.loadTracks(from: [URL(fileURLWithPath: "/tmp/Focus.mp3")])

        service.togglePlayback()
        XCTAssertEqual(service.playbackState, .playing)
        XCTAssertEqual(fakePlayer.playCallCount, 1)
        XCTAssertEqual(service.progress, 0.25)

        service.togglePlayback()
        XCTAssertEqual(service.playbackState, .paused)
        XCTAssertEqual(fakePlayer.pauseCallCount, 1)
    }

    func testNextTrackWhilePlayingAdvancesAndKeepsPlaybackActive() {
        let firstURL = URL(fileURLWithPath: "/tmp/First.mp3")
        let secondURL = URL(fileURLWithPath: "/tmp/Second.mp3")
        let firstPlayer = FakeAudioPlayer()
        let secondPlayer = FakeAudioPlayer()

        let service = AudioPlayerService(playerFactory: { url in
            if url == firstURL {
                return firstPlayer
            }

            return secondPlayer
        })

        service.loadTracks(from: [firstURL, secondURL])
        service.togglePlayback()
        service.nextTrack()

        XCTAssertEqual(service.currentTrack?.url, secondURL)
        XCTAssertEqual(service.playbackState, .playing)
        XCTAssertEqual(firstPlayer.stopCallCount, 1)
        XCTAssertEqual(secondPlayer.playCallCount, 1)
    }

    func testPlaybackFinishAutoAdvancesToNextTrack() {
        let firstURL = URL(fileURLWithPath: "/tmp/First.mp3")
        let secondURL = URL(fileURLWithPath: "/tmp/Second.mp3")
        let firstPlayer = FakeAudioPlayer(duration: 180)
        let secondPlayer = FakeAudioPlayer(duration: 200)

        let service = AudioPlayerService(playerFactory: { url in
            if url == firstURL {
                return firstPlayer
            }

            return secondPlayer
        })

        service.loadTracks(from: [firstURL, secondURL])
        service.togglePlayback()
        firstPlayer.finishPlayback(successfully: true)

        XCTAssertEqual(service.currentTrack?.url, secondURL)
        XCTAssertEqual(service.upNextTrack?.url, firstURL)
        XCTAssertEqual(service.playbackState, .playing)
        XCTAssertEqual(secondPlayer.playCallCount, 1)
    }

    func testSingleTrackLoopsAfterPlaybackFinishes() {
        let url = URL(fileURLWithPath: "/tmp/Loop.mp3")
        let player = FakeAudioPlayer()
        let service = AudioPlayerService(playerFactory: { _ in player })

        service.loadTracks(from: [url])
        service.togglePlayback()
        player.finishPlayback(successfully: true)

        XCTAssertEqual(service.currentTrack?.url, url)
        XCTAssertEqual(service.upNextTrack?.url, url)
        XCTAssertEqual(service.playbackState, .playing)
        XCTAssertEqual(player.playCallCount, 2)
    }

    func testFailedTrackSkipsToNextPlayableTrack() {
        let firstURL = URL(fileURLWithPath: "/tmp/Bad.flac")
        let secondURL = URL(fileURLWithPath: "/tmp/Good.mp3")
        let playablePlayer = FakeAudioPlayer()

        enum TestError: Error {
            case unsupported
        }

        let service = AudioPlayerService(playerFactory: { url in
            if url == firstURL {
                throw TestError.unsupported
            }

            return playablePlayer
        })

        service.loadTracks(from: [firstURL, secondURL])
        service.togglePlayback()

        XCTAssertEqual(service.currentTrack?.url, secondURL)
        XCTAssertEqual(service.playbackState, .playing)
        XCTAssertEqual(playablePlayer.playCallCount, 1)
    }

    func testReprioritizeUpcomingTracksKeepsCurrentPlaybackAndUpdatesUpNext() {
        let firstURL = URL(fileURLWithPath: "/tmp/Current.mp3")
        let secondURL = URL(fileURLWithPath: "/tmp/Lunch.mp3")
        let thirdURL = URL(fileURLWithPath: "/tmp/Happy.mp3")
        let player = FakeAudioPlayer()

        let service = AudioPlayerService(playerFactory: { _ in player })
        service.loadTracks(from: [firstURL, thirdURL, secondURL])
        service.togglePlayback()

        service.reprioritizeUpcomingTracks(from: [secondURL, firstURL, thirdURL])

        XCTAssertEqual(service.currentTrack?.url, firstURL)
        XCTAssertEqual(service.upNextTrack?.url, secondURL)
        XCTAssertEqual(service.playbackState, .playing)
        XCTAssertEqual(player.stopCallCount, 0)
    }

    func testReprioritizeUpcomingTracksLoadsQueueWhenNoTrackIsActive() {
        let firstURL = URL(fileURLWithPath: "/tmp/Focus.mp3")
        let secondURL = URL(fileURLWithPath: "/tmp/Calm.mp3")
        let service = AudioPlayerService(playerFactory: { _ in FakeAudioPlayer() })

        service.reprioritizeUpcomingTracks(from: [firstURL, secondURL])

        XCTAssertEqual(service.currentTrack?.url, firstURL)
        XCTAssertEqual(service.upNextTrack?.url, secondURL)
        XCTAssertEqual(service.playbackState, .ready)
    }
}

private final class FakeAudioPlayer: AudioPlayback {
    var currentTime: TimeInterval = 0
    var duration: TimeInterval
    var isPlaying = false
    var onFinish: ((Bool) -> Void)?
    var playCallCount = 0
    var pauseCallCount = 0
    var stopCallCount = 0

    init(duration: TimeInterval = 180) {
        self.duration = duration
    }

    func prepareToPlay() {
    }

    func play() -> Bool {
        playCallCount += 1
        isPlaying = true
        return true
    }

    func pause() {
        pauseCallCount += 1
        isPlaying = false
    }

    func stop() {
        stopCallCount += 1
        isPlaying = false
        currentTime = 0
    }

    func finishPlayback(successfully: Bool) {
        isPlaying = false
        currentTime = duration
        onFinish?(successfully)
    }
}
