//
//  Connection.swift
//  PurePostgres
//
//  Created by badim on 10/28/16.
//
//

import Foundation



class Connection {
    private let pr: Protocol
    
    init(host: String, port: Int, database: String, user: String, password: String) throws {
        let socket: Socket = try! LibmillSocket(host: host, port: port)
        
        pr = Protocol(socket: socket)
        
        try pr.startup(user: user, database: database, password: password)
    }
    
    func statement(query: String) -> Statement {
        return Statement(pr: pr, query: query)
    }
}
