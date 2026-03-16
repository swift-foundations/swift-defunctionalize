import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - DefunctionalizeMacro

public struct DefunctionalizeMacro {
    enum Diagnostic: String, DiagnosticMessage {
        case requiresStruct
        case noClosureProperties

        var message: String {
            switch self {
            case .requiresStruct:
                "@Defunctionalize can only be applied to structs"
            case .noClosureProperties:
                "@Defunctionalize requires at least one function-typed stored property"
            }
        }

        var diagnosticID: MessageID {
            MessageID(domain: "DefunctionalizeMacro", id: rawValue)
        }

        var severity: DiagnosticSeverity { .error }
    }
}

// MARK: - MemberMacro

extension DefunctionalizeMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(SwiftDiagnostics.Diagnostic(
                node: node,
                message: Diagnostic.requiresStruct
            ))
            return []
        }

        return expand(structDecl, node: node, context: context)
    }
}
