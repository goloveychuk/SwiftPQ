//
//  Row.swift
//  PurePostgres
//
//  Created by badim on 11/1/16.
//
//

import Foundation







public  class Row {
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
    var dict: [String: Any] {
        var dict = [String: Any]()
        for (ind, c) in columns.list.enumerated() {
            guard let d = values[ind] else {
                dict[c.name] = nil
                continue
            }
            var v : Any!
            switch c.typeOid {
            case .Int4:
                v = Int(Int32(fromBytes: d))
                
            case .Int2:
                v = Int(Int16(fromBytes: d)) //todo 64/32 bit systems
            
            case .Int8:
                v = Int(fromBytes: d)
                
            case .Text, .VarChar, .FixedChar:
                v = String(fromBytes: d)
                
            case .Bool:
                v = Bool(fromBytes: d)
                
            case .Timestampz: //todo infinity
                v = Date(fromBytes: d)
                
                
            case .Timestamp:
                v = Date(fromBytes: d)
        
            case .Float4:
                v = Float64(Float32(fromBytes: d))
                
            case .Float8:
                 v = Float64(fromBytes: d)
                
            case .Time:
                 v = Time(fromBytes: d)
            case .Date:
                v = PgDate(fromBytes: d)
            case .Bytea:
                v = d
            case .TimeTz:
                v = Time(fromBytes: d)
            case .UUID:
                v = UUID(fromBytes: d)
            case .Money:
                v = Money(fromBytes: d)
            case .Json:
                let l = Array(d)
                v = "hz"
            case .Decimal:
                let l = Array(d)
                let n = Int16(fromBytes: d.subdata(in: 0..<2))
                let weight = Int16(fromBytes: d.subdata(in: 2..<4))
                let sign = Int16(fromBytes: d.subdata(in: 4..<6))
                let scale = Int16(fromBytes: d.subdata(in: 6..<8))
                v = "dsa"
            default:
                assert(false, "bad type")
            }
            dict[c.name] = v
        }
        return dict
    }
    
}
