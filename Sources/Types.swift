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

public protocol PostgresArrayConvertible: PostgresTypeConvertible {
    static var oid: Oid { get }
}

public protocol IntegerPostgresType: PostgresArrayConvertible {
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
    public  var oid: Oid { return Oid.Int4 }
    public static var oid: Oid { return Oid.Int4 }
}
extension Int64: IntegerPostgresType {
    public  var oid: Oid { return Oid.Int8 }
    public static var oid: Oid { return Oid.Int8 }
}

extension Int: IntegerPostgresType {
    public  var oid: Oid { return Oid.Int8 }
    public static var oid: Oid { return Oid.Int8 }
}

extension Int16: IntegerPostgresType {
    public  var oid: Oid { return Oid.Int2 }
    public static var oid: Oid { return Oid.Int2 }
}

extension String: PostgresTypeConvertible {
    public init(fromBytes: Data) {
        self.init(data: fromBytes, encoding: String.Encoding.utf8)!
    }
    public  var oid: Oid { return Oid.Text }
    public var toBytes: Data {
        return self.data(using: String.Encoding.utf8)!
    }
}

extension Bool: PostgresTypeConvertible {
    public init(fromBytes: Data) {
        self.init(fromBytes[0]==1)
    }
    public  var oid: Oid { return Oid.Bool }
    public var toBytes: Data {
        var byte: Byte = 0
        if self {
            byte = 1
        }
        return Data(bytes: [byte])
    }
}

extension Float64: PostgresTypeConvertible {
    public  var oid: Oid { return Oid.Float8 }
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
    public  var oid: Oid { return Oid.Float4 }
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
    public  var oid: Oid { return Oid.Date}
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
    public  var oid: Oid {
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
    public  var oid: Oid { return Oid.Timestamp }

    public init(fromBytes: Data) {
        let microseconds = Int64(fromBytes: fromBytes)
        let ti = TimeInterval(Double(microseconds)/1_000_000.0)
        
        self.init(timeInterval: ti, since: MILLENIUM_DATE)
    }
}
extension UUID: PostgresTypeConvertible {
    public var toBytes: Data {
        let u = self.uuid
        return Data(bytes: [u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7, u.8, u.9, u.10, u.11, u.12, u.13, u.14, u.15])
    }
    public  var oid: Oid { return Oid.UUID }
    
    public init(fromBytes b: Data) {
        let u = Darwin.uuid_t(b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15])
        self.init(uuid: u)
    }
    
}

extension Data: PostgresTypeConvertible {
    public var toBytes: Data {
        return self
    }
    public  var oid: Oid { return Oid.Bytea }
    
    public init(fromBytes: Data) {
        self.init(fromBytes)
    }
}


public struct Money: PostgresTypeConvertible {
    let base, frac: Int
    public var toBytes: Data {
        let v = Int64(base * 100 + frac)
        return v.toBytes
    }
    public  var oid: Oid { return Oid.Money }
    
    public init(fromBytes: Data) {
        let v = Int64(fromBytes: fromBytes)
        let vv = Int(v)
        self.init(base: (vv / 100), frac: (vv % 100))
    }
    public init(base: Int, frac: Int) {
        self.base = base
        self.frac = frac
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

///extension Array where Element: PostgresTypeConvertible {
//    public var toBytes: Data {
//        return Data()
//    }
//    public var oid: Oid { return Oid.Bytea }
//    public init(fromBytes: Data) {
//        self.init()
//    }
//} ///////////////////////////////////////////////////////////don't work

//extension Array: PostgresTypeConvertible{}


public struct PostgresArray<T: PostgresArrayConvertible>: PostgresTypeConvertible {
    let data: Array<T>
    public var toBytes: Data {
        let dimension = Int32(1).toBytes
        let notNull = Int32(0).toBytes
        let typeOid = T.oid.rawValue.toBytes
        let length = Int32(self.data.count).toBytes
        let startingDimInd = Int32(0).toBytes
        var data = dimension+notNull+typeOid+length+startingDimInd
        
        for i in self.data {
            let d = i.toBytes
            let len_t = Int32(d.count).toBytes
            data.append(len_t+d)
        }
        print(data)
        return data
    }
    public  var oid: Oid {
        switch T.oid {
        case .Int8:
            return .ArrInt8
        default:
            return .Bytea
        }
    }
    public init(fromBytes d: Data) {
        let dimension = Int32(fromBytes: d.subdata(in: 0..<4))
        let notNull = Int32(fromBytes: d.subdata(in: 4..<8))
        let typeOid = Int32(fromBytes: d.subdata(in: 8..<12))
        let length = Int32(fromBytes: d.subdata(in: 12..<16))
        let startingDimInd = Int32(fromBytes: d.subdata(in: 16..<20))
        var data = Array<T>()
        var ind = 20
        for i in 0..<Int(length) {
            let t_len = Int(Int32(fromBytes: d.subdata(in: ind..<ind+4)))
            ind += 4
            let el = T(fromBytes: d.subdata(in: ind..<ind+t_len))
            ind += t_len
            data.append(el)
        }
        self.data = data
        

    }
  }

extension PostgresArray: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: T...) {
        self.data = elements
    }
}

// http://doxygen.postgresql.org/backend_2utils_2adt_2numeric_8c.html#a57a8f8ab552bae24926d252180956958
//extension Decimal: PostgresTypeConvertible

