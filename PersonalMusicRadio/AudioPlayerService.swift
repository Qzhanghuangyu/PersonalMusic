import AVFoundation
import Foundation

enum PlaybackState: Equatable {
    case idle
    case ready
    case playing
    case paused
    case failed
}

protocol AudioPlayback: AnyObject {
    var currentTime: TimeInterval { get set }
    var duration: TimeInterval { get }
    var isPlaying: Bool { get }
    var onFinish: ((Bool) -> Void)? { get set }

    func prepareToPlay()
    func play() -> Bool
    func pause()
    func stop()
}

final class AVAudioPlayerAdapter: NSObject, AudioPlayback, AVAudioPlayerDelegate {
    private let player: AVAudioPlayer
    var onFinish: ((Bool) -> Void)?

    init(url: URL) throws {
        self.player = try AVAudioPlayer(contentsOf: url)
        super.init()
        player.delegate = self
    }

    var currentTime: TimeInterval {
        get { player.currentTime }
        set { player.currentTime = newValue }
    }

    var duration: TimeInterval {
        player.duration
    }

    var isPlaying: Bool {
        player.isPlaying
    }

    func prepareToPlay() {
        player.prepareToPlay()
    }

    func play() -> Bool {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.stop()
        player.currentTime = 0
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?(flag)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        onFinish?(false)
    }
}

@MainActor
final class AudioPlayerService: ObservableObject {
    typealias PlayerFactory = (URL) throws -> AudioPlayback

    @Published private(set) var currentTrack: Track?
    @Published private(set) var upNextTrack: Track?
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published private(set) var progress: Double = 0

    private let playerFactory: PlayerFactory
    private var tracks: [Track] = []
    private var currentIndex: Int?
    private var player: AudioPlayback?
    private var progressTimer: Timer?

    init(playerFactory: @escaping PlayerFactory = { try AVAudioPlayerAdapter(url: $0) }) {
        self.playerFactory = playerFactory
    }

    func loadTracks(from urls: [URL]) {
        loadTracks(from: urls.map { Track(url: $0) })
    }

    func loadTracks(from tracks: [Track]) {
        stopCurrentPlayer()

        self.tracks = tracks
        currentIndex = tracks.isEmpty ? nil : 0
        syncQueueState()
        progress = 0
        playbackState = currentTrack == nil ? .idle : .ready
    }

    func reprioritizeUpcomingTracks(from urls: [URL]) {
        reprioritizeUpcomingTracks(from: urls.map { Track(url: $0) })
    }

    func reprioritizeUpcomingTracks(from tracks: [Track]) {
        guard let currentTrack else {
            loadTracks(from: tracks)
            return
        }

        let reorderedTracks = tracks.filter { $0.url != currentTrack.url }

        self.tracks = [currentTrack] + reorderedTracks
        currentIndex = 0
        syncQueueState()

        if playbackState == .idle, !self.tracks.isEmpty {
            playbackState = .ready
        }
    }

    func togglePlayback() {
        if playbackState == .playing {
            pause()
        } else {
            play()
        }
    }

    func nextTrack() {
        guard !tracks.isEmpty else {
            return
        }

        advanceToNextTrack(shouldResumePlayback: playbackState == .playing)
    }

    private func play() {
        guard currentTrack != nil else {
            playbackState = .idle
            return
        }

        let maxAttempts = max(tracks.count, 1)

        for attempt in 0..<maxAttempts {
            guard ensurePlayerLoaded(), let player, player.play() else {
                if !moveToRetryCandidate(forAttempt: attempt, maxAttempts: maxAttempts) {
                    playbackState = .failed
                    return
                }

                continue
            }

            playbackState = .playing
            syncProgress()
            startProgressTimer()
            return
        }

        playbackState = .failed
    }

    private func pause() {
        guard let player else {
            return
        }

        player.pause()
        stopProgressTimer()
        syncProgress()
        playbackState = .paused
    }

    private func ensurePlayerLoaded() -> Bool {
        if player != nil {
            return true
        }

        guard let currentTrack else {
            return false
        }

        do {
            let loadedPlayer = try playerFactory(currentTrack.url)
            loadedPlayer.onFinish = { [weak self] successfully in
                if Thread.isMainThread {
                    MainActor.assumeIsolated {
                        self?.handlePlaybackFinished(successfully: successfully)
                    }
                } else {
                    Task { @MainActor in
                        self?.handlePlaybackFinished(successfully: successfully)
                    }
                }
            }
            loadedPlayer.prepareToPlay()
            player = loadedPlayer
            syncProgress()
            return true
        } catch {
            player = nil
            return false
        }
    }

    private func nextIndex(after index: Int) -> Int {
        let next = index + 1
        return next >= tracks.count ? 0 : next
    }

    private func track(after index: Int?) -> Track? {
        guard let index, !tracks.isEmpty else {
            return nil
        }

        return tracks[nextIndex(after: index)]
    }

    private func syncQueueState() {
        currentTrack = currentIndex.map { tracks[$0] }
        upNextTrack = track(after: currentIndex)
    }

    private func syncProgress() {
        guard let player, player.duration > 0 else {
            progress = 0
            return
        }

        progress = min(max(player.currentTime / player.duration, 0), 1)
    }

    private func stopCurrentPlayer() {
        stopProgressTimer()
        player?.onFinish = nil
        player?.stop()
        player = nil
    }

    private func advanceToNextTrack(shouldResumePlayback: Bool) {
        guard !tracks.isEmpty else {
            playbackState = .idle
            currentIndex = nil
            syncQueueState()
            progress = 0
            return
        }

        stopCurrentPlayer()
        currentIndex = nextIndex(after: currentIndex ?? -1)
        syncQueueState()
        progress = 0
        playbackState = .ready

        if shouldResumePlayback {
            play()
        }
    }

    private func moveToRetryCandidate(forAttempt attempt: Int, maxAttempts: Int) -> Bool {
        stopCurrentPlayer()

        guard attempt + 1 < maxAttempts, !tracks.isEmpty else {
            return false
        }

        currentIndex = nextIndex(after: currentIndex ?? -1)
        syncQueueState()
        progress = 0
        playbackState = .ready
        return true
    }

    private func handlePlaybackFinished(successfully: Bool) {
        guard playbackState == .playing else {
            return
        }

        if successfully {
            progress = 1
        }

        advanceToNextTrack(shouldResumePlayback: true)
    }

    private func startProgressTimer() {
        stopProgressTimer()

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
