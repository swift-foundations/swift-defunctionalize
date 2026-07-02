# swift-defunctionalize

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Macro that extracts a first-order call algebra from a witness struct: every function-typed stored property becomes an inspectable, matchable enum case.

---

## Quick Start

Closures are opaque — they cannot be compared, pattern-matched, logged, or stored for later inspection. `@Defunctionalize` (after Reynolds, 1972) turns the closure surface of a witness struct into plain data:

```swift
import Defunctionalize

@Defunctionalize
struct UserService: Sendable {
    var fetchUser: @Sendable (Int) -> String
    var deleteUser: @Sendable (_ id: Int) -> Bool
    var reset: @Sendable () -> Void
    var timeout: Int  // not a function type — excluded from Calls
}

// Each closure property is now a first-order value:
let call = UserService.Calls.fetchUser(42)

call.fetchUser              // Optional(42) — extraction by case name
call.case                   // .fetchUser   — payload-free discriminant
call.is(\.reset)            // false        — prism-based case test

// The discriminant is finitely enumerable:
UserService.Calls.Case.allCases          // fetchUser, deleteUser, reset
UserService.Calls.Case.count.rawValue    // 3
UserService.Calls.Case.fetchUser.ordinal // Ordinal(0)
```

Without the macro, asserting "the service received `deleteUser(id: 7)` and nothing else" requires hand-written recording state per closure; with it, calls are values you compare and enumerate directly.

---

## Installation

Add swift-defunctionalize to your `Package.swift` (pre-release — no tags published yet, pin to `main`):

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-defunctionalize.git", branch: "main")
]
```

Add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Defunctionalize", package: "swift-defunctionalize")
    ]
)
```

### Requirements

- Swift 6.3+
- macOS 26.0+, iOS 26.0+, tvOS 26.0+, watchOS 26.0+, visionOS 26.0+

---

## What the Macro Generates

Attaching `@Defunctionalize` to a struct adds a nested `Calls` enum (marked `Sendable` when the struct is) built from the struct's function-typed stored properties:

| Member | Shape |
|--------|-------|
| One case per closure property | `case fetchUser(Int)` — associated values mirror the closure's parameters, labels preserved |
| Extraction properties | `call.fetchUser` returns `Int?`; multi-parameter cases return a labeled tuple, e.g. `call.write?.path`; parameterless cases return `Void?` |
| `Case` discriminant | Payload-free enum conforming to `Finite.Enumerable` — `allCases`, `count`, `ordinal` |
| `var case: Case` | The discriminant of any call value |
| `prisms` / `Prisms` | One `Optic.Prism<Calls, Value>` per case, e.g. `Calls.prisms.fetchUser.extract(call)` |
| `is(_:)`, `subscript(prism:)`, `modify(_:_:)` | Prism-driven case testing, extraction, and in-place payload mutation |

Rules applied during extraction:

- **Non-function fields are excluded** — only closure-typed stored properties enter the algebra.
- **Effects are erased** — `throws` and `async` closures contribute their parameters only; effects and return types are not part of the call representation.
- **Leading underscores are stripped** — `var _fetch` produces `case fetch`.

The prism and enumeration vocabulary (`Optic.Prism`, `Finite.Enumerable`, `Ordinal`) is re-exported by the `Defunctionalize` product, so a single `import Defunctionalize` suffices.

---

## Usage Examples

### Multi-parameter calls extract as labeled tuples

```swift
import Defunctionalize

@Defunctionalize
struct FileService: Sendable {
    var read: @Sendable (_ path: String) -> [UInt8]
    var write: @Sendable (_ path: String, _ contents: [UInt8]) -> Bool
}

let call = FileService.Calls.write(path: "/tmp", contents: [1, 2])
call.write?.path      // Optional("/tmp")
call.write?.contents  // Optional([1, 2])
```

### Prisms compose extraction and mutation

```swift
import Defunctionalize

var call = UserService.Calls.fetchUser(1)

UserService.Calls.prisms.fetchUser.extract(call)  // Optional(1)
call[prism: \.fetchUser]                          // Optional(1)

call.modify(\.fetchUser) { $0 = 99 }
call.fetchUser                                    // Optional(99)
```

---

## Products

| Product | When to import |
|---------|----------------|
| `Defunctionalize` | The macro plus re-exported prism/enumeration vocabulary — the only import most consumers need |
| `Defunctionalize Test Support` | Re-exports `Defunctionalize` for test targets |

---

## License

Apache 2.0. See [LICENSE](LICENSE.md).
