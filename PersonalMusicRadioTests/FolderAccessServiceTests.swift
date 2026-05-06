import XCTest
@testable import PersonalMusicRadio

final class FolderAccessServiceTests: XCTestCase {
    @MainActor
    func testRestoredFolderReturnsNilWithoutSavedBookmark() {
        let service = FolderAccessService(
            loadBookmarkData: { nil },
            saveBookmarkData: { _ in
                XCTFail("Unexpected bookmark save")
            }
        )

        XCTAssertNil(service.restoredMusicFolder())
    }

    @MainActor
    func testRestoredFolderReturnsNilForInvalidBookmarkData() {
        let service = FolderAccessService(
            loadBookmarkData: { Data("invalid".utf8) },
            saveBookmarkData: { _ in
                XCTFail("Unexpected bookmark save")
            }
        )

        XCTAssertNil(service.restoredMusicFolder())
    }

    func testDisplayNameUsesFolderName() {
        let url = URL(fileURLWithPath: "/Users/zhang/Music/QQMusic")

        XCTAssertEqual(FolderAccessService.displayName(for: url), "QQMusic")
    }

    func testDisplayNameFallsBackWhenNoFolderSelected() {
        XCTAssertEqual(FolderAccessService.displayName(for: nil), "QQ Music folder not selected")
    }
}
