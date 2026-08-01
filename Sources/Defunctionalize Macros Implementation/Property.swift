import SwiftSyntax

// MARK: - Property

/// A function-typed stored property extracted from the source struct.
struct Property {
    /// The identifier text as it appears in source, including backtick escaping.
    let name: String
    let parameters: [Parameter]
}

extension Property {
    /// The case name for the Calls enum: strips leading `_` from the property name.
    var `case`: String {
        guard name.hasPrefix("_") || (name.hasPrefix("`") && name.dropFirst().hasPrefix("_")) else {
            return name
        }
        let unescaped = name.hasPrefix("`") ? String(name.dropFirst().dropLast()) : name
        let stripped = String(unescaped.dropFirst())
        if stripped.contains(" ") || isSwiftKeyword(stripped) {
            return "`\(stripped)`"
        }
        return stripped
    }

    /// Parameters eligible for the call algebra (excludes ownership-annotated).
    var copyable: [Parameter] {
        parameters.filter { !$0.ownership.isAnnotated }
    }
}
