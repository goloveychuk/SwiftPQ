//
//  Statement.swift
//  PurePostgres
//
//  Created by badim on 10/30/16.
//
//

import Foundation
import Reflection

var n = 0

func getUniqueName() -> String {
    n += 1
    return String(format: "n%d", n)
}



class Statement {
    private let pr: Protocol
    let stName: String
    let query: String
    var dest: String? = nil
    var columns: Columns? = nil
    init(pr: Protocol, query: String) {
        self.pr = pr
        stName = getUniqueName()
        self.query = query
    }
    func parse() throws {
        let fields = try pr.parse(statementName: "st", query: query, oids: [.Int8])
        columns = Columns(fields)
    }
    
    func bind(_ args: [Data?]) throws {
        dest = getUniqueName()
        try pr.bind(statementName: "st", dest: "dest", args: args)
    }
    func execute() throws {
        try pr.execute(dest: "dest")
    }
    
    func getRow() throws -> Row? {
        let msg = try pr.readMsgForce()
        switch msg {
        case let .DataRow(num: _, values: values):
            return Row(values, columns: columns!)
        case .CommandComplete:
            return nil
        default:
            throw PostgresErrors.ProtocolError(.UnexpectedResp(msg))
        }
        
    }
    
}
