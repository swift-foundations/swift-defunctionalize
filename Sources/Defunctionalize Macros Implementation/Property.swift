import SwiftSyntax

struct Property {

    let name: String
    let parameters: [Parameter]
}

extension Property {

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

    var copyable: [Parameter] {
        parameters.filter { !$0.ownership.isAnnotated }
    }
}
