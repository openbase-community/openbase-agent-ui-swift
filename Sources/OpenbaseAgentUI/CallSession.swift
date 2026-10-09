import Foundation

public struct PreparedCallToken: Sendable, Equatable {
    public let roomName: String
    public let token: String

    public init(roomName: String, token: String) {
        self.roomName = roomName
        self.token = token
    }
}
public enum CallPreparationState: Sendable, Equatable {
    case idle
    case checkingCloudWorkspace
    case startingCloudWorkspace
    case waitingForCloudWorkspace

    public var isPreparing: Bool { self != .idle }
}

/// The conversation a call is started from. A call started from a thread
/// talks to that thread from its first word; a call started with no target
/// talks to the dispatcher.
public struct CallTargetThread: Sendable, Equatable {
    public let threadId: String
    /// The name the app shows for the thread, spoken when it cannot be
    /// reached. Optional: the runtime derives one otherwise.
    public let label: String?

    public init(threadId: String, label: String? = nil) {
        self.threadId = threadId
        let trimmed = label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.label = trimmed.isEmpty ? nil : trimmed
    }
}

/// Mints session credentials and, when necessary, prepares the backing agent
/// runtime before a call connects.
///
/// Implement the `targetThread:` variants to start calls inside a thread; the
/// defaults forward to the target-less methods, so an implementation of the
/// original two methods still satisfies the protocol (dispatcher calls only).
public protocol CallTokenProvider: Sendable {
    func fetchRoomToken(
        roomName: String,
        livekitDispatchAgentName: String
    ) async throws -> String

    func fetchRoomToken(
        roomName: String,
        livekitDispatchAgentName: String,
        targetThread: CallTargetThread?
    ) async throws -> String

    func shouldPrepareRoomToken() async -> Bool

    func prepareRoomTokenIfNeeded(
        roomName: String,
        livekitDispatchAgentName: String,
        onProgress: @escaping @Sendable (CallPreparationState) -> Void
    ) async throws -> PreparedCallToken?

    func prepareRoomTokenIfNeeded(
        roomName: String,
        livekitDispatchAgentName: String,
        targetThread: CallTargetThread?,
        onProgress: @escaping @Sendable (CallPreparationState) -> Void
    ) async throws -> PreparedCallToken?
}

public extension CallTokenProvider {
    func fetchRoomToken(
        roomName: String,
        livekitDispatchAgentName: String,
        targetThread _: CallTargetThread?
    ) async throws -> String {
        try await fetchRoomToken(roomName: roomName, livekitDispatchAgentName: livekitDispatchAgentName)
    }

    func shouldPrepareRoomToken() async -> Bool { false }

    func prepareRoomTokenIfNeeded(
        roomName _: String,
        livekitDispatchAgentName _: String,
        onProgress _: @escaping @Sendable (CallPreparationState) -> Void
    ) async throws -> PreparedCallToken? {
        nil
    }

    func prepareRoomTokenIfNeeded(
        roomName: String,
        livekitDispatchAgentName: String,
        targetThread _: CallTargetThread?,
        onProgress: @escaping @Sendable (CallPreparationState) -> Void
    ) async throws -> PreparedCallToken? {
        try await prepareRoomTokenIfNeeded(
            roomName: roomName,
            livekitDispatchAgentName: livekitDispatchAgentName,
            onProgress: onProgress
        )
    }
}

/// State exposed by a concrete call/session engine to its presentation layer.
public enum CallState: Sendable {
    case idle
    case errored(any Error)
    case activeIncoming
    case activeOutgoing
    case connected

    public var isActive: Bool {
        switch self {
        case .activeIncoming, .activeOutgoing, .connected:
            return true
        case .idle, .errored:
            return false
        }
    }

    public var errorMessage: String? {
        guard case let .errored(error) = self else { return nil }
        return error.localizedDescription
    }
}

extension CallState: Equatable {
    public static func == (lhs: CallState, rhs: CallState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.errored, .errored),
             (.activeIncoming, .activeIncoming),
             (.activeOutgoing, .activeOutgoing),
             (.connected, .connected):
            return true
        default:
            return false
        }
    }
}

public enum CallManagerError: LocalizedError, Sendable {
    case tokenFetchFailed(String)
    case tokenRequestDenied(code: String?, message: String)
    case notAuthenticated
    case notConfigured
    case liveKitNotAvailable
    case inboundCallBusy
    case inboundInvitationMissing
    case inboundInvitationExpired

    public var errorDescription: String? {
        switch self {
        case let .tokenFetchFailed(message):
            return "Failed to fetch token: \(message)"
        case let .tokenRequestDenied(_, message):
            return message
        case .notAuthenticated:
            return "You must be logged in to start a call"
        case .notConfigured:
            return "Call functionality is not configured"
        case .liveKitNotAvailable:
            return "LiveKit server URL is not configured"
        case .inboundCallBusy:
            return "Another voice call is already active"
        case .inboundInvitationMissing:
            return "The incoming call invitation is unavailable"
        case .inboundInvitationExpired:
            return "The incoming call invitation expired"
        }
    }
}

public enum ActiveVoiceSessionMuteToggleResult: Sendable, Equatable {
    case muted
    case unmuted
    case noActiveVoiceSession
}
