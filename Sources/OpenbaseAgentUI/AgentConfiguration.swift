import Foundation

/// Environment-specific settings required by an Openbase agent session.
public protocol OpenbaseAgentConfiguration: Sendable {
    /// The LiveKit server URL used for calls. Return `nil` to disable calling.
    @MainActor var liveKitServerUrl: String? { get }
}
public extension OpenbaseAgentConfiguration {
    @MainActor var liveKitServerUrl: String? { nil }
}

/// Process-wide dependency registry used by the session implementation and UI.
/// Configure it once during app startup before accessing required providers.
public final class OpenbaseAgentUI: @unchecked Sendable {
    public static let shared = OpenbaseAgentUI()

    private var storedConfiguration: (any OpenbaseAgentConfiguration)?
    private var storedAuthProvider: (any AuthTokenProvider)?
    private var storedSecureStorage: (any SecureStorage)?
    private var storedCallTokenProvider: (any CallTokenProvider)?
    private weak var storedEventHandler: (any OpenbaseAgentEventHandler)?
    private let lock = NSLock()

    private init() {}

    public static func configure(
        configuration: any OpenbaseAgentConfiguration,
        authProvider: any AuthTokenProvider,
        secureStorage: any SecureStorage,
        callTokenProvider: (any CallTokenProvider)? = nil,
        eventHandler: (any OpenbaseAgentEventHandler)? = nil
    ) {
        shared.lock.withLock {
            shared.storedConfiguration = configuration
            shared.storedAuthProvider = authProvider
            shared.storedSecureStorage = secureStorage
            shared.storedCallTokenProvider = callTokenProvider
            shared.storedEventHandler = eventHandler
        }
    }

    public static var configuration: any OpenbaseAgentConfiguration {
        get throws {
            try shared.lock.withLock {
                guard let configuration = shared.storedConfiguration else {
                    throw OpenbaseAgentUIError.notConfigured
                }
                return configuration
            }
        }
    }

    public static var authProvider: any AuthTokenProvider {
        get throws {
            try shared.lock.withLock {
                guard let authProvider = shared.storedAuthProvider else {
                    throw OpenbaseAgentUIError.notConfigured
                }
                return authProvider
            }
        }
    }

    public static var secureStorage: any SecureStorage {
        get throws {
            try shared.lock.withLock {
                guard let secureStorage = shared.storedSecureStorage else {
                    throw OpenbaseAgentUIError.notConfigured
                }
                return secureStorage
            }
        }
    }

    public static var callTokenProvider: (any CallTokenProvider)? {
        shared.lock.withLock { shared.storedCallTokenProvider }
    }

    public static var isConfigured: Bool {
        shared.lock.withLock { shared.storedConfiguration != nil }
    }

    @MainActor
    public static var isCallingEnabled: Bool {
        let dependencies = shared.lock.withLock {
            (shared.storedCallTokenProvider, shared.storedConfiguration)
        }
        return dependencies.0 != nil && dependencies.1?.liveKitServerUrl != nil
    }

    @MainActor
    public static func emit(_ event: OpenbaseAgentEvent) {
        let eventHandler = shared.lock.withLock { shared.storedEventHandler }
        eventHandler?.handleEvent(event)
    }

    static func resetForTesting() {
        shared.lock.withLock {
            shared.storedConfiguration = nil
            shared.storedAuthProvider = nil
            shared.storedSecureStorage = nil
            shared.storedCallTokenProvider = nil
            shared.storedEventHandler = nil
        }
    }
}

public enum OpenbaseAgentUIError: Error, LocalizedError, Sendable {
    case notConfigured

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "OpenbaseAgentUI has not been configured. Call OpenbaseAgentUI.configure(...) during app initialization."
        }
    }
}
