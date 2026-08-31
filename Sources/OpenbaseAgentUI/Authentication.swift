import Foundation

/// Supplies authentication to an Openbase agent integration without coupling
/// the package to a particular identity SDK.
public protocol AuthTokenProvider: Sendable {
    /// The current bearer-compatible token, or `nil` when signed out.
    var authToken: String? { get async }

    /// Performs an authenticated request using the consuming app's auth stack.
    func authenticatedRequest(
        method: String,
        url: String,
        data: [String: Any]?
    ) async throws -> Data
}
