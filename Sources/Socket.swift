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

let BATCH_SIZE = 10000

class LibmillSocket: Socket {
    let socket: TCPStream
    func write(_ data: Data) throws {
        try data.withUnsafeBytes { (p: UnsafePointer<Byte>) -> Void in
            let bp = UnsafeBufferPointer(start: p, count: data.count)
            try self.socket.write(bp, deadline: -1)
        }
    }
    func read() throws -> Data {
        var allData = Data()
        while true{
            let buf = try self.socket.read(upTo: BATCH_SIZE, deadline: -1)
            
            allData.append(contentsOf: buf)
            if buf.count < 8192 {
                break
            }
            
        }
        return allData
    }
    func flush() throws {
        try self.socket.flush(deadline: -1)
    }
    required init(host: String, port: Int) throws {
        self.socket = try TCPStream(host: host, port: port, deadline: -1)
        try socket.open(deadline: -1)
    }
    
    
}
