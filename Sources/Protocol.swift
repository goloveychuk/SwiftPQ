//
//  Protocol.swift
//  PurePostgres
//
//  Created by badim on 10/28/16.
//
//

import Foundation
import CryptoSwift

public typealias Byte = UInt8

enum ProtocolErrors {
    case UnexpectedResp(BackendMessages)
    case Other(String)
}

struct ErrorDescription: CustomDebugStringConvertible {
    let pairs: [(Byte, String)]
    init(_ pairs: [(Byte, String)]) {
        self.pairs = pairs
    }
    public var debugDescription: String {
        return pairs.debugDescription
    }
}

enum PostgresErrors: Error {
    case ProtocolError(ProtocolErrors)
    case AuthError(ErrorDescription)
    case ParseError(ErrorDescription)
    case BindError(ErrorDescription)
    case ExecuteError(ErrorDescription)
}





class Protocol {
    let socket: Socket
    var buffer: ReadBuffer
    init(socket: Socket) {
        self.socket = socket
        self.buffer = ReadBuffer()
    }
    func readMsgForce() throws -> BackendMessages {
        var msgType = try buffer.unpack()
        if msgType == nil {
            let d = try socket.read()
            buffer.add(d)
            msgType = try buffer.unpack()
        }
        
        let msg = try! BackendMessages(msgType: msgType!, buf: buffer)
        //print("debug, msg", msg)
        return msg
    }
    
    func readMsg() throws -> BackendMessages?  {
        guard !buffer.isEmpty else {
            return nil
        }
        return try readMsgForce()
    }
}
///async messages
extension Protocol {
    func readAsync() {
      
    }
}

//////////startup
extension Protocol {
    func startup(user: String, database: String, password: String) throws {
        let msg = FrontendMessages.StartupMessage(user: user, database: database)
        try socket.write(msg)
        try socket.flush()
        let resp = try readMsgForce()
        switch  resp {
        case .AuthenticationOk:
            break
        case let .AuthenticationMD5Password(salt: salt):
            try authMd5(user: user, password: password, salt: salt)
        case .AuthenticationCleartextPassword:
            try authPlain(password: password)
        default:
            throw PostgresErrors.ProtocolError(.UnexpectedResp(resp))
        }
        while let resp = try readMsg() {
            switch resp {
            case .ParameterStatus:
                break
            case .BackendKeyData:
                break
            case .ReadyForQuery:
                return
            default:
                throw PostgresErrors.ProtocolError(.UnexpectedResp(resp))
            }
        }
        
    }

}



//////////////auth
extension Protocol {
    func authPlain(password: String) throws {
        let msg = FrontendMessages.PasswordMessage(password: password)
        try socket.write(msg)
        try socket.flush()
        let resp = try readMsgForce()
        switch resp {
        case .AuthenticationOk:
            return
        case let .ErrorResponse(pairs: pairs):
            throw PostgresErrors.AuthError(ErrorDescription(pairs))
        default:
            throw PostgresErrors.ProtocolError(.UnexpectedResp(resp))
        }
    }
    func authMd5(user: String, password: String, salt: Buffer) throws{
        let c1 = (password + user).md5()
        let pass = "md5" + (c1.utf8+salt.bytes).md5().toHexString()
        let msg = FrontendMessages.PasswordMessage(password: pass)
        try socket.write(msg)
        try socket.flush()
        
        let resp = try readMsgForce()
        switch resp {
        case .AuthenticationOk:
            return
        case let .ErrorResponse(pairs: pairs):
            throw PostgresErrors.AuthError(ErrorDescription(pairs))
        default:
            throw PostgresErrors.ProtocolError(.UnexpectedResp(resp))
        }

    }
}



/////queries
extension Protocol {
    func parse(statementName: String, query: String, oids: [Int32]) throws -> [Field]? {
        
        let msg = FrontendMessages.Parse(destination: statementName, query: query, numberOfParameters: Int16(oids.count), argsOids: oids )
        
        try socket.write(msg, .Describe(name: statementName), .Flush)
        try socket.flush()
        
        let resp = try readMsgForce()
        switch resp {
        case .ParseComplete:
            break
        case let .ErrorResponse(pairs: pairs):
            throw PostgresErrors.ParseError(ErrorDescription(pairs))
        default:
            throw PostgresErrors.ProtocolError(.UnexpectedResp(resp))
        }
        
        while let resp = try readMsg() {
            switch resp {
            case .ParameterDescription:
                break
            case .NoData: //todo move to readasync
                return nil
            case let .RowDescription(fieldsNum: _, fields: fields):
                return fields
            //case .ReadyForQuery:
              //  return
            default:
                throw PostgresErrors.ProtocolError(.UnexpectedResp(resp))
            }
        }
        throw PostgresErrors.ProtocolError(.Other("didn't received row description"))
        
    }
    func bind(statementName: String, dest: String, args: [Buffer?]) throws {
        let params = args.map { (Int32($0?.count ?? -1), $0) }
        let msg = FrontendMessages.Bind(destinationName: dest, statementName: statementName, numberOfParametersFormatCodes: 1, paramsFormats: [.Binary], numberOfParameterValues: Int16(args.count), parameters: params, numberOfResultsFormatCodes: 1, resultFormats: [.Binary])
        try socket.write(msg, .Flush)
        try socket.flush()
        let resp = try readMsgForce()
        switch resp {
        case .BindComplete:
            break
        case let .ErrorResponse(pairs: pairs):
            throw PostgresErrors.BindError(ErrorDescription(pairs))
        default:
            throw PostgresErrors.ProtocolError(.UnexpectedResp(resp))
        }
        
    }
    func execute(dest: String) throws {
        
        try socket.write(.Execute(name: dest, maxRowNums: 0), .Sync)
        try socket.flush()
        
    }
    
}















