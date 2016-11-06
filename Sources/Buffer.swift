//
//  Buffer.swift
//  PurePostgres
//
//  Created by badim on 10/29/16.
//
//

import Foundation



class WriteBuffer {
    fileprivate var buffer: Data
    fileprivate var lengthInd: Int = 0

    init(_ type: FrontendMessageTypes?) {
        buffer = Data()
        if let type = type {
            buffer.append(Byte(type.rawValue.value))
            lengthInd = 1
        }
        self.addInt32(0) //preserve for len
    }
    func pack() -> Data {
        self.buffer.replaceSubrange(lengthInd..<lengthInd+MemoryLayout<Int32>.size, with: Int32(self.buffer.count-lengthInd).toBytes)//should be faster
        return self.buffer
    }
    func addInt32(_ v : Int32) {
        self.buffer.append(v.toBytes)
    }
    func addInt16(_ v: Int16) {
        self.buffer.append(v.toBytes)
    }
    func addLen() {
        lengthInd = self.buffer.count
        addInt32(0)
    }
    func addByte1(_ v: Byte) {
        buffer.append(v)
    }
    func addData(_ v: Data) {
        buffer.append(v)
    }
    func addString(_ v : String) {
        let bytes = v.data(using: String.Encoding.utf8)
        if let bytes = bytes {
            self.buffer.append(contentsOf: bytes)
            addNull()
        }
    }
    func addNull() {
        self.buffer.append(0)
    }
}

enum BufferErrors: Error {
    case NotEnough
}

let MSG_HEAD_LEN = 1+MemoryLayout<Int32>.size

class ReadBuffer {
    fileprivate var buffer: Data
    fileprivate var cursor: Int = 0
    
    init() {
        buffer = Data()
    }
    func add(_ d: Data) {
        if left > 0 {
            self.buffer = self.buffer.subdata(in: cursor..<buffer.count)
            self.buffer.append(d)
        } else {
            self.buffer = d
        }
        print(self.buffer.count)
        cursor = 0
        
    }
    func skip(_ bytes: Int = 1) {
        cursor += bytes
    }
    var left: Int { return buffer.count - cursor }
    var isEmpty: Bool {
        return left == 0
    }
//    func clean() {
//        cursor = 0
//        buffer = Data()
//    }
    func unpack() throws -> BackendMsgTypes? {
        let bytesLeft = buffer.count - cursor
        
        guard bytesLeft >= MSG_HEAD_LEN else {
            return nil
        }
        let msgTypeByte = getByte1()
        let msgType = BackendMsgTypes(rawValue: UnicodeScalar(msgTypeByte))!
        
        let len = Int(getInt32())
        
        guard bytesLeft >= len else {
            cursor -= MSG_HEAD_LEN
            return nil
        }
        return msgType
    }
    func getByte1() -> Byte {
        cursor += 1
        return buffer[cursor-1]
    }
    func getBytes(_ count: Int) -> Data {
        let d = buffer.subdata(in: cursor..<cursor+count)
        cursor += count
        return d
    }
    func getInt32() -> Int32 {
        let newC = cursor+MemoryLayout<Int32>.size
        defer { cursor = newC }
        return Int32(fromBytes: buffer.subdata(in: cursor..<newC))
    }
    func getInt16() -> Int16 {
        let newC = cursor+MemoryLayout<Int16>.size
        defer { cursor = newC }
        return Int16(fromBytes: buffer.subdata(in: cursor..<newC))
    }
    func getString() -> String {
        var newCursor = cursor
        while buffer[newCursor] != 0 {
            newCursor += 1
        }
        let strData = buffer.subdata(in: cursor..<newCursor)
        let str = String(data: strData, encoding: String.Encoding.utf8)
        
        cursor = newCursor + 1
        return str!
    }
    var isNull: Bool {
        return self.buffer[cursor] == 0
    }
    
}

