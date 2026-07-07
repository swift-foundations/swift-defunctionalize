import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DefunctionalizeMacrosPlugin: CompilerPlugin {
    // [any Macro.Type] element type is required by SwiftCompilerPlugin.CompilerPlugin.providingMacros.
    // swiftlint:disable:next no_any_protocol_existential
    let providingMacros: [any Macro.Type] = [
        DefunctionalizeMacro.self
    ]
}
