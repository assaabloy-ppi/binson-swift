//
//  Builder.swift
//  Binson
//
//  Created by Kenneth Pernyer on 2017-05-12

import Foundation

public class Builder {

    /// Unpack from Hex
    /// - parameter data: The Hex string to unpack.
    /// - returns: Binson object.
    public class func unpack(hex: String) -> Binson? {
        let raw = Data(bytes: Array<Byte>(hex: hex))
        return Builder.unpack(data: raw)
    }

    /// Unpack from InputStream
    /// - parameter data: The byte input stream to unpack.
    /// - returns: Binson object.
    public class func unpack(stream: InputStream) -> Binson? {
        let raw = Data(input: stream)
        return Builder.unpack(data: raw)
    }

    /// Unpack from Data
    /// - parameter data: The input data to unpack
    /// - returns: Binson object
    public class func unpack(data: Data) -> Binson? {
        
        guard let (binson, _) = try? unpackBinson(data) else {
            return nil
        }
        
        return binson
    }
    
    /// Unpack from Data
    /// - parameter data: The input data to unpack
    /// - returns: Binson object
    private class func unpackBinson(_ data: Data) throws -> (value: Binson, remainder: Data) {

        guard !data.isEmpty else {
            throw BinsonError.insufficientData
        }
        
        let byte = data.first!
        let rest = data.subdata(in: 1 ..< data.endIndex)
        
        guard byte == Mark.beginByte else {
            throw BinsonError.invalidData
        }
        
        var binson = Binson()
        var data = rest
        
        while !data.isEmpty {
            var name: String
            var value: Value
            (name, value, data) = try unpackPair(data)
            
            if (name == "Mark.endByte") {
                break
            }
            else {
                binson += (name, value)
            }
        }
        
        return (binson, data)
    }
    
    /// Parse one byte
    ///
    /// - parameter data: The input data to unpack.
    /// - returns: One byte data and the remainder to unpack
    private class func unpackByte(_ data: Data) throws -> (value: Byte, remainder: Data) {
        
        guard data.count >= 1 else {
            throw BinsonError.insufficientData
        }
        
        return (data[0], data.subdata(in: 1 ..< data.count))
    }
    
    /// Shift bytes to form an integer.
    ///
    /// - parameter data: The input data to unpack.
    /// - parameter count: The byte size of the integer.
    ///
    /// - returns: An integer representation of `size` bytes of data.
    private class func unpackInteger(_ data: Data, count: Int) throws -> (value: UInt64, remainder: Data) {
        guard count > 0 else {
            throw BinsonError.invalidArgument
        }
        
        guard data.count >= count else {
            throw BinsonError.insufficientData
        }
        
        var value: UInt64 = 0
        for i in 0 ..< count {
            let byte = data[i]
            value = value << 8 | UInt64(byte)
        }
        
        return (value, data.subdata(in: count ..< data.count))
    }
    
    /// Parse bytes to build a string.
    ///
    /// - parameter data: The input data to unpack.
    /// - parameter length: The length of the string.
    ///
    /// - returns: A string representation of `size` bytes of data.
    private class func unpackString(_ data: Data, count: Int) throws -> (value: String, remainder: Data) {
        guard count > 0 else {
            return ("", data)
        }
        
        guard data.count >= count else {
            throw BinsonError.insufficientData
        }
        
        let subdata = data.subdata(in: 0 ..< count)
        guard let result = String(data: subdata, encoding: .utf8) else {
            throw BinsonError.invalidData
        }
        
        return (result, data.subdata(in: count ..< data.count))
    }
    
    /// Parse bytes to form an array of Binson Values.
    ///
    /// TODO: [Byte]
    private class func unpackBytes(_ data: Data, count: Int) throws -> (value: [Byte], remainder: Data) {
        var values = [Byte]()
        var rest = data
        
        var byte: Byte
        
        for _ in 0 ..< count {
            (byte, rest) = try unpackByte(rest)
            values.append(byte)
        }
        
        return (values, rest)
    }
    
    /// Parse bytes to form an array of Binson Values.
    ///
    /// - parameter data: The input data to unpack.
    /// - parameter count: The number of elements to unpack.
    ///
    /// - returns: An array of `count` elements + remainder.
    private class func unpackArray(_ data: Data, count: Int) throws -> (value: [Value], remainder: Data) {
        var values = [Value]()
        var rest = data
        
        var newValue: Value
        
        for _ in 0 ..< count {
            (newValue, rest) = try unpackValue(rest)
            values.append(newValue)
        }
        
        return (values, rest)
    }
    
    
    /// Unpacks data into a Binson Value and returns the remaining data for further scanning.
    ///
    /// - parameter data: The input data to unpack.
    ///
    /// - returns: A Value + remainder.
    private class func unpackPair(_ data: Data) throws -> (name: String, value: Value, remainder: Data) {
        var name: String = "TODO"
        var value: Value = "HEPP"
        var rest = data
        
        // TODO
        
        return (name, value, rest)
    }
    
    /// Unpacks data into a Binson Value and returns the remaining data for further scanning.
    ///
    /// - parameter data: The input data to unpack.
    ///
    /// - returns: A Value + remainder.
    private class func unpackValue(_ data: Data) throws -> (value: Value, remainder: Data) {
        
        guard !data.isEmpty else {
            throw BinsonError.insufficientData
        }
        
        let value = data.first!
        let data = data.subdata(in: 1 ..< data.endIndex)
        
        switch value {
            
        case Mark.beginByte:
            return (Value.nil, data)

        case Mark.endByte:
            return (Value.nil, data)
            
        // fixarray
        case 0x90 ... 0x9f:
            let count = Int(value - 0x90)
            let (array, remainder) = try unpackArray(data, count: count)
            return (.array(array), remainder)
            
        // fixstr
        case 0xa0 ... 0xbf:
            let count = Int(value - 0xa0)
            let (string, remainder) = try unpackString(data, count: count)
            return (.string(string), remainder)
            
        // false
        case Mark.falseByte:
            return (.bool(false), data)
            
        // true
        case Mark.trueByte:
            return (.bool(true), data)
            
        // bytes 8, 16, 32
        case 0xc4 ... 0xc6:
            //let intCount = 1 << Int(value - 0xc4)
            //let (dataCount, remainder1) = try unpackInteger(data, count: intCount)
            //let (subdata, remainder2) = try unpackData(remainder1, count: Int(dataCount))
            //return (.bytes(subdata), remainder2)
            return (.bytes([]), data)
            
        // float 64
        case 0xcb:
            let (intValue, remainder) = try unpackInteger(data, count: 8)
            let double = Double(bitPattern: intValue)
            return (.double(double), remainder)
            
        // int 8
        case 0xd0:
            guard !data.isEmpty else {
                throw BinsonError.insufficientData
            }
            
            let byte = Int8(bitPattern: data[0])
            return (.int(Int64(byte)), data.subdata(in: 1 ..< data.count))
            
        // int 16
        case 0xd1:
            let (bytes, remainder) = try unpackInteger(data, count: 2)
            let integer = Int16(bitPattern: UInt16(truncatingBitPattern: bytes))
            return (.int(Int64(integer)), remainder)
            
        // int 32
        case 0xd2:
            let (bytes, remainder) = try unpackInteger(data, count: 4)
            let integer = Int32(bitPattern: UInt32(truncatingBitPattern: bytes))
            return (.int(Int64(integer)), remainder)
            
        // int 64
        case 0xd3:
            let (bytes, remainder) = try unpackInteger(data, count: 8)
            let integer = Int64(bitPattern: bytes)
            return (.int(integer), remainder)
            
        // str 8, 16, 32
        case 0xd9 ... 0xdb:
            let countSize = 1 << Int(value - 0xd9)
            let (count, remainder1) = try unpackInteger(data, count: countSize)
            let (string, remainder2) = try unpackString(remainder1, count: Int(count))
            return (.string(string), remainder2)
            
        // array 16, 32
        case 0xdc ... 0xdd:
            let countSize = 1 << Int(value - 0xdb)
            let (count, remainder1) = try unpackInteger(data, count: countSize)
            let (array, remainder2) = try unpackArray(remainder1, count: Int(count))
            return (.array(array), remainder2)
            
        default:
            throw BinsonError.invalidData
        }
    }
}
