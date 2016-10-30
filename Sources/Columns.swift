//
//  Columns.swift
//  PurePostgres
//
//  Created by badim on 10/30/16.
//
//

import Foundation


typealias Column = (name: String, size: Int, typeOid: Oid)

struct Columns {
    var list: [Column]
    init(_ fields: [Field]) {
        list = fields.map { Column(name: $0.name, size: Int($0.typeSize),                            typeOid: Oid(rawValue: $0.typeOid)!) }
    }
    subscript (ind: Int) -> Column {
        return list[ind]
    }
}
