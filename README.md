# OpenbaseAgentUI

OpenbaseAgentUI is the dependency-light public contract used to connect an iOS app to an Openbase agent session. It provides configuration, authentication and secure-storage adapters, call-token preparation, lifecycle events, and session-facing state and errors.

The package deliberately does not ship an authentication client, Keychain implementation, LiveKit session, or app UI. Consuming apps supply those concrete integrations, which keeps credentials and product-specific policy outside the reusable core.

## Installation

Add the package with Swift Package Manager:

```swift
.package(
    url: "https://github.com/openbase-community/openbase-agent-ui-swift.git",
    from: "0.1.0"
)
```

Releases are tagged from the `main` branch; `0.1.0` is the first published
revision.

Then depend on the library product:

```swift
.product(name: "OpenbaseAgentUI", package: "openbase-agent-ui-swift")
```

## Configuration

Implement the adapters owned by your app and configure the package during app startup:

```swift
import OpenbaseAgentUI

OpenbaseAgentUI.configure(
    configuration: AppAgentConfiguration(),
    authProvider: AppAuthTokenProvider(),
    secureStorage: AppSecureStorage(),
    callTokenProvider: AppCallTokenProvider(),
    eventHandler: AppAgentEventHandler.shared
)
```

`CallTokenProvider` can optionally prepare a backend before returning a room token. The default implementation does no preparation, so simple integrations only need to implement `fetchRoomToken`.

## Boundary

This package owns stable interfaces and value types that a session UI can depend on. A consuming app remains responsible for:

- user authentication and authenticated HTTP requests;
- Keychain or other secure storage;
- minting LiveKit-compatible room tokens;
- the concrete call/session engine and presentation;
- handling emitted lifecycle events.

## License

OpenbaseAgentUI is licensed under AGPL-3.0-only. See [LICENSE](LICENSE).
