import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

func extractFunction(from type: TypeSyntax) -> FunctionTypeSyntax? {
    if let function = type.as(FunctionTypeSyntax.self) { return function }
    if let attributed = type.as(AttributedTypeSyntax.self) {
        return extractFunction(from: attributed.baseType)
    }
    if let optional = type.as(OptionalTypeSyntax.self) {
        return extractFunction(from: optional.wrappedType)
    }
    if let tuple = type.as(TupleTypeSyntax.self),
        tuple.elements.count == 1,
        let element = tuple.elements.first
    {
        return extractFunction(from: element.type)
    }
    return nil
}

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

                    case .keyword(.borrowing):
                        ownership = .init(isInout: false, specifier: .borrowing)

                    case .keyword(.consuming):
                        ownership = .init(isInout: false, specifier: .consuming)

                    default: break
                    }
                }
            }
        }

        return Parameter(label: label, type: param.type, ownership: ownership)
    }
}

func extractProperties(from structDecl: StructDeclSyntax) -> [Property] {
    structDecl.memberBlock.members.compactMap { member in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
            varDecl.bindingSpecifier.tokenKind == .keyword(.var)
                || varDecl.bindingSpecifier.tokenKind == .keyword(.let),
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

    let caseNames = properties.map(\.case)
    members.append(generateCaseDiscriminant(caseNames: caseNames, isPublic: isPublic))

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

    members.append("\(inline)\(access)static var prisms: Prisms { Prisms() }")

    members.append(
        """
            \(inline)\(access)func `is`<Value>(_ keyPath: KeyPath<Prisms, Optic_Primitives.Optic.Prism<Calls, Value>>) -> Bool {
                    Self.prisms[keyPath: keyPath].extract(self) != nil
                }
        """
    )

    members.append(
        """
            \(inline)\(access)subscript<Value>(prism keyPath: KeyPath<Prisms, Optic_Primitives.Optic.Prism<Calls, Value>>) -> Value? {
                    Self.prisms[keyPath: keyPath].extract(self)
                }
        """
    )

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

func isSwiftKeyword(_ identifier: String) -> Bool {
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
