//
//  types.swift
//  PurePostgres
//
//  Created by badim on 10/30/16.
//
//

import Foundation




//https://github.com/postgres/postgres/blob/master/src/include/catalog/pg_type.h
enum Oid: Int32 {
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
    case Timestampz = 1184
}



protocol PostgresTypeConvertable {
    
}

extension Int: PostgresTypeConvertable {
    
}



protocol PostgresTypeConvertible {
    
    var toBytes: Data { get }
    init(fromBytes : Data)
}

protocol NumericalPostgresType: PostgresTypeConvertible {
    associatedtype T: Integer
    var bigEndian: T { get }
    init(bigEndian: T)
}

extension NumericalPostgresType {
    var toBytes: Data {
        var newV = self.bigEndian
        return Data(bytes: &newV, count: MemoryLayout<T>.size)
    }
    init(fromBytes: Data) {
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
    
}


extension Int: NumericalPostgresType {
    
}

extension Int16: NumericalPostgresType {
    
}



