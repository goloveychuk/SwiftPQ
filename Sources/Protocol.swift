//
//  Protocol.swift
//  PurePostgres
//
//  Created by badim on 10/28/16.
//
//

import Foundation
import CryptoSwift

typealias Byte = UInt8






class Protocol {
    let socket: Socket
    var password: String?
    var user: String?
    init(socket: Socket) {
        self.socket = socket
    }
    func startup(user: String, database: String?, password: String?) {
        let msg = FrontendMessages.StartupMessage(user: user, database: database)
        let buf = msg.buf()
        
        try! socket.write(buf)
        try! socket.flush()
        self.password = password
        self.user = user
        read()
        
    }
    func read() {
        let resp = try! socket.read()
        let msgIn = Buffer(resp)
        while true {
            guard let msg = try! BackendMessages(buf: msgIn) else {
                break
            }
            print(msg)
            switch msg {
            case let .AuthenticationMD5Password(salt: salt):
                authMd5(salt: salt)
            case .AuthenticationCleartextPassword:
                authPlain()
            default:
                break
            }
        }

    }
    func authPlain() {
        let msg = FrontendMessages.PasswordMessage(password: self.password!)
        let buf = msg.buf()
        try! socket.write(buf)
        try! socket.flush()
        read()
    }
    func authMd5(salt: Data) {
        
        let c1 = (self.password! + self.user!).md5()
        let pass = "md5" + (c1.utf8+salt).md5().toHexString()
        
        let msg = FrontendMessages.PasswordMessage(password: pass)
    
        let buf = msg.buf()
        try! socket.write(buf)
        try! socket.flush()

        read()
    }
    
}

extension Protocol {
    func parse(_ query: String ) {
        let statementName = "dest"
        let msg = FrontendMessages.Parse(destination: statementName, query: query, numberOfParameters: 0, argsOids: [])
        
        let msg2 = FrontendMessages.Describe(name: statementName)
        
        let msg3 = FrontendMessages.Sync
        try! socket.write(msg.buf())
        try! socket.write(msg2.buf())
        try! socket.write(msg3.buf())
        try! socket.flush()
        read()
    let dest = "asdasd"
        let msg4 = FrontendMessages.Bind(destinationName: dest, statementName: statementName, numberOfParametersFormatCodes: 1, paramsFormats: [.Binary], numberOfParameterValues: 0, parameters: [], numberOfResultsFormatCodes: 1, resultFormats: [.Text])
        
        try! socket.write(msg4.buf())
        
        
        let msg5 = FrontendMessages.Execute(name: dest, maxRowNums: 0)
        
        try! socket.write(msg5.buf())
        try! socket.flush()
        read()
    }
    
}















