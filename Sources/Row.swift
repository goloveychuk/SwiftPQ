//
//  Row.swift
//  PurePostgres
//
//  Created by badim on 11/1/16.
//
//

import Foundation







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
    var dict: [String: Any] {
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
            case .Timestampz:
                let microseconds = Int64(fromBytes: d)
                let ti = TimeInterval(Double(microseconds)/1_000_000.0)
                let dc = DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2000)
                let sinceDate = Calendar.current.date(from: dc)!
                let d = Date(timeInterval:
                    ti, since: sinceDate)
                dict[c.name] = d
                
            case .Timestamp: //didn't tested
                let microseconds = Int64(fromBytes: d)
                let ti = TimeInterval(Double(microseconds)/1_000_000.0)
                let dc = DateComponents(timeZone: TimeZone.current, year: 2000)
                let sinceDate = Calendar.current.date(from: dc)!
                let d = Date(timeInterval:
                    ti, since: sinceDate)
                dict[c.name] = d
            
            default:
                assert(false, "bad type")
            }
        }
        return dict
    }
    
}
