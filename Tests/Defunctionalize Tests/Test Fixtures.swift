import Testing
public import Defunctionalize

// MARK: - Basic Witness Struct

@Defunctionalize
struct UserService: Sendable {
    var fetchUser: @Sendable (Int) -> String
    var deleteUser: @Sendable (_ id: Int) -> Bool
    var reset: @Sendable () -> Void
    var timeout: Int  // non-function: excluded from Calls
}

// MARK: - Labeled Parameters

@Defunctionalize
struct FileService: Sendable {
    var read: @Sendable (_ path: String) -> [UInt8]
    var write: @Sendable (_ path: String, _ contents: [UInt8]) -> Bool
}

// MARK: - Unlabeled Parameters

@Defunctionalize
struct Calculator: Sendable {
    var add: @Sendable (Int, Int) -> Int
}

// MARK: - Effects (not in call algebra)

@Defunctionalize
struct ThrowingService: Sendable {
    var fetch: @Sendable (Int) throws -> String
    var save: @Sendable (String) async throws -> Bool
}

// MARK: - Single Closure Property

@Defunctionalize
struct SingleOp: Sendable {
    var execute: @Sendable (String) -> Void
}

// MARK: - Leading Underscore

@Defunctionalize
struct WithUnderscore: Sendable {
    var _fetch: @Sendable (Int) -> String
}

// MARK: - Mixed: closure + non-closure

@Defunctionalize
struct Mixed: Sendable {
    var load: @Sendable (String) -> Int
    var name: String
    var save: @Sendable (Int) -> Void
}
