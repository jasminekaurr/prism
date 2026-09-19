// Summary: Keychain helpers, biometric app lock, and crash reporting with sensitive-data redaction.

import Foundation
import LocalAuthentication
import Security

enum KeychainStore {
    static func set(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum BiometricAuth {
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to device passcode when biometrics unavailable.
            return await withCheckedContinuation { cont in
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                    cont.resume(returning: success)
                }
            }
        }
        return await withCheckedContinuation { cont in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                cont.resume(returning: success)
            }
        }
    }
}

protocol CrashReporting: Sendable {
    func record(error: Error, context: String)
}

struct RedactingCrashReporter: CrashReporting {
    func record(error: Error, context: String) {
        #if DEBUG
        print("[crash] \(context): \(String(describing: type(of: error)))")
        #endif
        // Production: forward type-only metadata to a future vendor; never log reflection/price/auth.
    }
}

/// Placeholder auth for local MVP — Sign in with Apple arrives with backend.
struct StubAuthRepository: AuthRepository {
    var isSignedIn: Bool { get async { false } }

    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile {
        throw AuthStubError.notConfigured
    }

    func signOut() async throws {}

    func deleteAccount() async throws {
        throw AuthStubError.notConfigured
    }
}

enum AuthStubError: LocalizedError {
    case notConfigured
    var errorDescription: String? {
        "Sign in with Apple will be available once cloud accounts are enabled."
    }
}
