//
//  Socket.swift
//  PurePostgres
//
//  Created by badim on 10/28/16.
//
//

import Foundation

import TCP

protocol Socket {
     func write(_ data: Data) throws
    func read() throws -> Data
    init(host: String, port: Int) throws
     func flush() throws
}

let BATCH_SIZE = 10000000

class LibmillSocket: Socket {
    let socket: TCPStream
    
    public func write(_ data: Data) throws {
        try data.withUnsafeBytes { (p: UnsafePointer<Byte>) -> Void in
        let bp = UnsafeBufferPointer(start: p, count: data.count)
        try self.socket.write(bp, deadline: -1)
    }
    }
    public func read() throws -> Data {
        let buf = try self.socket.read(upTo: BATCH_SIZE, deadline: -1)
        return Data(buf)
    }
    public func flush() throws {
        try self.socket.flush(deadline: -1)
    }
    required init(host: String, port: Int) throws {
        self.socket = try TCPStream(host: host, port: port, deadline: -1)
        try socket.open(deadline: -1)
    }
}


extension Socket {
    func write(_ msgs: FrontendMessages...) throws {
        for i in msgs {
            print("debug, sent", i)
            try write(i.buf().pack())
        }
    }
}
