//
//  Connection.swift
//  PurePostgres
//
//  Created by badim on 10/28/16.
//
//

import Foundation


class Transaction {
    func commit() {
        
    }
    func rollback() {
        
    }
    func cursor() {
        
    }
    
}


public class Connection {
    private let pr: Protocol
    
    public init(host: String, port: Int, database: String, user: String, password: String) throws {
        let socket: Socket = try! LibmillSocket(host: host, port: port)
        
        pr = Protocol(socket: socket)
        
        try pr.startup(user: user, database: database, password: password)
    }
    
    public func statement(query: String) -> Statement {
        return Statement(pr: pr, query: query)
    }
    @discardableResult
    public func execute(_ query: String, args: [PostgresTypeConvertible?] = []) throws -> Statement {
        let st = Statement(pr: pr, query: query)
        try st.parse(args)
        try st.bind(args)
        try st.execute()
        return st
    }
    func transaction() -> Transaction {
        return Transaction()
    }
    func close() {
        
    }
}


