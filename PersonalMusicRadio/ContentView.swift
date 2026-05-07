import SwiftUI

private struct ProgramVisualStyle {
    let accent: Color
    let headerBackground: Color
    let panelBackground: Color
    let panelBorder: Color
    let mutedPanelBackground: Color
    let badgeBackground: Color
    let badgeBorder: Color
    let tagLine: String
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    private let sceneResolver = SceneResolver()
    private let sceneTrackSelector = SceneTrackSelector()
    private let radioCopywriter = RadioCopywriter()
    private let folderAccessService = FolderAccessService()
    private let musicScanner = MusicScanner()
    private let audioMetadataReader = AudioMetadataReader()
    @StateObject private var audioPlayerService = AudioPlayerService()
    @State private var selectedMusicFolder: URL?
    @State private var importedTrackCount = 0
    @State private var ignoredFormatCounts: [String: Int] = [:]
    @State private var currentProgram = SceneResolver().program(for: SceneResolver().resolve())
    @State private var scheduledSceneRefresh: Timer?
    @State private var nextSceneChangeDate: Date?
    @State private var lastAutomaticSceneChangeAt: Date?
    @State private var lastAutomaticProgramName: String?
    @State private var displayClock = Date()
    @State private var displayTimer: Timer?

    var body: some View {
        ZStack {
            visualStyle.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Divider()

                HStack(alignment: .top, spacing: 24) {
                    stationPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    sideRail
                        .frame(width: 280)
                }
                .padding(24)
            }
        }
        .onAppear {
            displayClock = Date()
            refreshProgram()
            restoreMusicFolder()
            scheduleNextSceneRefresh()
            startDisplayTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                stopScheduledSceneRefresh()
                stopDisplayTimer()
                return
            }

            displayClock = Date()
            refreshCurrentSceneQueue()
            startDisplayTimer()
        }
        .onDisappear {
            stopScheduledSceneRefresh()
            stopDisplayTimer()
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Personal Music Radio")
                    .font(.system(size: 22, weight: .semibold))

                Text("A local AI station tuned to your day")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusPill(title: hostState.rawValue, systemImage: "waveform")
            statusPill(title: currentProgram.name, systemImage: "dot.radiowaves.left.and.right")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(visualStyle.headerBackground.opacity(0.96))
    }

    private var stationPanel: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text(currentProgram.name)
                    .font(.system(size: 34, weight: .semibold))

                Text(currentProgram.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(visualStyle.tagLine)
                    .font(.caption)
                    .foregroundStyle(visualStyle.accent)

                scheduleStrip
            }

            HStack(alignment: .center, spacing: 22) {
                hostVisual

                VStack(alignment: .leading, spacing: 12) {
                    Text("Now on air")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(currentTrackTitle)
                            .font(.system(size: 28, weight: .medium))

                        Text(currentTrackDetails)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Text(recommendationReasonText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let upNextTitle {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Up next")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Text(upNextTitle)
                                .font(.headline)

                            Text(upNextDetails)
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            Text(upNextCueText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 6)
                    }

                    matchResultSection
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("DJ intro", systemImage: "text.quote")
                    .font(.headline)

                Text(djIntroText)
                    .font(.system(size: 18))
                    .lineSpacing(5)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Label(introStatusText, systemImage: introStatusSymbol)
                    Text("Audio stays local on your Mac.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(visualStyle.mutedPanelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            playbackSection

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(visualStyle.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(visualStyle.panelBorder, lineWidth: 1)
        )
    }

    private var hostVisual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(visualStyle.mutedPanelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(visualStyle.panelBorder, lineWidth: 1)
                )

            VStack(spacing: 12) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundStyle(visualStyle.accent)

                Text(hostState.rawValue)
                    .font(.headline)

                Text("Host state")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 210, height: 210)
    }

    private var playbackSection: some View {
        VStack(spacing: 16) {
            ProgressView(value: audioPlayerService.progress)

            HStack(spacing: 12) {
                Button {
                    audioPlayerService.togglePlayback()
                } label: {
                    Label(playbackButtonTitle, systemImage: playbackButtonSymbol)
                }
                .buttonStyle(.borderedProminent)
                .disabled(audioPlayerService.currentTrack == nil)

                Button {
                    audioPlayerService.nextTrack()
                } label: {
                    Label("Next", systemImage: "forward.fill")
                }
                .disabled(audioPlayerService.currentTrack == nil)

                Spacer()

                Button {
                } label: {
                    Label("Like", systemImage: "heart")
                }
                .disabled(true)

                Button {
                } label: {
                    Label("Not for now", systemImage: "moon")
                }
                .disabled(true)

                Button {
                    audioPlayerService.nextTrack()
                } label: {
                    Label("Skip", systemImage: "arrow.right")
                }
                .disabled(audioPlayerService.currentTrack == nil)
            }
            .buttonStyle(.bordered)
        }
    }

    private var sideRail: some View {
        VStack(alignment: .leading, spacing: 16) {
            sideSection(
                title: "Source",
                systemImage: "music.note.list",
                rows: [
                    FolderAccessService.displayName(for: selectedMusicFolder),
                    importedTrackCountText,
                    ignoredFormatsText,
                    "No private account data"
                ],
                actionTitle: "Choose Folder",
                action: chooseFolder
            )

            sideSection(
                title: "Tuning",
                systemImage: "slider.horizontal.3",
                rows: [
                    "Current program: \(currentProgram.name)",
                    nextSceneChangeRowText,
                    lastAutomaticSwitchRowText
                ],
                actionTitle: "Refresh Queue",
                action: refreshCurrentSceneQueue
            )

            sideSection(
                title: "Privacy",
                systemImage: "lock",
                rows: [
                    "No audio upload",
                    "No local path upload",
                    "No external metadata lookup"
                ],
                actionTitle: "Review",
                action: {}
            )

            Spacer()
        }
    }

    private func sideSection(
        title: String,
        systemImage: String,
        rows: [String],
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            VStack(alignment: .leading, spacing: 7) {
                ForEach(rows, id: \.self) { row in
                    Text(row)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: action) {
                Label(actionTitle, systemImage: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private func statusPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(visualStyle.badgeBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(visualStyle.badgeBorder, lineWidth: 1)
            )
    }

    private func chooseFolder() {
        guard let folder = folderAccessService.chooseMusicFolder() else {
            return
        }

        selectedMusicFolder = folder
        loadMusicFolder(folder)
    }

    private func restoreMusicFolder() {
        guard let folder = folderAccessService.restoredMusicFolder() else {
            return
        }

        selectedMusicFolder = folder
        loadMusicFolder(folder)
    }

    private func loadMusicFolder(_ folder: URL) {
        refreshProgram()
        let report = musicScanner.scanReport(in: folder)
        let tracks = report.audioFiles.map(audioMetadataReader.track(for:))
        importedTrackCount = report.audioFiles.count
        ignoredFormatCounts = report.ignoredExtensions
        audioPlayerService.loadTracks(
            from: sceneTrackSelector.orderedTracks(from: tracks, for: currentProgram.scene)
        )
        scheduleNextSceneRefresh()
    }

    private func refreshCurrentSceneQueue() {
        refreshProgram()
        scheduleNextSceneRefresh()

        guard let selectedMusicFolder else {
            return
        }

        let report = musicScanner.scanReport(in: selectedMusicFolder)
        let tracks = report.audioFiles.map(audioMetadataReader.track(for:))
        importedTrackCount = report.audioFiles.count
        ignoredFormatCounts = report.ignoredExtensions
        audioPlayerService.reprioritizeUpcomingTracks(
            from: sceneTrackSelector.orderedTracks(from: tracks, for: currentProgram.scene)
        )
    }

    private func refreshProgram() {
        let scene = sceneResolver.resolve()
        currentProgram = sceneResolver.program(for: scene)
    }

    private func scheduleNextSceneRefresh(now: Date = Date()) {
        stopScheduledSceneRefresh()

        let nextChange = sceneResolver.nextSceneChange(after: now)
        nextSceneChangeDate = nextChange
        let timer = Timer(fire: nextChange, interval: 0, repeats: false) { _ in
            Task { @MainActor in
                refreshCurrentSceneQueue()
                lastAutomaticSceneChangeAt = nextChange
                lastAutomaticProgramName = currentProgram.name
            }
        }
        timer.tolerance = 0
        RunLoop.main.add(timer, forMode: .common)
        scheduledSceneRefresh = timer
    }

    private func stopScheduledSceneRefresh() {
        scheduledSceneRefresh?.invalidate()
        scheduledSceneRefresh = nil
        nextSceneChangeDate = nil
    }

    private func startDisplayTimer() {
        stopDisplayTimer()

        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                displayClock = Date()
            }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        displayTimer = timer
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private var visualStyle: ProgramVisualStyle {
        switch currentProgram.scene {
        case .morning:
            return ProgramVisualStyle(
                accent: Color(red: 0.94, green: 0.55, blue: 0.28),
                headerBackground: Color(red: 0.99, green: 0.96, blue: 0.91),
                panelBackground: Color.white.opacity(0.9),
                panelBorder: Color(red: 0.91, green: 0.79, blue: 0.66),
                mutedPanelBackground: Color(red: 0.99, green: 0.94, blue: 0.87),
                badgeBackground: Color(red: 1.0, green: 0.95, blue: 0.88),
                badgeBorder: Color(red: 0.91, green: 0.79, blue: 0.66),
                tagLine: "Warm light for the morning set"
            )
        case .work:
            return ProgramVisualStyle(
                accent: Color(red: 0.19, green: 0.48, blue: 0.79),
                headerBackground: Color(red: 0.92, green: 0.96, blue: 0.99),
                panelBackground: Color.white.opacity(0.92),
                panelBorder: Color(red: 0.72, green: 0.82, blue: 0.92),
                mutedPanelBackground: Color(red: 0.93, green: 0.96, blue: 0.99),
                badgeBackground: Color(red: 0.92, green: 0.96, blue: 0.99),
                badgeBorder: Color(red: 0.72, green: 0.82, blue: 0.92),
                tagLine: "Focused cues for a steadier work block"
            )
        case .lunch:
            return ProgramVisualStyle(
                accent: Color(red: 0.67, green: 0.45, blue: 0.23),
                headerBackground: Color(red: 0.98, green: 0.95, blue: 0.9),
                panelBackground: Color.white.opacity(0.91),
                panelBorder: Color(red: 0.87, green: 0.78, blue: 0.67),
                mutedPanelBackground: Color(red: 0.97, green: 0.93, blue: 0.87),
                badgeBackground: Color(red: 0.98, green: 0.94, blue: 0.88),
                badgeBorder: Color(red: 0.87, green: 0.78, blue: 0.67),
                tagLine: "A softer lunch-table palette"
            )
        case .nap:
            return ProgramVisualStyle(
                accent: Color(red: 0.43, green: 0.47, blue: 0.72),
                headerBackground: Color(red: 0.92, green: 0.93, blue: 0.98),
                panelBackground: Color.white.opacity(0.9),
                panelBorder: Color(red: 0.74, green: 0.77, blue: 0.9),
                mutedPanelBackground: Color(red: 0.91, green: 0.93, blue: 0.98),
                badgeBackground: Color(red: 0.92, green: 0.94, blue: 0.99),
                badgeBorder: Color(red: 0.74, green: 0.77, blue: 0.9),
                tagLine: "Quiet color for a short reset"
            )
        case .happy:
            return ProgramVisualStyle(
                accent: Color(red: 0.2, green: 0.63, blue: 0.5),
                headerBackground: Color(red: 0.9, green: 0.98, blue: 0.95),
                panelBackground: Color.white.opacity(0.92),
                panelBorder: Color(red: 0.69, green: 0.88, blue: 0.81),
                mutedPanelBackground: Color(red: 0.89, green: 0.97, blue: 0.94),
                badgeBackground: Color(red: 0.9, green: 0.98, blue: 0.95),
                badgeBorder: Color(red: 0.69, green: 0.88, blue: 0.81),
                tagLine: "Brighter color for the afternoon lift"
            )
        }
    }

    private var importedTrackCountText: String {
        importedTrackCount == 1 ? "1 track imported" : "\(importedTrackCount) tracks imported"
    }

    private var ignoredFormatsText: String {
        guard !ignoredFormatCounts.isEmpty else {
            return "Ignored formats: none"
        }

        let summary = ignoredFormatCounts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(3)
            .map { "\($0.key)(\($0.value))" }
            .joined(separator: ", ")

        return "Ignored formats: \(summary)"
    }

    private var scheduleStrip: some View {
        HStack(spacing: 10) {
            Label("On now", systemImage: "clock")
            Text(scheduleStatusText)
            Spacer(minLength: 0)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var scheduleStatusText: String {
        guard let nextSceneChangeDate, let nextProgramName else {
            return "Schedule updates while the station is open."
        }

        return "until \(formattedTime(nextSceneChangeDate)) | then \(nextProgramName) | \(relativeSwitchText)"
    }

    private var nextSceneChangeRowText: String {
        guard let nextSceneChangeDate, let nextProgramName else {
            return "Next switch pending"
        }

        return "Next switch: \(formattedTime(nextSceneChangeDate)) to \(nextProgramName) (\(relativeSwitchText))"
    }

    private var lastAutomaticSwitchRowText: String {
        guard let lastAutomaticSceneChangeAt, let lastAutomaticProgramName else {
            return "No automatic switch yet"
        }

        return "Last auto switch: \(formattedTime(lastAutomaticSceneChangeAt)) to \(lastAutomaticProgramName)"
    }

    private var nextProgramName: String? {
        guard let nextSceneChangeDate else {
            return nil
        }

        let nextScene = sceneResolver.resolve(now: nextSceneChangeDate)
        return sceneResolver.program(for: nextScene).name
    }

    private func formattedTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private var relativeSwitchText: String {
        guard let nextSceneChangeDate else {
            return "countdown unavailable"
        }

        let remaining = max(0, Int(nextSceneChangeDate.timeIntervalSince(displayClock)))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60

        if hours > 0 {
            return "in \(hours)h \(minutes)m \(seconds)s"
        }

        if minutes > 0 {
            return "in \(minutes)m \(seconds)s"
        }

        return "in \(seconds)s"
    }

    private var hostState: HostState {
        switch audioPlayerService.playbackState {
        case .idle, .ready:
            return .quiet
        case .playing:
            return .playing
        case .paused:
            return .paused
        case .failed:
            return .tuning
        }
    }

    private var currentTrackTitle: String {
        audioPlayerService.currentTrack?.title ?? "Choose a folder to tune in"
    }

    private var currentTrackDetails: String {
        audioPlayerService.currentTrack?.detailsText ?? "No local track loaded"
    }

    private var recommendationReasonText: String {
        radioCopywriter.recommendationReason(
            program: currentProgram,
            currentTrack: audioPlayerService.currentTrack,
            upNextTrack: audioPlayerService.upNextTrack
        )
    }

    private var matchResultSection: some View {
        let result = sceneTrackSelector.matchResult(
            currentTrack: audioPlayerService.currentTrack,
            upNextTrack: audioPlayerService.upNextTrack,
            scene: currentProgram.scene
        )

        return VStack(alignment: .leading, spacing: 10) {
            Label("Match Result", systemImage: "sparkles")
                .font(.headline)

            Text(result.currentTrackLine)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(result.upNextTrackLine)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let fallbackLine = result.fallbackLine {
                Text(fallbackLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 10)
    }


    private var djIntroText: String {
        radioCopywriter.djIntro(
            program: currentProgram,
            currentTrack: audioPlayerService.currentTrack,
            upNextTrack: audioPlayerService.upNextTrack
        )
    }

    private var introStatusText: String {
        audioPlayerService.playbackState == .failed ? "Format needs a different player path" : "Local playback only"
    }

    private var introStatusSymbol: String {
        audioPlayerService.playbackState == .failed ? "exclamationmark.triangle" : "checkmark.circle"
    }

    private var playbackButtonTitle: String {
        audioPlayerService.playbackState == .playing ? "Pause" : "Play"
    }

    private var playbackButtonSymbol: String {
        audioPlayerService.playbackState == .playing ? "pause.fill" : "play.fill"
    }

    private var upNextTitle: String? {
        audioPlayerService.upNextTrack?.title
    }

    private var upNextDetails: String {
        audioPlayerService.upNextTrack?.detailsText ?? ""
    }

    private var upNextCueText: String {
        radioCopywriter.upNextCue(
            program: currentProgram,
            upNextTrack: audioPlayerService.upNextTrack
        )
    }
}
