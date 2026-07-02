@_exported public import Finite_Primitives
@_exported public import Optic_Primitives

/// Extracts a first-order call algebra from a witness struct (Reynolds 1972).
///
/// For each function-typed stored property, generates a case in the nested
/// `Calls` enum with associated values matching the closure's parameters.
/// Non-function fields are excluded. Effects (async/throws) are not part
/// of the call algebra.
///
/// ```swift
/// @Defunctionalize
/// struct UserService: Sendable {
///     var fetchUser: @Sendable (_ id: Int) -> String
///     var deleteUser: @Sendable (_ id: Int) throws -> Void
///     var timeout: Duration  // excluded — not a function type
/// }
/// // UserService.Calls.fetchUser(42)
/// // UserService.Calls.deleteUser(7)
/// // UserService.Calls.Case.allCases
/// ```
@attached(member, names: arbitrary)
public macro Defunctionalize() =
    #externalMacro(
        module: "Defunctionalize_Macros_Implementation",
        type: "DefunctionalizeMacro"
    )
