//
//  Row.swift
//  PurePostgres
//
//  Created by badim on 11/1/16.
//
//

import Foundation







public  class Row {
    let values:[Buffer?]
    let columns: Columns
    init(_ values: [Buffer?], columns: Columns) {
        self.values = values
        self.columns = columns
    }
    subscript(ind: Int) -> Buffer? {
        return values[ind]
    }
    func val<T: PostgresTypeConvertible>(_ ind: Int) -> T? {
        guard let x = values[ind] else {
            return nil
        }
        
        return T(psBuffer: x) ////////check oid
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
                v = Int(Int32(psBuffer: d))
                
            case .Int2:
                v = Int(Int16(psBuffer: d)) //todo 64/32 bit systems
            
            case .Int8:
                v = Int(psBuffer: d)
                
            case .Text, .VarChar, .FixedChar:
                v = String(psBuffer: d)
                
            case .Bool:
                v = Bool(psBuffer: d)
                
            case .Timestampz: //todo infinity
                v = Date(psBuffer: d)
                
                
            case .Timestamp:
                v = Date(psBuffer: d)
        
            case .Float4:
                v = Float64(Float32(psBuffer: d))
                
            case .Float8:
                v = Float64(psBuffer: d)
                
            case .Time:
                v = Time(psBuffer: d)
            case .Date:
                v = PgDate(psBuffer: d)
            case .Bytea:
                v = d
            case .TimeTz:
                v = Time(psBuffer: d)
            case .UUID:
                v = UUID(psBuffer: d)
            case .Money:
                v = Money(psBuffer: d)
            case .Json:
                let l = Array(d)
                v = "hz"
            case .Decimal:
                let l = Array(d)
                let n = Int16(psBuffer: d[0..<2])
                let weight = Int16(psBuffer: d[2..<4])
                let sign = UInt16(psBuffer: d[4..<6])
                let scale = Int16(psBuffer: d[6..<8])
                var ind = 8
                
                var digits = [Int16]()
            
                for i in 0..<Int(n) {
                    let digit = Int16(psBuffer: d[ind..<ind+2])
                    digits.append(digit)
                    ind+=2
                }
                print(l.count, l, n, weight, sign, scale, digits)
                v = "dsa"
                
            case .ArrInt8:
                v = PostgresArray<Int64>(psBuffer: d)
                
            default:
                let l = Array(d)
                assert(false, "bad type")
            }
            dict[c.name] = v
        }
        return dict
    }
    
}
