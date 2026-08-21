import SwiftDiagnostics

extension DefunctionalizeMacro {
    enum Diagnostic: String, DiagnosticMessage {
        case requiresStruct
        case noClosureProperties
    }
}

extension DefunctionalizeMacro.Diagnostic {
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
