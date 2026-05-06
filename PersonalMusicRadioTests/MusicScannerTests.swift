import XCTest
@testable import PersonalMusicRadio

final class MusicScannerTests: XCTestCase {
    private let fileManager = FileManager.default

    func testCountAudioFilesIncludesSupportedExtensionsRecursively() throws {
        let folder = try makeTemporaryFolder()
        defer {
            try? fileManager.removeItem(at: folder)
        }

        let nestedFolder = folder.appendingPathComponent("Nested", isDirectory: true)
        try fileManager.createDirectory(at: nestedFolder, withIntermediateDirectories: true)

        try makeFile(named: "focus.mp3", in: folder)
        try makeFile(named: "lunch.M4A", in: nestedFolder)
        try makeFile(named: "nap.flac", in: nestedFolder)

        XCTAssertEqual(MusicScanner().countAudioFiles(in: folder), 3)
    }

    func testCountAudioFilesIgnoresUnsupportedFiles() throws {
        let folder = try makeTemporaryFolder()
        defer {
            try? fileManager.removeItem(at: folder)
        }

        try makeFile(named: "notes.txt", in: folder)
        try makeFile(named: "cover.jpg", in: folder)
        try makeFile(named: "lyrics.lrc", in: folder)

        XCTAssertEqual(MusicScanner().countAudioFiles(in: folder), 0)
    }

    func testCountAudioFilesIgnoresDirectoriesWithAudioExtension() throws {
        let folder = try makeTemporaryFolder()
        defer {
            try? fileManager.removeItem(at: folder)
        }

        let fakeAudioFolder = folder.appendingPathComponent("album.mp3", isDirectory: true)
        try fileManager.createDirectory(at: fakeAudioFolder, withIntermediateDirectories: true)

        XCTAssertEqual(MusicScanner().countAudioFiles(in: folder), 0)
    }

    func testAudioFilesReturnsSortedPlayableFiles() throws {
        let folder = try makeTemporaryFolder()
        defer {
            try? fileManager.removeItem(at: folder)
        }

        try makeFile(named: "zeta.wav", in: folder)
        try makeFile(named: "Alpha.mp3", in: folder)
        try makeFile(named: "notes.txt", in: folder)

        let files = MusicScanner().audioFiles(in: folder).map(\.lastPathComponent)

        XCTAssertEqual(files, ["Alpha.mp3", "zeta.wav"])
    }

    func testScanReportIncludesIgnoredExtensionsSummary() throws {
        let folder = try makeTemporaryFolder()
        defer {
            try? fileManager.removeItem(at: folder)
        }

        try makeFile(named: "playable.mp3", in: folder)
        try makeFile(named: "cache.qmcflac", in: folder)
        try makeFile(named: "clip.qmcflac", in: folder)
        try makeFile(named: "cover.jpg", in: folder)

        let report = MusicScanner().scanReport(in: folder)

        XCTAssertEqual(report.audioFiles.map(\.lastPathComponent), ["playable.mp3"])
        XCTAssertEqual(report.ignoredExtensions["qmcflac"], 2)
        XCTAssertEqual(report.ignoredExtensions["jpg"], 1)
    }

    private func makeTemporaryFolder() throws -> URL {
        let folder = fileManager.temporaryDirectory
            .appendingPathComponent("MusicScannerTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        return folder
    }

    private func makeFile(named name: String, in folder: URL) throws {
        let url = folder.appendingPathComponent(name, isDirectory: false)
        try Data().write(to: url)
    }
}
