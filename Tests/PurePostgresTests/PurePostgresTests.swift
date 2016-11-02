import XCTest
@testable import PurePostgres


let sql = "create table TestBindings (t_int8 int8 not null, t_int4 int4 not null, t_int2 int2 not null," +
"t_serial8 serial8 not null, t_serial4 serial4 not null, t_serial2 serial2 not null," +
"t_decimal decimal not null, t_money money not null," +
"t_boolean bool not null, t_bytea bytea not null," +
"t_char_one char not null, t_char_ten char(10) not null, t_varchar_one varchar not null, t_varchar_ten varchar(10) not null, t_text text not null," +
"t_float8 float8 not null, t_float4 float4 not null," +
"t_date date not null, t_time time not null, t_timetz timetz not null, t_timestamp timestamp not null, t_timestamptz timestamptz not null," +
"t_json json not null, t_uuid uuid not null," +
"t_int8_arr int8[]" +
")"


//-- t_jsonb jsonb not null,
//todo arrays, composite types

class PurePostgresTests: XCTestCase {
    var conn: PurePostgres.Connection!
    
    override func setUp() {
        super.setUp()
        conn = try! Connection(host: "127.0.0.1", port: 5432, database: "testdb_swiftpq", user: "badim", password: "testpass")
    }
    func testExample() throws {
        //let query = "select id, source_id, body_type, sold, datetime_added from models_app_car where year = $1 or true order by id limit 100000"
        
        
        
        //let st = try conn.execute(query, args: [2010])
        
        
        
        //while let row = try st.getRow() {
    
        //}
    }
    func cleanDb() {
        let st = try! conn.execute("delete from TestBindings")
        while let _ = try! st.getRow(){
            
        }
        
    }
    func testBindingsInsert() throws {
        
        cleanDb()
        
        let int8 = Int(1324572457543)
        let int4 = Int32(1212312312)
        let int2 = Int16(2334)
        let serial8 = Int(234234234232)
        let serial4 = Int32(90800564)
        let serial2 = Int16(4321)
        let decimal = Float64(312.123) //to decimal
        let money = Int(12)
        let boolean = true
        let bytea = Data(bytes: [3,2, 123])
        let char_1 = "a"
        let char_10 = "fkdjshwidh"
        let varchar_1 = "c"
        let varchar_10 = "jslsoriapg"
        let text = "sadffdsafdsafasdsadffdsafdsafasdsadffdsafdsafasdsadffdsafdsafasdsadffdsafdsafasdsadffdsafdsafasdsadffdsafdsafasdsadffdsafdsafasdsadffdsafdsafasdsadffdsafdsafasd sadffdsafdsafasd sadffdsafdsafasd sadffdsafdsafasd"
        let float8 = Float64(123.123)
        let float4 = Float32(3211.432)
        
        let date = PgDate(year: 2012, month: 11, day: 3)
        let time = Time(hour: 23, minute: 12, second: 32, microsecond: 32321, tz: nil)
        let timetz = Time(hour: 23, minute: 12, second: 32,microsecond: 64321,  tz: nil)
        let timestamp = Date()
        let timestamptz = Date()
        let json = "{\"asd\": \"fsd\"}"
        let uuid = UUID(uuidString: "4asfas34safggds1")
        
        //let int8_arr: [Int64] = [543,123,123,543,12312312123,534254235]
        let int8_arr = CustomType(.ArrInt8, data: Data(bytes: [21, 31, 123, 1, 12, 12, 1, 32]))
        
        let q = "insert into TestBindings(t_int8, t_int4, t_int2, t_serial8, t_serial4, t_serial2, t_decimal, t_money, t_boolean, t_bytea, t_char_one, t_char_ten, t_varchar_one, t_varchar_ten, t_text, t_float8, t_float4, t_date, t_time, t_timetz, t_timestamp, t_timestamptz, t_json, t_uuid, t_int8_arr) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, null, null, null )"
        
        let st = try! conn.execute(q, args: [int8, int4, int2, serial8, serial4, serial2, decimal, money, boolean, bytea, char_1, char_10, varchar_1, varchar_10, text, float8, float4, date, time, timetz, timestamp, timestamptz])
        while let a = try! st.getRow() {
            
        }
        let qq = "select * from TestBindings"
        let st2 = try! conn.execute(qq)
        while let r = try! st2.getRow() {
            print(r.dict)
        }
        
    }


    static var allTests : [(String, (PurePostgresTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
