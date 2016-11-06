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

let BATCH_SIZE = 1_000_000

class LibmillSocket: Socket {
    let socket: TCPStream
    
    public func write(_ data: Data) throws {
        try data.withUnsafeBytes { (p: UnsafePointer<Byte>) -> Void in
        let bp = UnsafeBufferPointer(start: p, count: data.count)
        try self.socket.write(bp, deadline: -1)
    }
    }
    public func read() throws -> Data {
        var buf = Data(count: BATCH_SIZE)
        let buffer = try buf.withUnsafeMutableBytes { (p: UnsafeMutablePointer<Byte>) -> UnsafeBufferPointer<Byte> in
            let bufP = UnsafeMutableBufferPointer(start: p, count: BATCH_SIZE)
            return try self.socket.read(into: bufP, deadline: -1)
        }

        buf = Data(buffer: buffer)
        return buf
//        /////////////////////////////////////////////////////////////////////////////////
//        var buf = try self.socket.read(upTo: BATCH_SIZE, deadline: -1)
//        return buf.withUnsafeMutableBufferPointer {
//            let d = Data(bytesNoCopy: UnsafeMutableRawPointer($0.baseAddress!), count: buf.count, deallocator: .none)
//            return d
//        }
        
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
            //print("debug, sent", i)
            try write(i.buf().pack())
        }
    }
}
