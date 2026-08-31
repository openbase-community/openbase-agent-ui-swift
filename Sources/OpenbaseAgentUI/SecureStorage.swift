/// Secure persistence supplied by the consuming app, normally backed by the
/// Keychain. The reusable package never chooses storage keys or persists data
/// on its own.
public protocol SecureStorage: Sendable {
    func save(key: String, value: String) throws
    func read(key: String) -> String?
    func delete(key: String)
}
