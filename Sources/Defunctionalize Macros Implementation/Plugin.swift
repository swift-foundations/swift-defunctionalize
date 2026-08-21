import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DefunctionalizeMacrosPlugin: CompilerPlugin {

    let providingMacros: [any Macro.Type] = [
        DefunctionalizeMacro.self
    ]
}
