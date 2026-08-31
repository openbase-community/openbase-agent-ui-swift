/// Lifecycle events emitted by an Openbase agent session for the consuming app
/// to route into navigation, notifications, diagnostics, or analytics.
public enum OpenbaseAgentEvent: Sendable, Equatable {
    case incomingCall(callerId: String, callerName: String)
    case voipTokenUpdated(token: String)
    case callStarted(roomName: String)
    case callEnded(roomName: String)
    case error(message: String)
}
public protocol OpenbaseAgentEventHandler: AnyObject, Sendable {
    @MainActor
    func handleEvent(_ event: OpenbaseAgentEvent)
}
