// Summary: Future Supabase client façade — not connected in the local MVP.

import Foundation

/// Placeholder configuration. Never place service-role keys here.
struct SupabaseConfig: Sendable {
    var projectURL: URL?
    var anonKey: String?

    static let missing = SupabaseConfig(projectURL: nil, anonKey: nil)

    var isConfigured: Bool {
        projectURL != nil && !(anonKey ?? "").isEmpty
    }
}

protocol CloudSyncing: Sendable {
    func pushPendingChanges() async throws
    func pullRemoteChanges() async throws
}

/// No-op sync until a real Supabase project is wired.
struct NoOpCloudSync: CloudSyncing {
    func pushPendingChanges() async throws {}
    func pullRemoteChanges() async throws {}
}

enum SyncConflictPolicy {
    /// Latest valid user edit wins for scalar fields.
    /// Tags/feelings merge by id; decision events are append-only.
    static let description = """
    MVP conflict policy:
    - Scalar fields: latest updatedAt wins
    - Tags & feelings: union by identifier
    - Decision events: append-only
    - Deletion requires explicit user intent
    - Never overwrite a newer local reflection with stale cloud data
    """
}
