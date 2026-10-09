import Foundation
import Testing
@testable import OpenbaseAgentUI

@Suite(.serialized)
struct OpenbaseAgentUITests {
    init() {
        OpenbaseAgentUI.resetForTesting()
    }

    @Test @MainActor
    func configurationExposesConsumerAdapters() async throws {
        let configuration = TestConfiguration(liveKitServerUrl: "wss://voice.example.test")
        let auth = TestAuthTokenProvider()
        let storage = TestSecureStorage()
        let calls = TestCallTokenProvider()
        let events = TestEventHandler()

        OpenbaseAgentUI.configure(
            configuration: configuration,
            authProvider: auth,
            secureStorage: storage,
            callTokenProvider: calls,
            eventHandler: events
        )

        #expect(OpenbaseAgentUI.isConfigured)
        #expect(OpenbaseAgentUI.isCallingEnabled)
        #expect(try await OpenbaseAgentUI.authProvider.authToken == "test-token")
        #expect(try OpenbaseAgentUI.secureStorage.read(key: "missing") == nil)
        #expect(try await OpenbaseAgentUI.callTokenProvider?.fetchRoomToken(
            roomName: "room",
            livekitDispatchAgentName: "dispatcher"
        ) == "room-token")

        OpenbaseAgentUI.emit(.callStarted(roomName: "room"))
        #expect(events.events == [.callStarted(roomName: "room")])
    }

    @Test
    func requiredAdaptersThrowBeforeConfiguration() {
        #expect(throws: OpenbaseAgentUIError.self) {
            _ = try OpenbaseAgentUI.configuration
        }
        #expect(throws: OpenbaseAgentUIError.self) {
            _ = try OpenbaseAgentUI.authProvider
        }
        #expect(throws: OpenbaseAgentUIError.self) {
            _ = try OpenbaseAgentUI.secureStorage
        }
        #expect(OpenbaseAgentUI.callTokenProvider == nil)
    }

    @Test
    func callTokenPreparationDefaultsToNoOp() async throws {
        let provider = TestCallTokenProvider()
        #expect(await !provider.shouldPrepareRoomToken())
        #expect(try await provider.prepareRoomTokenIfNeeded(
            roomName: "room",
            livekitDispatchAgentName: "dispatcher",
            onProgress: { _ in }
        ) == nil)
    }

    @Test
    func callTargetDefaultsForwardToTargetlessProvider() async throws {
        // An implementation of the original two methods keeps compiling and
        // behaves as a dispatcher-only provider.
        let provider = TestCallTokenProvider()
        let target = CallTargetThread(threadId: "s_1", label: "  Hi are you there?  ")
        #expect(target.label == "Hi are you there?")
        #expect(CallTargetThread(threadId: "s_1", label: "   ").label == nil)
        #expect(try await provider.fetchRoomToken(
            roomName: "room",
            livekitDispatchAgentName: "dispatcher",
            targetThread: target
        ) == "room-token")
        #expect(try await provider.prepareRoomTokenIfNeeded(
            roomName: "room",
            livekitDispatchAgentName: "dispatcher",
            targetThread: target,
            onProgress: { _ in }
        ) == nil)
    }

    @Test
    func callTargetReachesAProviderThatImplementsIt() async throws {
        let provider = TargetAwareCallTokenProvider()
        let token = try await provider.fetchRoomToken(
            roomName: "room",
            livekitDispatchAgentName: "dispatcher",
            targetThread: CallTargetThread(threadId: "s_1", label: "Thread")
        )
        #expect(token == "room-token:s_1:Thread")
        #expect(try await provider.fetchRoomToken(roomName: "room", livekitDispatchAgentName: "dispatcher") == "room-token")
    }

    @Test
    func sessionStateSemanticsRemainStable() {
        #expect(CallState.connected.isActive)
        #expect(CallState.activeIncoming.isActive)
        #expect(!CallState.idle.isActive)
        #expect(CallState.errored(TestError()).errorMessage == "test error")
        #expect(CallState.errored(TestError()) == .errored(TestError()))
        #expect(CallPreparationState.startingCloudWorkspace.isPreparing)
        #expect(!CallPreparationState.idle.isPreparing)
    }
}

private struct TestConfiguration: OpenbaseAgentConfiguration {
    @MainActor let liveKitServerUrl: String?
}

private struct TestAuthTokenProvider: AuthTokenProvider {
    var authToken: String? { get async { "test-token" } }

    func authenticatedRequest(
        method _: String,
        url _: String,
        data _: [String: Any]?
    ) async throws -> Data {
        Data()
    }
}

private struct TestSecureStorage: SecureStorage {
    func save(key _: String, value _: String) throws {}
    func read(key _: String) -> String? { nil }
    func delete(key _: String) {}
}

private struct TestCallTokenProvider: CallTokenProvider {
    func fetchRoomToken(
        roomName _: String,
        livekitDispatchAgentName _: String
    ) async throws -> String {
        "room-token"
    }
}

private struct TargetAwareCallTokenProvider: CallTokenProvider {
    func fetchRoomToken(roomName: String, livekitDispatchAgentName: String) async throws -> String {
        try await fetchRoomToken(roomName: roomName, livekitDispatchAgentName: livekitDispatchAgentName, targetThread: nil)
    }

    func fetchRoomToken(
        roomName _: String,
        livekitDispatchAgentName _: String,
        targetThread: CallTargetThread?
    ) async throws -> String {
        guard let targetThread else { return "room-token" }
        return "room-token:\(targetThread.threadId):\(targetThread.label ?? "")"
    }
}

@MainActor
private final class TestEventHandler: OpenbaseAgentEventHandler, @unchecked Sendable {
    var events: [OpenbaseAgentEvent] = []

    func handleEvent(_ event: OpenbaseAgentEvent) {
        events.append(event)
    }
}

private struct TestError: LocalizedError {
    var errorDescription: String? { "test error" }
}
