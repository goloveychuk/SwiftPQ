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



public class Statement {
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
    public  func parse(_ args: [PostgresTypeConvertible?]) throws {
        let oids = args.map { $0?.oid.rawValue ?? 0 }
        let fields = try pr.parse(statementName: "", query: query, oids: oids)
        columns = Columns(fields)
    }
    
   public  func bind(_ args: [PostgresTypeConvertible?]) throws {
    let args = args.map { $0?.toBytes } //todo make lazy
        dest = getUniqueName()
        try pr.bind(statementName: "", dest: "", args: args)
    }
   public  func execute() throws {
        try pr.execute(dest: "")
    }
    
   public  func getRow() throws -> Row? {
        let msg = try pr.readMsgForce()
        switch msg {
        case let .DataRow(num: _, values: values):
            return Row(values, columns: columns!)
        case .CommandComplete:
            let msg = try pr.readMsgForce()
            switch msg {
            case .ReadyForQuery:
                return nil
            default:
                throw PostgresErrors.ProtocolError(.UnexpectedResp(msg))
            }
        default:
            throw PostgresErrors.ProtocolError(.UnexpectedResp(msg))
        }
    }
    
}
