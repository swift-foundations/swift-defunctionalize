import SwiftSyntax

// MARK: - Parameter

/// A parameter of a function-typed property.
struct Parameter {
    let label: String?
    let type: TypeSyntax
    let ownership: Ownership
}

extension Parameter {
    /// The type stripped of ownership specifiers and @escaping.
    var base: TypeSyntax {
        var result = type
        if ownership.isAnnotated,
            let attributed = result.as(AttributedTypeSyntax.self)
        {
            result = attributed.baseType
        }
        if let attributed = result.as(AttributedTypeSyntax.self) {
            let filtered = attributed.attributes.filter { attr in
                guard case .attribute(let a) = attr else { return true }
                return a.attributeName.trimmedDescription != "escaping"
            }
            if filtered.isEmpty && attributed.specifiers.isEmpty {
                return attributed.baseType.trimmed
            }
            var cleaned = attributed
            cleaned.attributes = AttributeListSyntax(filtered)
            return TypeSyntax(cleaned).trimmed
        }
        return result.trimmed
    }
}
