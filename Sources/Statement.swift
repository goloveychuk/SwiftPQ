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




class Row {
    let values:[Data?]
    let columns: Columns
    init(_ values: [Data?], columns: Columns) {
        self.values = values
        self.columns = columns
    }
    subscript(ind: Int) -> Data? {
        return values[ind]
    }
    func val<T: PostgresTypeConvertible>(_ ind: Int) -> T? {
        guard let x = values[ind] else {
            return nil
        }
        
        return T(fromBytes: x) ////////check oid
    }
    func toStruct<T>() throws -> T {
        var dict = [String: Any]()
        for (ind, c) in columns.list.enumerated() {
            guard let d = values[ind] else {
                dict[c.name] = nil
                continue
            }
            switch c.typeOid {
            case .Int4:
                let v = Int(Int32(fromBytes: d))
                dict[c.name] = v
            case .Int2:
                let v = Int(Int16(fromBytes: d))
                dict[c.name] = v
            case .Int8:
                let v = Int(fromBytes: d)
                dict[c.name] = v
            case .Text:
                let v = String(fromBytes: d)
                dict[c.name] = v
            case .Bool:
                let v = Bool(fromBytes: d)
                dict[c.name] = v
            default:
                break
            }
        }
        return try construct(dictionary: dict)
    }

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
        
        let msgg = try pr.readMsg()
        guard let msg = msgg else {
            return nil
        }
        switch msg {
        case let .DataRow(num: _, values: values):
            return Row(values, columns: columns!)
         default:
            print("warn")
            return nil
        }
        
    }
    
}
