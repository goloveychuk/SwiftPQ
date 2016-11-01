//
//  main.swift
//  PurePostgres
//
//  Created by badim on 10/28/16.
//
//

import Foundation





let con = try Connection(host: "127.0.0.1", port: 5432, database: "auto_trader", user: "badim", password: "testpass")


let query = "select id, source_id, body_type, sold, datetime_added from models_app_car where year = $1 or true order by id limit 100"


let st = con.statement(query: query)
try st.parse()


try st.bind([2008.toBytes])
try st.execute()



struct Car {
    let id: Int
    let source_id: Int
    let body_type: String
    let sold: Bool
    
}

for i in 0..<10 {
    let row = try st.getRow()!
    //let id: Int32? = row.val(0)
    //let sourceId: Int32? = row.val(1)
    
    print(row.dict)
}





//pro.parse(query, args: [Int(2012).toBytes])

