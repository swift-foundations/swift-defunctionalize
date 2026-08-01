import SwiftSyntax

// MARK: - Parameter.Ownership

extension Parameter {
    struct Ownership {
        let isInout: Bool
        let specifier: Keyword?
    }
}

extension Parameter.Ownership {
    var isAnnotated: Bool { isInout || specifier != nil }

    static let none = Self(isInout: false, specifier: nil)
}
