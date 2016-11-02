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
    //case Bytea = 17
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
}




public protocol PostgresTypeConvertible {
    
    var toBytes: Data { get }
    init(fromBytes : Data)
    var oid: Oid { get }
}

public protocol NumericalPostgresType: PostgresTypeConvertible {
    associatedtype T: Integer
    var bigEndian: T { get }
    init(bigEndian: T)
}

extension NumericalPostgresType {
    public var toBytes: Data {
        var newV = self.bigEndian
        return Data(bytes: &newV, count: MemoryLayout<T>.size)
    }
    public init(fromBytes: Data) {
        
        var v: T = 0
        withUnsafeMutablePointer(to: &v) {
           $0.withMemoryRebound(to: Byte.self, capacity: MemoryLayout<T>.size) {
            fromBytes.copyBytes(to: $0, count: MemoryLayout<T>.size)
         }
        }
        self.init(bigEndian: v)
    }
}

extension Int32: NumericalPostgresType {
    public var oid: Oid { return Oid.Int4 }
}
extension Int64: NumericalPostgresType {
    public var oid: Oid { return Oid.Int8 }
}

extension Int: NumericalPostgresType {
    public var oid: Oid { return Oid.Int8 }
}

extension Int16: NumericalPostgresType {
    public var oid: Oid { return Oid.Int2 }
}

extension String {
    public init?(fromBytes: Data) {
        self.init(data: fromBytes, encoding: String.Encoding.utf8)
    }
}

extension Bool {
    public init(fromBytes: Data) {
        self.init(fromBytes[0]==1)
    }
}

