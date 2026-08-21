public import Defunctionalize
import Testing

@Defunctionalize
struct UserService: Sendable {
    var fetchUser: @Sendable (Int) -> String
    var deleteUser: @Sendable (_ id: Int) -> Bool
    var reset: @Sendable () -> Void
    var timeout: Int
}

@Defunctionalize
struct FileService: Sendable {
    var read: @Sendable (_ path: String) -> [UInt8]
    var write: @Sendable (_ path: String, _ contents: [UInt8]) -> Bool
}

@Defunctionalize
struct Calculator: Sendable {
    var add: @Sendable (Int, Int) -> Int
}

@Defunctionalize
struct ThrowingService: Sendable {
    var fetch: @Sendable (Int) throws -> String
    var save: @Sendable (String) async throws -> Bool
}

@Defunctionalize
struct SingleOp: Sendable {
    var execute: @Sendable (String) -> Void
}

@Defunctionalize
struct WithUnderscore: Sendable {
    var _fetch: @Sendable (Int) -> String
}

@Defunctionalize
struct Mixed: Sendable {
    var load: @Sendable (String) -> Int
    var name: String
    var save: @Sendable (Int) -> Void
}
