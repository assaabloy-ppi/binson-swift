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
        
        guard let (byte, rest) = try? unpackByte(data), byte == Mark.beginByte else {
            print("Failed to unpack, no starting MARK")
            return nil
        }
        
        let binson: Binson
        let rest2: Data
        do {
            (binson, rest2) = try unpackBinsonObject(rest)
        } catch {
            print("caught: \(error)")
            return nil
        }
        
        if !rest2.isEmpty {
            print("Handle trailing garbage")
            // Not really an Error, is it?
        }
        
        return binson
    }
    
    /// Unpack from Data expecting a full Binson object
    /// - parameter data: The input data to unpack
    /// - returns: Binson object and possibly a non-empty trailing remainder
    private class func unpackBinsonObject(_ data: Data) throws -> (value: Binson, remainder: Data) {
        
        var binson = Binson()
        var data = data
        
        while !data.isEmpty {
            var name: String
            var value: Value
            (name, value, data) = try unpackPair(data)
            
            /// Special ending MARK for a Binson object
            if (name == "Mark.endByte") {
                break
            }
            else {
                binson += (name, value)
            }
        }
        
        /// Return the Binson and if nested remaining data is non-empty
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
        for i in (0 ..< count).reversed() {
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
    private class func unpackString(_ data: Data, value: Byte) throws -> (value: String, remainder: Data) {
        
        let count: Int = { () -> Int in
            switch value {
            case Mark.string1Byte:
                return 1
            case Mark.string2Byte:
                return 2
            default:
                return 4
            }
        }()
        
        print(data.hex)
        
        guard let (size, rest) = try? unpackInteger(data, count: count) else {
            throw BinsonError.invalidData
        }
        
        guard size >= 0 else {
            throw BinsonError.invalidData
        }
        
        guard rest.count >= Int(size) else {
            throw BinsonError.insufficientData
        }
        
        let endIndex: Int = count+Int(size)-1
        let subdata = rest.subdata(in: 0 ..< endIndex)
        guard let result = String(data: subdata, encoding: .utf8) else {
            throw BinsonError.invalidData
        }

        return (result, rest.subdata(in: endIndex ..< rest.count))
    }
    
    /// Parse bytes to form an array of Binson Values.
    ///
    /// TODO: [Byte]
    private class func unpackBytes(_ data: Data, value: Byte) throws -> (value: [Byte], remainder: Data) {
        
        let n = { () -> Int in
            switch value {
            case Mark.bytes1Byte:
                return 1
            case Mark.bytes2Byte:
                return 2
            default:
                return 4
            }
        }()
        
        guard let (count, rest) = try? unpackInteger(data, count: n) else {
            throw BinsonError.invalidData
        }
        
        let length = Int(count)
        
        guard length > 0 else {
            throw BinsonError.invalidData
        }
        
        guard rest.count >= length else {
            throw BinsonError.insufficientData
        }
        
        var values = [Byte]()
        var rest2 = rest
        
        var byte: Byte
        
        for _ in 0 ..< length {
            (byte, rest2) = try unpackByte(rest2)
            values.append(byte)
        }
        
        return (values, rest2.subdata(in: 0 ..< rest2.count))
    }
    
    /// Parse bytes to form an array of Binson Values.
    ///
    /// - parameter data: The input data to unpack.
    /// - returns: An array of Values + remainder.
    private class func unpackArray(_ data: Data) throws -> (value: [Value], remainder: Data) {
        var values = [Value]()
        var rest = data

        while (rest.first != Mark.endArrayByte){
            let (tempValue, tempRest) = try unpackValue(rest)
            rest = tempRest
            values.append(tempValue)
        }
        
        rest = rest.subdata(in: 1 ..< rest.count)
        
        return (values, rest)
    }
    
    /// Unpacks Key, Value Pair and returns the remaining data for further scanning.
    ///
    /// - parameter data: The input data to unpack.
    /// - returns: A Key, a Value + remainder.
    private class func unpackPair(_ data: Data) throws -> (name: String, value: Value, remainder: Data) {
        
        guard let (name, rest) = try? unpackValue(data) else {
            throw BinsonError.invalidData
        }
        
        guard name != Value.nil else {
            // We found the end MARK and value will be Value.nil
            return ("Mark.endByte", Value.nil, rest)
        }

        guard let key: String = name.stringValue else {
            // We found a BinsonValue for Key but it is not a String
            throw BinsonError.invalidData
        }
            
        guard let (value, rest2) = try? unpackValue(rest) else {
            // We got an exception while parsing for BinsonValue
            throw BinsonError.invalidData
        }
        
        // We parsed key and value correctly
        return (key, value, rest2)
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
            let (binson, remainder) = try unpackBinsonObject(data)
            return (Value.object(binson), remainder)
        
        // TODO: Improve the parsing later
        case Mark.endByte:
            return (Value.nil, data)
            
        // False
        case Mark.falseByte:
            return (Value.bool(false), data)
            
        // True
        case Mark.trueByte:
            return (Value.bool(true), data)
            
        // String
        case Mark.string1Byte ... Mark.string4Byte:
            let (string, remainder) = try unpackString(data, value: value)
            return (Value.string(string), remainder)
            
        // Bytes
        case Mark.bytes1Byte ... Mark.bytes4Byte:
            let (bytes, rest) = try unpackBytes(data, value: value)
            return (Value.bytes(bytes), rest)

        // Double
        case Mark.doubleByte:
            let (intValue, remainder) = try unpackInteger(data, count: 8)
            let double = Double(bitPattern: intValue)
            return (.double(double), remainder)
            
        // Int 8
        case Mark.integer1Byte:
            let (number, rest) = try unpackInteger(data, count: 1)
            let integer = Int16(bitPattern: UInt16(truncatingBitPattern: number))
            return (.int(Int64(integer)), rest)
            
        // Int 16
        case Mark.integer2Byte:
            let (number, rest) = try unpackInteger(data, count: 2)
            let integer = Int16(bitPattern: UInt16(truncatingBitPattern: number))
            return (.int(Int64(integer)), rest)
            
        // Int 32
        case Mark.integer4Byte:
            let (number, rest) = try unpackInteger(data, count: 4)
            let integer = Int32(bitPattern: UInt32(truncatingBitPattern: number))
            return (.int(Int64(integer)), rest)
            
        // Int 64
        case Mark.integer8Byte:
            let (number, rest) = try unpackInteger(data, count: 8)
            let integer = Int64(bitPattern: number)
            return (.int(integer), rest)
            
        // Array
        case Mark.beginArrayByte:
            let (array, rest) = try unpackArray(data)
            return (.array(array), rest)
            
        default:
            throw BinsonError.invalidData
        }
    }
}
