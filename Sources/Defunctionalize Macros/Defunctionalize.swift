@_exported public import Finite_Primitives
@_exported public import Optic_Primitives

@attached(member, names: arbitrary)
public macro Defunctionalize() =
    #externalMacro(
        module: "Defunctionalize_Macros_Implementation",
        type: "DefunctionalizeMacro"
    )
