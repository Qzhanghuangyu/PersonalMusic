import Foundation
import Security

struct LastFMKeyStore: Sendable {
    private let readValue: @Sendable () -> String?
    private let saveValue: @Sendable (String) -> Bool
    private let clearValue: @Sendable () -> Bool

    init(
        readValue: @escaping @Sendable () -> String? = { KeychainLastFMKeyStore.readKey() },
        saveValue: @escaping @Sendable (String) -> Bool = { KeychainLastFMKeyStore.saveKey($0) },
        clearValue: @escaping @Sendable () -> Bool = { KeychainLastFMKeyStore.clearKey() }
    ) {
        self.readValue = readValue
        self.saveValue = saveValue
        self.clearValue = clearValue
    }

    func readKey() -> String? {
        readValue()?.trimmedNonEmpty
    }

    func saveKey(_ key: String) -> Bool {
        guard let trimmedKey = key.trimmedNonEmpty else {
            return false
        }

        return saveValue(trimmedKey)
    }

    func clearKey() -> Bool {
        clearValue()
    }

    var isConfigured: Bool {
        readKey() != nil
    }
}

private enum KeychainLastFMKeyStore {
    private static let service = "dev.local.PersonalMusicRadio"
    private static let account = "LastFMAPIKey"

    static func readKey() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8)?.trimmedNonEmpty else {
            return nil
        }

        return key
    }

    static func saveKey(_ key: String) -> Bool {
        let data = Data(key.utf8)

        SecItemDelete(baseQuery as CFDictionary)

        var query = baseQuery
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func clearKey() -> Bool {
        let status = SecItemDelete(baseQuery as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
