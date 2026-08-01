import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - DefunctionalizeMacro

public struct DefunctionalizeMacro {}

// MARK: - MemberMacro

extension DefunctionalizeMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
            // Untyped throws forced by external protocol SwiftSyntaxMacros (macro expansion).
            // swiftlint:disable:next typed_throws_required
            // swift-linter:disable:next untyped throws
            // REASON: MemberMacro.expansion(of:providingMembersOf:conformingTo:in:) is an
            // external SwiftSyntaxMacros protocol requirement spelled with untyped `throws`;
            // no typed `E` can be named here without breaking the conformance.
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
