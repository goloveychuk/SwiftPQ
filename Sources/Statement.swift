//
//  Statement.swift
//  PurePostgres
//
//  Created by badim on 10/30/16.
//
//

import Foundation

var n = 0

func getUniqueName() -> String {
    n += 1
    return String(format: "n%d", n)
}

class Row {
    let values:[(Int32, Data?)]
    init(_ values: [(Int32, Data?)]) {
        self.values = values
    }
}

class Statement {
    private let pr: Protocol
    let stName: String
    let query: String
    var dest: String? = nil
    init(pr: Protocol, query: String) {
        self.pr = pr
        stName = getUniqueName()
        self.query = query
    }
    func parse() throws {
        try pr.parse(statementName: "st", query: query, oids: [.Int8])
    }
    
    func bind(_ args: [Data?]) throws {
        dest = getUniqueName()
        try pr.bind(statementName: "st", dest: "dest", args: args)
    }
    func execute() throws {
        try pr.execute(dest: "dest")
    }
    
    func getRow() throws -> Row? {
        
        let msgg = try pr.readMsg()
        guard let msg = msgg else {
            return nil
        }
        switch msg {
        case let .DataRow(num: _, values: values):
            return Row(values)
         default:
            print("warn")
            return nil
        }
        
    }
    
}