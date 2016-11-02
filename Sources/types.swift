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
    case Json = 114
    //case Xml = 142
    case Float4 = 700
    case Float8 = 701
    
    case FixedChar = 1042
    case VarChar = 1043
    
    case Decimal = 1700
    case Money = 790
    
    
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
        var v: UInt64 = readPrimitiveMemory(data: fromBytes)
        v = UInt64(bigEndian: v)
        self.init(bitPattern: v)
    }
    public var toBytes: Data {
        var v = self.bitPattern.bigEndian
        return getPrimitiveBytes(&v)
    }
}

extension Float32: PostgresTypeConvertible {
    public var oid: Oid { return Oid.Float4 }
    public init(fromBytes: Data) {
        var v: UInt32 = readPrimitiveMemory(data: fromBytes)
        v = UInt32(bigEndian: v)
        self.init(bitPattern: v)
    }
    public var toBytes: Data {
        var v = self.bitPattern.bigEndian
        return getPrimitiveBytes(&v)
    }
}

extension PgDate: PostgresTypeConvertible {
    public var oid: Oid { return Oid.Date}
    public init(fromBytes: Data) {
        let days = Int32(fromBytes: fromBytes)
        let milD = DateComponents(calendar: Calendar.current, year: 2000).date!//shitty api
        
        let d = Calendar.current.date(byAdding: .day, value: Int(days), to: milD)!
        let dc = Calendar.current.dateComponents([.year, .month, .day], from: d)
        self.init(year: dc.year!, month: dc.month!, day: dc.day!)
    }
    public var toBytes: Data {
        let dc = Calendar.current.dateComponents([Calendar.Component.day], from: DateComponents(year: 2000), to:  DateComponents(year: year, month: month, day: day))
        let days = Int32(dc.day!)
        return days.toBytes
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
        if fromBytes.count == 12 {
            let tD = fromBytes.subdata(in: 0..<8)
            //let tzD = fromBytes.subdata(in: 8..<12) //todo timezones. Timezones are everywhere
            let microseconds = Int64(fromBytes: tD)
            self.init(Int(microseconds))
            
        } else {
            let microseconds = Int64(fromBytes: fromBytes)
            self.init(Int(microseconds))
        }
    }
    init(_ microseconds: Int) {
        let seconds = microseconds / 1_000_000
        let hour = seconds / 3600
        let minute = (seconds % 3600) / 60
        let second = seconds % 60
        let microsecond = microseconds % 1_000_000
        self.init(hour: hour, minute: minute, second: second, microsecond: microsecond, tz: nil)
    }
    public var toBytes: Data {
        var seconds = Int64(second)
        
        seconds += 60 * minute
        
        seconds += 3600 * hour
        
        let microseconds = (seconds * 1_000_000) + microsecond
        
        var d = microseconds.toBytes
        if let _ = tz {
            let tzd = Int32(0)
            d.append(tzd.toBytes)
        }
        return d
        
    }
}
let MILLENIUM_DC = DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2000) //check date
let MILLENIUM_DATE = Calendar.autoupdatingCurrent.date(from: MILLENIUM_DC)!

extension Date: PostgresTypeConvertible { //deal with timezones
    public var toBytes: Data {
        let ti = self.timeIntervalSince(MILLENIUM_DATE)
        let microseconds = Int64(ti * 1_000_000)
        return microseconds.toBytes
    }
    public var oid: Oid { return Oid.Timestamp }

    public init(fromBytes: Data) {
        let microseconds = Int64(fromBytes: fromBytes)
        let ti = TimeInterval(Double(microseconds)/1_000_000.0)
        
        self.init(timeInterval: ti, since: MILLENIUM_DATE)
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






