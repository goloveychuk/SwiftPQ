import XCTest
@testable import PurePostgres

class PurePostgresTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(PurePostgres().text, "Hello, World!")
    }


    static var allTests : [(String, (PurePostgresTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
