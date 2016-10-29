//
//  main.swift
//  PurePostgres
//
//  Created by badim on 10/28/16.
//
//

import Foundation




let socket: Socket = try! LibmillSocket(host: "127.0.0.1", port: 5432)

let pro = Protocol(socket: socket)

//pro.startup(user: "badim", database: "auto_trader")
pro.startup(user: "badim", database: "auto_trader", password: "testpass")


let query = "select * from models_app_car limit 1000"

pro.parse(query)
