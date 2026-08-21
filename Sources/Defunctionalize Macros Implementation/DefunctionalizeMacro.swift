import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DefunctionalizeMacro {}

extension DefunctionalizeMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext

    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                SwiftDiagnostics.Diagnostic(
                    node: node,
                    message: Diagnostic.requiresStruct
                )
            )
            return []
        }

        return expand(structDecl, node: node, context: context)
    }
}
