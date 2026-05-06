import Foundation

struct MusicScanner {
    struct ScanReport: Equatable {
        let audioFiles: [URL]
        let ignoredExtensions: [String: Int]
    }

    private let fileManager: FileManager
    private let audioExtensions: Set<String>

    init(
        fileManager: FileManager = .default,
        audioExtensions: Set<String> = ["aac", "aiff", "flac", "m4a", "mp3", "wav"]
    ) {
        self.fileManager = fileManager
        self.audioExtensions = audioExtensions
    }

    func countAudioFiles(in folder: URL) -> Int {
        scanReport(in: folder).audioFiles.count
    }

    func audioFiles(in folder: URL) -> [URL] {
        scanReport(in: folder).audioFiles
    }

    func scanReport(in folder: URL) -> ScanReport {
        let didStartAccessing = folder.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                folder.stopAccessingSecurityScopedResource()
            }
        }

        guard let enumerator = fileManager.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else {
            return ScanReport(audioFiles: [], ignoredExtensions: [:])
        }

        var files: [URL] = []
        var ignoredExtensions: [String: Int] = [:]

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  values.isRegularFile == true else {
                continue
            }

            let fileExtension = fileURL.pathExtension.lowercased()

            guard audioExtensions.contains(fileExtension) else {
                let normalizedExtension = fileExtension.isEmpty ? "(no extension)" : fileExtension
                ignoredExtensions[normalizedExtension, default: 0] += 1
                continue
            }

            files.append(fileURL)
        }

        let sortedAudioFiles = files.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }

        return ScanReport(audioFiles: sortedAudioFiles, ignoredExtensions: ignoredExtensions)
    }
}
