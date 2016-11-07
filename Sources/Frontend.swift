//
//  Frontend.swift
//  PurePostgres
//
//  Created by badim on 10/29/16.
//
//

import Foundation





enum FrontendMessageTypes: UnicodeScalar {
    case PasswordMessage = "p"
    case Parse = "P"
    case Describe = "D"
    case Sync = "S"
    case Execute = "E"
    case Bind = "B"
    case Flush = "H"
}

let PROTOCOL_VERSION: Int32 = 196608


enum Formats: Int16 {
    case Binary = 1
    case Text = 0
}


 enum FrontendMessages {
    case PasswordMessage(password: String)
    case StartupMessage(user: String, database: String?)
    case Parse(destination: String, query: String, numberOfParameters: Int16, argsOids: [Int32])
    
    case Describe(name: String)
    case Sync
    case Execute(name: String, maxRowNums: Int32)
    case Bind(destinationName : String, statementName: String, numberOfParametersFormatCodes: Int16, paramsFormats: [Formats], numberOfParameterValues: Int16, parameters: [(length: Int32, data: Buffer?)],
        numberOfResultsFormatCodes: Int16, resultFormats: [Formats]
    )
    case Flush
    
    func buf() -> WriteBuffer {
        switch self {
        case let .StartupMessage(user: user, database: database):
            var msg = WriteBuffer(nil)
            msg.addInt32(PROTOCOL_VERSION)
            msg.addString("user")
            msg.addString(user)
            if let database = database {
                msg.addString("database")
                msg.addString(database)
            }
            msg.addNull()
            return msg
            
        case let .PasswordMessage(password: password):
            var msg = WriteBuffer(.PasswordMessage)
            msg.addString(password)
            return msg
            
        case let .Parse(destination: dest, query: q, numberOfParameters: num, argsOids: oids):
            var msg = WriteBuffer(.Parse)
            msg.addString(dest)
            msg.addString(q)
            msg.addInt16(num)
            for oid in oids {
                msg.addInt32(oid)
            }
            return msg
            
        case let .Describe(name: name):
            var msg = WriteBuffer(.Describe)
            msg.addByte1(Byte(ascii: "S"))
            msg.addString(name)
            return msg
        case .Sync:
            let msg = WriteBuffer(.Sync)
            return msg
        case let .Execute(name: name, maxRowNums: mx):
            var msg = WriteBuffer(.Execute)
            msg.addString(name)
            msg.addInt32(mx)
            return msg
        case let .Bind(destinationName: dest, statementName: st,
        numberOfParametersFormatCodes: numParamCodes, paramsFormats: paramsFormats, numberOfParameterValues: numParamVals, parameters: params,
        numberOfResultsFormatCodes: numResCodes, resultFormats: resFormats):
            var msg = WriteBuffer(.Bind)
            msg.addString(dest)
            msg.addString(st)
            msg.addInt16(numParamCodes)
            for i in paramsFormats {
                msg.addInt16(i.rawValue)
            }
            msg.addInt16(numParamVals)
            for i in params {
                msg.addInt32(i.length)
                if i.length != -1 {
                    msg.addBuffer(i.data!)
                }
            }
            msg.addInt16(numResCodes)
            for i in resFormats {
                msg.addInt16(i.rawValue)
            }
            return msg
        case .Flush:
            let msg = WriteBuffer(.Flush)
            return msg
        }
    }
}
