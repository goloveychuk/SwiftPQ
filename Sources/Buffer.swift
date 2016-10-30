//
//  Buffer.swift
//  PurePostgres
//
//  Created by badim on 10/29/16.
//
//

import Foundation



class Buffer {
    var buffer: Data
    var lengthInd: Int? = nil
    var cursor = 0
    init(_ data : Data){
        buffer = data
    }
    init() {
        buffer = Data()
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
    func addType<T:RawRepresentable>(_ v: T) where T.RawValue == UnicodeScalar {
        buffer.append(Byte(v.rawValue.value))
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
    func buf() -> Data {
        if let lengthInd = lengthInd {
            //print("count", buffer.count)
            self.buffer.replaceSubrange(lengthInd..<lengthInd+MemoryLayout<Int32>.size, with: Int32(self.buffer.count-lengthInd).toBytes)
        }
        return self.buffer
    }
    var haveMore: Bool {
        return cursor < self.buffer.count
    }
    var isNull: Bool {
        return self.buffer[cursor] == 0
    }
    func getByte1() -> Byte {
        cursor += 1
        return buffer[cursor-1]
    }
    func skipByte() {
        cursor += 1
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
    func getInt16() -> Int16 {//todo refactor
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
}

