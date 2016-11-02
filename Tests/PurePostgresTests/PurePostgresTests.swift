import XCTest
@testable import PurePostgres

class PurePostgresTests: XCTestCase {
    var conn: PurePostgres.Connection!
    
    override func setUp() {
        super.setUp()
        conn = try! Connection(host: "127.0.0.1", port: 5432, database: "auto_trader", user: "badim", password: "testpass")
        
    }
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        
        let query = "select id, source_id, body_type, sold, datetime_added from models_app_car where year = $1 or true order by id limit 100000"
        
        
        
        let st = try conn.execute(query, args: [2010])
        
        
        
        while let row = try st.getRow() {
    
        }
        
    
    }


    static var allTests : [(String, (PurePostgresTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
