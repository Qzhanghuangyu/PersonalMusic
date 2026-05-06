import AppKit
import Foundation

@MainActor
final class FolderAccessService {
    private let loadBookmarkData: () -> Data?
    private let saveBookmarkData: (Data) -> Void

    init(
        defaults: UserDefaults = .standard,
        bookmarkKey: String = "selectedMusicFolderBookmark"
    ) {
        self.loadBookmarkData = {
            defaults.data(forKey: bookmarkKey)
        }

        self.saveBookmarkData = { data in
            defaults.set(data, forKey: bookmarkKey)
        }
    }

    init(
        loadBookmarkData: @escaping () -> Data?,
        saveBookmarkData: @escaping (Data) -> Void
    ) {
        self.loadBookmarkData = loadBookmarkData
        self.saveBookmarkData = saveBookmarkData
    }

    func chooseMusicFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose QQ Music Download Folder"
        panel.message = "Personal Music Radio will only use the folder you choose. It will not scan your home directory."
        panel.prompt = "Choose Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        guard panel.runModal() == .OK else {
            return nil
        }

        guard let url = panel.url else {
            return nil
        }

        saveBookmark(for: url)
        return url
    }

    func restoredMusicFolder() -> URL? {
        guard let data = loadBookmarkData() else {
            return nil
        }

        guard let bookmark = resolvedBookmark(from: data) else {
            return nil
        }

        if bookmark.isStale {
            saveBookmark(for: bookmark.url)
        }

        return bookmark.url
    }

    nonisolated static func displayName(for url: URL?) -> String {
        guard let url else {
            return "QQ Music folder not selected"
        }

        let name = url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? url.path : name
    }

    private func saveBookmark(for url: URL) {
        let data = bookmarkData(for: url, options: [.withSecurityScope])
            ?? bookmarkData(for: url, options: [])

        if let data {
            saveBookmarkData(data)
        }
    }

    private func bookmarkData(for url: URL, options: URL.BookmarkCreationOptions) -> Data? {
        try? url.bookmarkData(
            options: options,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    private func resolvedBookmark(from data: Data) -> (url: URL, isStale: Bool)? {
        resolvedBookmark(from: data, options: [.withSecurityScope])
            ?? resolvedBookmark(from: data, options: [])
    }

    private func resolvedBookmark(
        from data: Data,
        options: URL.BookmarkResolutionOptions
    ) -> (url: URL, isStale: Bool)? {
        var isStale = false

        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: options,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        return (url, isStale)
    }
}
