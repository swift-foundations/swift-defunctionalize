import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Extraction Types

/// A function-typed stored property extracted from the source struct.
struct Property {
    /// The identifier text as it appears in source, including backtick escaping.
    let name: String
    let parameters: [Parameter]

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

/// A parameter of a function-typed property.
struct Parameter {
    let label: String?
    let type: TypeSyntax

    struct Ownership {
        let isInout: Bool
        let specifier: Keyword?

        var isAnnotated: Bool { isInout || specifier != nil }

        static let none = Self(isInout: false, specifier: nil)
    }

    let ownership: Ownership

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

// MARK: - Extraction

/// Extracts function type from a type annotation, unwrapping Optional and Attributed wrappers.
func extractFunction(from type: TypeSyntax) -> FunctionTypeSyntax? {
    if let function = type.as(FunctionTypeSyntax.self) { return function }
    if let attributed = type.as(AttributedTypeSyntax.self) { return extractFunction(from: attributed.baseType) }
    if let optional = type.as(OptionalTypeSyntax.self) { return extractFunction(from: optional.wrappedType) }
    if let tuple = type.as(TupleTypeSyntax.self),
        tuple.elements.count == 1,
        let element = tuple.elements.first
    {
        return extractFunction(from: element.type)
    }
    return nil
}

/// Extracts parameters from a function type, detecting ownership annotations.
func extractParameters(from function: FunctionTypeSyntax) -> [Parameter] {
    function.parameters.map { param in
        let label: String? =
            param.secondName?.text
            ?? {
                guard let first = param.firstName?.text, first != "_" else { return nil }
                return first
            }()

        var ownership = Parameter.Ownership.none
        if let attributed = param.type.as(AttributedTypeSyntax.self) {
            for specifier in attributed.specifiers {
                if let simple = specifier.as(SimpleTypeSpecifierSyntax.self) {
                    switch simple.specifier.tokenKind {
                    case .keyword(.inout): ownership = .init(isInout: true, specifier: nil)
                    case .keyword(.borrowing): ownership = .init(isInout: false, specifier: .borrowing)
                    case .keyword(.consuming): ownership = .init(isInout: false, specifier: .consuming)
                    default: break
                    }
                }
            }
        }

        return Parameter(label: label, type: param.type, ownership: ownership)
    }
}

/// Extracts only function-typed stored properties from a struct.
func extractProperties(from structDecl: StructDeclSyntax) -> [Property] {
    structDecl.memberBlock.members.compactMap { member in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
            varDecl.bindingSpecifier.tokenKind == .keyword(.var) || varDecl.bindingSpecifier.tokenKind == .keyword(.let),
            !varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }),
            let binding = varDecl.bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
            let typeAnnotation = binding.typeAnnotation,
            binding.accessorBlock == nil,
            let function = extractFunction(from: typeAnnotation.type)
        else {
            return nil
        }

        return Property(
            name: identifier.identifier.text,
            parameters: extractParameters(from: function)
        )
    }
}

// MARK: - Expansion

func expand(
    _ structDecl: StructDeclSyntax,
    node: AttributeSyntax,
    context: some MacroExpansionContext
) -> [DeclSyntax] {
    let properties = extractProperties(from: structDecl)

    guard !properties.isEmpty else {
        context.diagnose(
            Diagnostic(
                node: node,
                message: DefunctionalizeMacro.Diagnostic.noClosureProperties
            )
        )
        return []
    }

    let isPublic = isPublicDecl(structDecl)
    let inlinable = isPublic && canInline(from: structDecl.memberBlock)
    let sendable = isSendable(structDecl)
    let access = isPublic ? "public " : ""
    let inline = inlinable ? "@inlinable\n        " : ""

    var members: [String] = []

    // 1. Case declarations
    for prop in properties {
        let params = prop.copyable
        if params.isEmpty {
            members.append("case \(prop.case)")
        } else {
            let values = params.map { param in
                param.label.map { "\($0): \(param.base)" } ?? "\(param.base)"
            }.joined(separator: ", ")
            members.append("case \(prop.case)(\(values))")
        }
    }

    // 2. Extraction properties
    for prop in properties {
        let params: [(label: String?, type: String)] = prop.copyable.map {
            ($0.label, $0.base.trimmedDescription)
        }
        members.append(
            generateExtractionProperty(
                caseName: prop.case,
                parameters: params,
                isPublic: isPublic
            ).description
        )
    }

    // 3. Case discriminant
    let caseNames = properties.map(\.case)
    members.append(generateCaseDiscriminant(caseNames: caseNames, isPublic: isPublic))

    // 4. var case: Case
    let caseCases = properties.map { "case .\($0.case): .\($0.case)" }
        .joined(separator: "\n            ")

    members.append(
        """
            \(inline)\(access)var `case`: Case {
                    switch self {
                    \(caseCases)
                    }
                }
        """
    )

    // 5. Prisms struct
    let prisms = properties.map { prop in
        generatePrism(
            for: PrismCase(
                caseName: prop.case,
                rootTypeName: "Calls",
                parameters: prop.copyable.map { ($0.label, $0.base.trimmedDescription) }
            )
        )
    }.joined(separator: "\n\n        ")

    members.append(
        """
            \(access)struct Prisms: Sendable {
                    \(inline)\(access)init() {}

                    \(prisms)
                }
        """
    )

    // 6. static var prisms
    members.append("\(inline)\(access)static var prisms: Prisms { Prisms() }")

    // 7. is(_:)
    members.append(
        """
            \(inline)\(access)func `is`<Value>(_ keyPath: KeyPath<Prisms, Optic_Primitives.Optic.Prism<Calls, Value>>) -> Bool {
                    Self.prisms[keyPath: keyPath].extract(self) != nil
                }
        """
    )

    // 8. subscript[prism:]
    members.append(
        """
            \(inline)\(access)subscript<Value>(prism keyPath: KeyPath<Prisms, Optic_Primitives.Optic.Prism<Calls, Value>>) -> Value? {
                    Self.prisms[keyPath: keyPath].extract(self)
                }
        """
    )

    // 9. modify(_:_:)
    members.append(
        """
            \(inline)\(access)mutating func modify<Value>(_ keyPath: KeyPath<Prisms, Optic_Primitives.Optic.Prism<Calls, Value>>, _ transform: (inout Value) -> Void) {
                    let prism = Self.prisms[keyPath: keyPath]
                    guard var value = prism.extract(self) else { return }
                    transform(&value)
                    self = prism.embed(value)
                }
        """
    )

    // Build the enum
    let inheritance =
        sendable
        ? ": Sendable, Optic_Primitives.__OpticPrismAccessible"
        : ": Optic_Primitives.__OpticPrismAccessible"

    let body = members.joined(separator: "\n\n        ")

    let callsEnum: DeclSyntax = """
        \(raw: access)enum Calls\(raw: inheritance) {
            \(raw: body)
        }
        """

    return [callsEnum]
}

// MARK: - Keyword Check

private func isSwiftKeyword(_ identifier: String) -> Bool {
    [
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
        "func", "import", "init", "inout", "internal", "let", "open", "operator",
        "private", "precedencegroup", "protocol", "public", "rethrows", "static",
        "struct", "subscript", "typealias", "var", "break", "case", "catch",
        "continue", "default", "defer", "do", "else", "fallthrough", "for",
        "guard", "if", "in", "repeat", "return", "switch", "throw", "where",
        "while", "as", "false", "is", "nil", "self", "Self", "super",
        "throws", "true", "try", "async", "await",
    ].contains(identifier)
}
