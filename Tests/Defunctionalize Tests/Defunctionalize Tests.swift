import Testing

@testable import Defunctionalize

@Suite("Defunctionalize")
struct DefunctionalizeTests {

    @Suite("Unit")
    struct Unit {

        // MARK: - Basic call algebra

        @Test func `calls case generation`() {
            let call = UserService.Calls.fetchUser(42)
            #expect(call.fetchUser == 42)
        }

        @Test func `labeled calls case`() {
            let call = UserService.Calls.deleteUser(id: 7)
            #expect(call.deleteUser == 7)
        }

        @Test func `parameterless case`() {
            let call = UserService.Calls.reset
            #expect(call.reset != nil)
        }

        @Test func `non function field excluded`() {
            // timeout is not a closure — excluded from Calls
            #expect(UserService.Calls.Case.count.rawValue == 3)
        }

        // MARK: - Multi-parameter

        @Test func `multi param extraction`() {
            let call = FileService.Calls.write(path: "/tmp", contents: [1, 2])
            let extracted = call.write
            #expect(extracted?.path == "/tmp")
        }

        @Test func `unlabeled params`() {
            let call = Calculator.Calls.add(1, 2)
            #expect(call.add != nil)
        }

        // MARK: - Effects excluded from parameters

        @Test func `throwing closure parameters only`() {
            let call = ThrowingService.Calls.fetch(42)
            #expect(call.fetch == 42)
        }

        @Test func `async throwing parameters only`() {
            let call = ThrowingService.Calls.save("data")
            #expect(call.save == "data")
        }

        // MARK: - Case discriminant

        @Test func `case discriminant`() {
            #expect(UserService.Calls.Case.fetchUser.ordinal.rawValue == 0)
            #expect(UserService.Calls.Case.deleteUser.ordinal.rawValue == 1)
            #expect(UserService.Calls.Case.reset.ordinal.rawValue == 2)
        }

        @Test func `case property`() {
            #expect(UserService.Calls.fetchUser(1).case == .fetchUser)
            #expect(UserService.Calls.reset.case == .reset)
        }

        @Test func `case enumeration`() {
            var count = 0
            for _ in UserService.Calls.Case.allCases {
                count += 1
            }
            #expect(count == 3)
        }

        // MARK: - Prisms

        @Test func `prism extract`() {
            #expect(UserService.Calls.prisms.fetchUser.extract(.fetchUser(42)) == 42)
            #expect(UserService.Calls.prisms.fetchUser.extract(.reset) == nil)
        }

        @Test func `is method`() {
            #expect(UserService.Calls.fetchUser(1).is(\.fetchUser) == true)
            #expect(UserService.Calls.fetchUser(1).is(\.reset) == false)
        }

        @Test func `prism subscript`() {
            #expect(UserService.Calls.fetchUser(42)[prism: \.fetchUser] == 42)
        }

        @Test func modify() {
            var call = UserService.Calls.fetchUser(1)
            call.modify(\.fetchUser) { $0 = 99 }
            #expect(call.fetchUser == 99)
        }

        // MARK: - Leading underscore stripping

        @Test func `underscore stripping`() {
            let call = WithUnderscore.Calls.fetch(42)
            #expect(call.fetch == 42)
        }

        // MARK: - Mixed closure + non-closure

        @Test func `mixed only closures`() {
            // Only load and save are in Calls — name is excluded
            #expect(Mixed.Calls.Case.count.rawValue == 2)
            let call = Mixed.Calls.load("key")
            #expect(call.load == "key")
        }

        // MARK: - Single operation

        @Test func `single operation`() {
            let call = SingleOp.Calls.execute("hello")
            #expect(call.execute == "hello")
            #expect(SingleOp.Calls.Case.count.rawValue == 1)
        }
    }
}
