//
//  types.swift
//  PurePostgres
//
//  Created by badim on 10/30/16.
//
//

import Foundation




//https://github.com/postgres/postgres/blob/master/src/include/catalog/pg_type.h
public enum Oid: Int32 {
    case Bool = 16
    case Bytea = 17
    case Char = 18
    case Int8 = 20
    case Int2 = 21
    case Int4 = 23
    case Text = 25
    //case Oid = 26
    //case Json = 114
    //case Xml = 142
    case Float4 = 700
    case Float8 = 701
    
    case VarChar = 1043
    
    case Date = 1082
    case Time = 1083
    case TimeTz = 1266
    case Timestamp = 1114
    case Timestampz = 1184
    case Interval = 1186
    case UUID = 2950
    
    ///arrays
    case ArrInt8 =  1016
}

public struct Time {
    let hour, minute, second, microsecond: Int
    let tz: Int?
}
public struct PgDate {
    let year, month, day: Int
}


public protocol PostgresTypeConvertible {
    var toBytes: Data { get }
    init(fromBytes : Data)
    var oid: Oid { get }
}

public protocol IntegerPostgresType: PostgresTypeConvertible {
    associatedtype T: Integer
    var bigEndian: T { get }
    init(bigEndian: T)
}

func readPrimitiveMemory<T>(data: Data) -> T {
    let v = UnsafeMutablePointer<T>.allocate(capacity: 1)
    v.withMemoryRebound(to: Byte.self, capacity: MemoryLayout<T>.size) { //todo read docs
        data.copyBytes(to: $0, count: MemoryLayout<T>.size)
    }
    return v.pointee
}

func getPrimitiveBytes<T>(_ v: UnsafeMutablePointer<T>) -> Data {
    return Data(bytes: v, count: MemoryLayout<T>.size)
}

extension IntegerPostgresType {
    public var toBytes: Data {
        var newV = self.bigEndian
        return getPrimitiveBytes(&newV)
    }
    public init(fromBytes: Data) {
        let v: T = readPrimitiveMemory(data: fromBytes)
        self.init(bigEndian: v)
    }
}

extension Int32: IntegerPostgresType {
    public var oid: Oid { return Oid.Int4 }
}
extension Int64: IntegerPostgresType {
    public var oid: Oid { return Oid.Int8 }
}

extension Int: IntegerPostgresType {
    public var oid: Oid { return Oid.Int8 }
}

extension Int16: IntegerPostgresType {
    public var oid: Oid { return Oid.Int2 }
}

extension String: PostgresTypeConvertible {
    public init(fromBytes: Data) {
        self.init(data: fromBytes, encoding: String.Encoding.utf8)!
    }
    public var oid: Oid { return Oid.Text }
    public var toBytes: Data {
        return self.data(using: String.Encoding.utf8)!
    }
}

extension Bool: PostgresTypeConvertible {
    public init(fromBytes: Data) {
        self.init(fromBytes[0]==1)
    }
    public var oid: Oid { return Oid.Bool }
    public var toBytes: Data {
        var byte: Byte = 0
        if self {
            byte = 1
        }
        return Data(bytes: [byte])
    }
}

extension Float64: PostgresTypeConvertible {
    public var oid: Oid { return Oid.Float8 }
    public init(fromBytes: Data) {
        let v: Float64 = readPrimitiveMemory(data: fromBytes)
        self.init(v)
    }
    public var toBytes: Data {
        var v = self
        return getPrimitiveBytes(&v)
    }
}

extension Float32: PostgresTypeConvertible {
    public var oid: Oid { return Oid.Float4 }
    public init(fromBytes: Data) {
        let v: Float32 = readPrimitiveMemory(data: fromBytes)
        self.init(v)
    }
    public var toBytes: Data {
        var v = self
        return getPrimitiveBytes(&v)
    }
}

extension PgDate: PostgresTypeConvertible {
    public var oid: Oid { return Oid.Date}
    public init(fromBytes: Data) {
        self.init(year: 3112, month:3, day: 1)
    }
    public var toBytes: Data {
        let time: Int32 = 312
        return time.toBytes
    }
}

extension Time: PostgresTypeConvertible {
    public var oid: Oid {
        if tz != nil {
            return Oid.TimeTz
        } else {
            return Oid.Time
        }
    }
    public init(fromBytes: Data) {
        self.init(hour: 12, minute:3, second: 1, microsecond: 31213, tz: nil)
    }
    public var toBytes: Data {
        if let tz = tz {
            let time: Int64 = 312
            var d = time.toBytes
            d.append(1)
            d.append(1)
            return d
        
        } else {
            let time: Int64 = 312
            return time.toBytes
        }
        
    }
}

extension Date: PostgresTypeConvertible {
    public var toBytes: Data {
        let time: Int64 = 312
        return time.toBytes
    }
    public var oid: Oid { return Oid.Timestamp }

    public init(fromBytes: Data) {
        let microseconds = Int64(fromBytes: fromBytes)
        let ti = TimeInterval(Double(microseconds)/1_000_000.0)
        let dc = DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2000)
        let sinceDate = Calendar.current.date(from: dc)!
        self.init(timeInterval: ti, since: sinceDate)
    }
}
extension UUID: PostgresTypeConvertible {
    public var toBytes: Data {
        return self.uuidString.toBytes
    }
    public var oid: Oid { return Oid.UUID }
    
    public init(fromBytes: Data) {
        self.init()
    }
    
}

extension Data: PostgresTypeConvertible {
    public var toBytes: Data {
        return self
    }
    public var oid: Oid { return Oid.Bytea }
    
    public init(fromBytes: Data) {
        self.init(fromBytes)
    }
}




struct CustomType: PostgresTypeConvertible {
    let data: Data
    let oid: Oid
    public init(_ oid: Oid, data: Data) {
        self.data = data
        self.oid = oid
    }
    var toBytes: Data { return data }
    public init(fromBytes: Data) {
        self.init(Oid.ArrInt8, data: fromBytes )
    }
}






