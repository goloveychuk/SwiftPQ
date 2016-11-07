//
//  Buffer.swift
//  PurePostgres
//
//  Created by badim on 10/29/16.
//
//

import Foundation
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public typealias Buffer = Array<Byte>

extension Array {
    public func copyBytes(to pointer: UnsafeMutableBufferPointer<Byte>) {
        guard pointer.count > 0 else {
            return
        }
        
        precondition(self.endIndex >= 0)
        precondition(self.endIndex <= pointer.count, "The pointer is not large enough")
        
        _ = self.withUnsafeBufferPointer {
            memcpy(pointer.baseAddress!, $0.baseAddress!, self.count)
        }
    }
    public func copyBytes(to pointer: UnsafeMutablePointer<Byte>, count: Int) {
        copyBytes(to: UnsafeMutableBufferPointer(start: pointer, count: count))
    }

}
//extension Buffer {
//    public mutating func append(_ byte: Byte) {
//        self.bytes.append(byte)
//    }
//    mutating func replaceSubrange(_ range: Range<Int>, with: Buffer) {
//        self.bytes.replaceSubrange(range, with: with)
//    }
//}



struct WriteBuffer {
    fileprivate var buffer: Buffer
    fileprivate var lengthInd: Int = 0

    init(_ type: FrontendMessageTypes?) {
        buffer = Buffer()
        if let type = type {
            buffer.append(Byte(type.rawValue.value))
            lengthInd = 1
        }
        self.addInt32(0) //preserve for len
    }
    func pack() -> Buffer {
        var buf = self
        buf.buffer.replaceSubrange(lengthInd..<lengthInd+MemoryLayout<Int32>.size, with: Int32(self.buffer.count-lengthInd).toBuffer)//should be faster
        return buf.buffer
    }
    mutating func addInt32(_ v : Int32) {
        self.buffer.append(contentsOf: v.toBuffer)
    }
    mutating func addInt16(_ v: Int16) {
        self.buffer.append(contentsOf: v.toBuffer)
    }
    mutating func addLen() {
        lengthInd = self.buffer.count
        addInt32(0)
    }
    mutating func addByte1(_ v: Byte) {
        buffer.append(v)
    }
    mutating func addBuffer(_ v: Buffer) {
        buffer.append(contentsOf: v)
    }
    mutating func addString(_ v : String) {
        
        
        self.buffer.append(contentsOf: v.toBuffer)
        addNull()
        
    }
    mutating  func addNull() {
        self.buffer.append(0)
    }
}

enum BufferErrors: Error {
    case NotEnough
}

let MSG_HEAD_LEN = 1+MemoryLayout<Int32>.size

struct ReadBuffer {
    fileprivate var buffer: Buffer
    fileprivate var cursor: Int = 0
    
    init() {
        buffer = Buffer()
    }
    mutating func add(_ d: Buffer) {
        if left > 0 {
            self.buffer = Buffer(self.buffer[cursor..<buffer.count])
            self.buffer.append(contentsOf: d)
        } else {
            self.buffer = d
        }
        print(self.buffer.count)
        cursor = 0
        
    }
    mutating func skip(_ bytes: Int = 1) {
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
    mutating func unpack() throws -> BackendMsgTypes? {
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
    mutating func getByte1() -> Byte {
        cursor += 1
        return buffer[cursor-1]
    }
    mutating func getBytes(_ count: Int) -> Buffer {
        let d = buffer[cursor..<cursor+count]
        cursor += count
        return Buffer(d)
    }
    mutating func getInt32() -> Int32 {
        let newC = cursor+MemoryLayout<Int32>.size
        defer { cursor = newC }
        return Int32(psBuffer: Buffer(buffer[cursor..<newC]))
    }
    mutating func getInt16() -> Int16 {
        let newC = cursor+MemoryLayout<Int16>.size
        defer { cursor = newC }
        return Int16(psBuffer: Buffer(buffer[cursor..<newC]))
    }
    mutating func getString() -> String {
        var newCursor = cursor
        while buffer[newCursor] != 0 {
            newCursor += 1
        }
        let strData = buffer[cursor..<newCursor]
        let str = String(psBuffer: Buffer(strData))
        
        cursor = newCursor + 1
        return str
    }
    var isNull: Bool {
        return self.buffer[cursor] == 0
    }
    
}

