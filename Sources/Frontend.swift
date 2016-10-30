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
    case Bind(destinationName : String, statementName: String, numberOfParametersFormatCodes: Int16, paramsFormats: [Formats], numberOfParameterValues: Int16, parameters: [(length: Int32, data: Data?)],
        numberOfResultsFormatCodes: Int16, resultFormats: [Formats]
    )
    case Flush
    
    func buf() -> Data {
        let msg = Buffer()
        
        switch self {
        case let .StartupMessage(user: user, database: database):
            msg.addLen()
            msg.addInt32(PROTOCOL_VERSION)
            msg.addString("user")
            msg.addString(user)
            if let database = database {
                msg.addString("database")
                msg.addString(database)
            }
            msg.addNull()
            
        case let .PasswordMessage(password: password):
            msg.addType(FrontendMessageTypes.PasswordMessage)
            msg.addLen()
            msg.addString(password)
            
        case let .Parse(destination: dest, query: q, numberOfParameters: num, argsOids: oids):
            msg.addType(FrontendMessageTypes.Parse)
            msg.addLen()
            msg.addString(dest)
            msg.addString(q)
            msg.addInt16(num)
            for oid in oids {
                msg.addInt32(oid)
            }
        case let .Describe(name: name):
            msg.addType(FrontendMessageTypes.Describe)
            msg.addLen()
            msg.addByte1(Byte(ascii: "S"))
            msg.addString(name)
        case .Sync:
            msg.addType(FrontendMessageTypes.Sync)
            msg.addLen()
        case let .Execute(name: name, maxRowNums: mx):
            msg.addType(FrontendMessageTypes.Execute)
            msg.addLen()
            msg.addString(name)
            msg.addInt32(mx)
        case let .Bind(destinationName: dest, statementName: st,
        numberOfParametersFormatCodes: numParamCodes, paramsFormats: paramsFormats, numberOfParameterValues: numParamVals, parameters: params,
        numberOfResultsFormatCodes: numResCodes, resultFormats: resFormats):
            msg.addType(FrontendMessageTypes.Bind)
            msg.addLen()
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
                    msg.addData(i.data!)
                }
            }
            msg.addInt16(numResCodes)
            for i in resFormats {
                msg.addInt16(i.rawValue)
            }
        case .Flush:
            msg.addType(FrontendMessageTypes.Flush)
            msg.addLen()
        }
        return msg.buf()
    }
}
