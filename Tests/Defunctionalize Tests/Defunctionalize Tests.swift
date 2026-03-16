import Testing
@testable import Defunctionalize

@Suite("Defunctionalize")
struct DefunctionalizeTests {

    @Suite("Unit")
    struct Unit {

        // MARK: - Basic call algebra

        @Test func callsCaseGeneration() {
            let call = UserService.Calls.fetchUser(42)
            #expect(call.fetchUser == 42)
        }

        @Test func labeledCallsCase() {
            let call = UserService.Calls.deleteUser(id: 7)
            #expect(call.deleteUser == 7)
        }

        @Test func parameterlessCase() {
            let call = UserService.Calls.reset
            #expect(call.reset != nil)
        }

        @Test func nonFunctionFieldExcluded() {
            // timeout is not a closure — excluded from Calls
            #expect(UserService.Calls.Case.count.rawValue == 3)
        }

        // MARK: - Multi-parameter

        @Test func multiParamExtraction() {
            let call = FileService.Calls.write(path: "/tmp", contents: [1, 2])
            let extracted = call.write
            #expect(extracted?.path == "/tmp")
        }

        @Test func unlabeledParams() {
            let call = Calculator.Calls.add(1, 2)
            #expect(call.add != nil)
        }

        // MARK: - Effects excluded from parameters

        @Test func throwingClosureParametersOnly() {
            let call = ThrowingService.Calls.fetch(42)
            #expect(call.fetch == 42)
        }

        @Test func asyncThrowingParametersOnly() {
            let call = ThrowingService.Calls.save("data")
            #expect(call.save == "data")
        }

        // MARK: - Case discriminant

        @Test func caseDiscriminant() {
            #expect(UserService.Calls.Case.fetchUser.ordinal.rawValue == 0)
            #expect(UserService.Calls.Case.deleteUser.ordinal.rawValue == 1)
            #expect(UserService.Calls.Case.reset.ordinal.rawValue == 2)
        }

        @Test func caseProperty() {
            #expect(UserService.Calls.fetchUser(1).case == .fetchUser)
            #expect(UserService.Calls.reset.case == .reset)
        }

        @Test func caseEnumeration() {
            var count = 0
            for _ in UserService.Calls.Case.allCases {
                count += 1
            }
            #expect(count == 3)
        }

        // MARK: - Prisms

        @Test func prismExtract() {
            #expect(UserService.Calls.prisms.fetchUser.extract(.fetchUser(42)) == 42)
            #expect(UserService.Calls.prisms.fetchUser.extract(.reset) == nil)
        }

        @Test func isMethod() {
            #expect(UserService.Calls.fetchUser(1).is(\.fetchUser) == true)
            #expect(UserService.Calls.fetchUser(1).is(\.reset) == false)
        }

        @Test func prismSubscript() {
            #expect(UserService.Calls.fetchUser(42)[prism: \.fetchUser] == 42)
        }

        @Test func modify() {
            var call = UserService.Calls.fetchUser(1)
            call.modify(\.fetchUser) { $0 = 99 }
            #expect(call.fetchUser == 99)
        }

        // MARK: - Leading underscore stripping

        @Test func underscoreStripping() {
            let call = WithUnderscore.Calls.fetch(42)
            #expect(call.fetch == 42)
        }

        // MARK: - Mixed closure + non-closure

        @Test func mixedOnlyClosures() {
            // Only load and save are in Calls — name is excluded
            #expect(Mixed.Calls.Case.count.rawValue == 2)
            let call = Mixed.Calls.load("key")
            #expect(call.load == "key")
        }

        // MARK: - Single operation

        @Test func singleOperation() {
            let call = SingleOp.Calls.execute("hello")
            #expect(call.execute == "hello")
            #expect(SingleOp.Calls.Case.count.rawValue == 1)
        }
    }
}
