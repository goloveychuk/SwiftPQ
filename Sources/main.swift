//
//  main.swift
//  PurePostgres
//
//  Created by badim on 10/28/16.
//
//

import Foundation





let con = try Connection(host: "127.0.0.1", port: 5432, database: "auto_trader", user: "badim", password: "testpass")


let query = "select * from models_app_car where year = $1 limit 100"


let st = con.statement(query: query)
try st.parse()


try st.bind([2008.toBytes])
try st.execute()


for i in 0..<10 {
    let row = try st.getRow()
    print(row)
}





//pro.parse(query, args: [Int(2012).toBytes])

