import XCTest
@testable import PersonalMusicRadio

final class LastFMKeyStoreTests: XCTestCase {
    func testSaveKeyTrimsWhitespaceBeforePersisting() {
        let recorder = SaveRecorder()
        let keyStore = LastFMKeyStore(
            readValue: { nil },
            saveValue: { key in
                recorder.savedKey = key
                return true
            },
            clearValue: { true }
        )

        XCTAssertTrue(keyStore.saveKey("  abc123  "))
        XCTAssertEqual(recorder.savedKey, "abc123")
    }

    func testSaveKeyRejectsEmptyValues() {
        let keyStore = LastFMKeyStore(
            readValue: { nil },
            saveValue: { _ in
                XCTFail("saveValue should not be called for an empty key")
                return true
            },
            clearValue: { true }
        )

        XCTAssertFalse(keyStore.saveKey("   "))
    }

    func testIsConfiguredReflectsStoredKey() {
        let keyStore = LastFMKeyStore(
            readValue: { "stored-key" },
            saveValue: { _ in true },
            clearValue: { true }
        )

        XCTAssertTrue(keyStore.isConfigured)
        XCTAssertEqual(keyStore.readKey(), "stored-key")
    }

    func testClearKeyUsesInjectedClearAction() {
        let recorder = ClearRecorder()
        let keyStore = LastFMKeyStore(
            readValue: { nil },
            saveValue: { _ in true },
            clearValue: {
                recorder.didClear = true
                return true
            }
        )

        XCTAssertTrue(keyStore.clearKey())
        XCTAssertTrue(recorder.didClear)
    }
}

private final class SaveRecorder: @unchecked Sendable {
    var savedKey: String?
}

private final class ClearRecorder: @unchecked Sendable {
    var didClear = false
}
