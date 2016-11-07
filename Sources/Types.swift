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
    var toBuffer: Buffer { get }
    init(psBuffer : Buffer)
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

func readPrimitiveMemory<T>(psBuffer: Buffer) -> T {
    let v = UnsafeMutablePointer<T>.allocate(capacity: 1)
    v.withMemoryRebound(to: Byte.self, capacity: MemoryLayout<T>.size) { //todo read docs
        psBuffer.copyBytes(to: $0, count: MemoryLayout<T>.size)
    }
    return v.pointee
}

func getPrimitiveBuffer<T>(_ v: UnsafeMutablePointer<T>) -> Buffer {
    return v.withMemoryRebound(to: Byte.self, capacity: MemoryLayout<T>.size) {
        let pb = UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size)
        return Buffer(pb)
    }
    
}

extension IntegerPostgresType {
    public var toBuffer: Buffer {
        var newV = self.bigEndian
        return getPrimitiveBuffer(&newV)
    }
    public init(psBuffer buffer: Buffer) {
        let v: T = readPrimitiveMemory(psBuffer: buffer)
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
extension UInt16: IntegerPostgresType {
    public  var oid: Oid { return Oid.Int2 }
    public static var oid: Oid { return Oid.Int2 }
}

extension String: PostgresTypeConvertible {
    public init(psBuffer buffer: Buffer) {
        self.init(bytes: buffer, encoding: String.Encoding.utf8)!
//        self = try! String(psBuffer buffer)
    }
    public  var oid: Oid { return Oid.Text }
    public var toBuffer: Buffer {
        return Buffer(self)
    }
}

extension Bool: PostgresTypeConvertible {
    public init(psBuffer buffer: Buffer) {
        self.init(buffer[0]==1)
    }
    public  var oid: Oid { return Oid.Bool }
    public var toBuffer: Buffer {
        var byte: Byte = 0
        if self {
            byte = 1
        }
        return Buffer([byte])
    }
}

extension Float64: PostgresTypeConvertible {
    public  var oid: Oid { return Oid.Float8 }
    public init(psBuffer buffer: Buffer) {
        var v: UInt64 = readPrimitiveMemory(psBuffer: buffer)
        v = UInt64(bigEndian: v)
        self.init(bitPattern: v)
    }
    public var toBuffer: Buffer {
        var v = self.bitPattern.bigEndian
        return getPrimitiveBuffer(&v)
    }
}

extension Float32: PostgresTypeConvertible {
    public  var oid: Oid { return Oid.Float4 }
    public init(psBuffer buffer: Buffer) {
        var v: UInt32 = readPrimitiveMemory(psBuffer: buffer)
        v = UInt32(bigEndian: v)
        self.init(bitPattern: v)
    }
    public var toBuffer: Buffer {
        var v = self.bitPattern.bigEndian
        return getPrimitiveBuffer(&v)
    }
}

extension PgDate: PostgresTypeConvertible {
    public  var oid: Oid { return Oid.Date}
    public init(psBuffer buffer: Buffer) {
        let days = Int32(psBuffer: buffer)
        let milD = DateComponents(calendar: Calendar.current, year: 2000).date!//shitty api
        
        let d = Calendar.current.date(byAdding: .day, value: Int(days), to: milD)!
        let dc = Calendar.current.dateComponents([.year, .month, .day], from: d)
        self.init(year: dc.year!, month: dc.month!, day: dc.day!)
    }
    public var toBuffer: Buffer {
        let dc = Calendar.current.dateComponents([Calendar.Component.day], from: DateComponents(year: 2000), to:  DateComponents(year: year, month: month, day: day))
        let days = Int32(dc.day!)
        return days.toBuffer
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
    public init(psBuffer buffer: Buffer) {
        if buffer.count == 12 {
            let tD = buffer[0..<8]
            //let tzD = Buffer[8..<12] //todo timezones. Timezones are everywhere
            let microseconds = Int64(psBuffer: tD)
            self.init(Int(microseconds))
            
        } else {
            let microseconds = Int64(psBuffer: buffer)
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
    public var toBuffer: Buffer {
        var seconds = Int64(second)
        
        seconds += 60 * minute
        
        seconds += 3600 * hour
        
        let microseconds = (seconds * 1_000_000) + microsecond
        
        var d = microseconds.toBuffer
        if let _ = tz {
            let tzd = Int32(0)
            d.append(tzd.toBuffer)
        }
        return d
        
    }
}
let MILLENIUM_DC = DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2000) //check date
let MILLENIUM_DATE = Calendar.autoupdatingCurrent.date(from: MILLENIUM_DC)!

extension Date: PostgresTypeConvertible { //deal with timezones
    public var toBuffer: Buffer {
        let ti = self.timeIntervalSince(MILLENIUM_DATE)
        let microseconds = Int64(ti * 1_000_000)
        return microseconds.toBuffer
    }
    public  var oid: Oid { return Oid.Timestamp }

    public init(psBuffer buffer: Buffer) {
        let microseconds = Int64(psBuffer: buffer)
        let ti = TimeInterval(Double(microseconds)/1_000_000.0)
        
        self.init(timeInterval: ti, since: MILLENIUM_DATE)
    }
}
extension UUID: PostgresTypeConvertible {
    public var toBuffer: Buffer {
        let u = self.uuid
        return Buffer([u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7, u.8, u.9, u.10, u.11, u.12, u.13, u.14, u.15])
    }
    public  var oid: Oid { return Oid.UUID }
    
    public init(psBuffer b: Buffer) {
        let u = Darwin.uuid_t(b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15])
        self.init(uuid: u)
    }
    
}

extension Buffer: PostgresTypeConvertible {
    public var toBuffer: Buffer {
        return self
    }
    public  var oid: Oid { return Oid.Bytea }
    
    public init(psBuffer buffer: Buffer) {
        self = buffer
    }
}


public struct Money: PostgresTypeConvertible {
    let base, frac: Int
    public var toBuffer: Buffer {
        let v = Int64(base * 100 + frac)
        return v.toBuffer
    }
    public  var oid: Oid { return Oid.Money }
    
    public init(psBuffer buffer: Buffer) {
        let v = Int64(psBuffer: buffer)
        let vv = Int(v)
        self.init(base: (vv / 100), frac: (vv % 100))
    }
    public init(base: Int, frac: Int) {
        self.base = base
        self.frac = frac
    }
}

struct CustomType: PostgresTypeConvertible {
    let buffer: Buffer
    let oid: Oid
    public init(_ oid: Oid, buffer: Buffer) {
        self.buffer = buffer
        self.oid = oid
    }
    var toBuffer: Buffer { return buffer }
    public init(psBuffer buffer: Buffer) {
        self.init(Oid.ArrInt8, buffer: buffer )
    }
}

///extension Array where Element: PostgresTypeConvertible {
//    public var toBuffer: Buffer {
//        return Buffer()
//    }
//    public var oid: Oid { return Oid.Bytea }
//    public init(psBuffer Buffer: Buffer) {
//        self.init()
//    }
//} ///////////////////////////////////////////////////////////don't work

//extension Array: PostgresTypeConvertible{}


public struct PostgresArray<T: PostgresArrayConvertible>: PostgresTypeConvertible {
    let buffer: Array<T>
    public var toBuffer: Buffer {
        let dimension = Int32(1).toBuffer
        let notNull = Int32(0).toBuffer
        let typeOid = T.oid.rawValue.toBuffer
        let length = Int32(self.buffer.count).toBuffer
        let startingDimInd = Int32(0).toBuffer
        var buffer = Buffer(dimension.bytes+notNull.bytes+typeOid.bytes+length.bytes+startingDimInd.bytes)
        
        for i in self.buffer {
            let d = i.toBuffer
            let len_t = Int32(d.count).toBuffer
            buffer.append(len_t)
            buffer.append(d)
        }
        print(buffer)
        return buffer
    }
    public  var oid: Oid {
        switch T.oid {
        case .Int8:
            return .ArrInt8
        default:
            return .Bytea
        }
    }
    public init(psBuffer d: Buffer) {
        let dimension = Int32(psBuffer: d[0..<4])
        let notNull = Int32(psBuffer: d[4..<8])
        let typeOid = Int32(psBuffer: d[8..<12])
        let length = Int32(psBuffer: d[12..<16])
        let startingDimInd = Int32(psBuffer: d[16..<20])
        var buffer = Array<T>()
        var ind = 20
        for i in 0..<Int(length) {
            let t_len = Int(Int32(psBuffer: d[ind..<ind+4]))
            ind += 4
            let el = T(psBuffer: d[ind..<ind+t_len])
            ind += t_len
            buffer.append(el)
        }
        self.buffer = buffer
        

    }
  }

extension PostgresArray: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: T...) {
        self.buffer = elements
    }
}

extension Decimal {
    
}

// http://doxygen.postgresql.org/backend_2utils_2adt_2numeric_8c.html#a57a8f8ab552bae24926d252180956958
//extension Decimal: PostgresTypeConvertible


