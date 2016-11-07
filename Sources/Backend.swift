//
//  Backend.swift
//  PurePostgres
//
//  Created by badim on 10/29/16.
//
//

import Foundation



enum Errors: Error {
    case badMsgType(Byte)
    case badByte
}





enum TransactionStatus: Character {
    case idle = "I"
    case transactionBlock = "T"
    case failedTransactionBlock = "E"
}


enum BackendMsgTypes: UnicodeScalar {
    case Authentication = "R"
    case ParameterStatus = "S"
    case BackendKeyData = "K"
    case ReadyForQuery = "Z"
    case ErrorResponse = "E"
    case CommandComplete = "C"
    case ParseComplete = "1"
    case ParameterDescription = "t"
    case RowDescription = "T"
    case BindComplete = "2"
    case DataRow = "D"
    case NoticeResponse = "N"
    case NoData = "n"
}





typealias Field = (name: String, tableOid: Int32, atrNum: Int16, typeOid: Int32, typeSize: Int16, typeMod: Int32, formatType: Int16)

enum BackendMessages {
    
    case AuthenticationOk
    case AuthenticationKerberosV5
    case AuthenticationCleartextPassword
    case AuthenticationMD5Password(salt: Buffer)
    case AuthenticationSCMCredential
    case AuthenticationGSS
    case AuthenticationSSPI
    case AuthenticationGSSContinue
    
    case ParameterStatus(k: String, v: String)
    case BackendKeyData(id: Int32, secretKey: Int32)
    case ReadyForQuery(status: TransactionStatus)
    case ErrorResponse(pairs: [(Byte, String)])
    case CommandComplete(tag: String)
    case ParseComplete
    case ParameterDescription(number: Int16, oids: [Int32])
    case RowDescription(fieldsNum: Int16, fields: [Field])
    case BindComplete
    case DataRow(num: Int16, values: [Buffer?])
    case NoticeResponse(pairs: [(Byte, String)])
    case NoData
    
    init(msgType : BackendMsgTypes, buf: ReadBuffer) throws {
        
        
        switch msgType {
        case .Authentication:
            let d1 = buf.getInt32()
            switch d1 {
            case 0:
                self = .AuthenticationOk
            case 2:
                self = .AuthenticationKerberosV5
            case 3:
                self = .AuthenticationCleartextPassword
            case 5:
                let salt = buf.getBytes(4)
                self = .AuthenticationMD5Password(salt: salt)
            case 6:
                self = .AuthenticationSCMCredential
            default:
                throw Errors.badByte
            }
            
        case .ParameterStatus:
            let k = buf.getString()
            let v = buf.getString()
            self = .ParameterStatus(k: k, v: v)
        case .BackendKeyData:
            let id = buf.getInt32()
            let secretKey = buf.getInt32()
            self = .BackendKeyData(id: id, secretKey: secretKey)
        case .ReadyForQuery:
            let status = Character(UnicodeScalar(buf.getByte1()))
            self = .ReadyForQuery(status: TransactionStatus(rawValue: status)!)
        case .ErrorResponse:
            var pairs: [(Byte, String)] = []
            while !buf.isNull {
                let fType = buf.getByte1()
                let val = buf.getString()
                pairs.append((fType, val))
            }
            buf.skip()
            self = .ErrorResponse(pairs: pairs )
        case .CommandComplete:
            let tag = buf.getString()
            self = .CommandComplete(tag: tag)
        case .ParseComplete:
            self = .ParseComplete
        case .ParameterDescription:
            let num = buf.getInt16()
            var oids = [Int32](repeating: 0, count: Int(num))
            for ind in 0..<Int(num) {
                oids[ind] = buf.getInt32()
            }
            self = .ParameterDescription(number: num, oids: oids)
            
        case .RowDescription:
            let num = buf.getInt16()
            var fields = [Field]()
            for _ in 0..<num {
                let name = buf.getString()
                let tableOid = buf.getInt32()
                let atrNum = buf.getInt16()
                let typeOid = buf.getInt32()
                let typeSize = buf.getInt16()
                let typeMod = buf.getInt32()
                let formatType = buf.getInt16()
                
                fields.append(Field(name: name, tableOid: tableOid, atrNum: atrNum,
                                    typeOid: typeOid, typeSize: typeSize,
                                    typeMod: typeMod, formatType: formatType))
            }
            self = .RowDescription(fieldsNum: num, fields: fields)
        case .BindComplete:
            self = .BindComplete
        case .DataRow:
            let num = buf.getInt16()
            var values = [Buffer?]()
            for _ in 0..<num {
                let len = buf.getInt32()
                var d : Buffer? = nil
                if len != -1 {
                    d = buf.getBytes(Int(len))
                    //print(String(data: d!, encoding: String.Encoding.utf8))
                }
                values.append(d)
            }
            self = .DataRow(num: num, values: values)
        case .NoticeResponse:
            var pairs: [(Byte, String)] = []
            while !buf.isNull {
                let fType = buf.getByte1()
                let val = buf.getString()
                pairs.append((fType, val))
            }
            buf.skip()
            self = .NoticeResponse(pairs: pairs )
        case .NoData:
            self = .NoData
        }
        
    }
    
}
