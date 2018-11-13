//  Binson+Unpack.swift
//  Binson
//
//  Created by Kenneth Pernyer on 2017-05-12

import Foundation

internal extension Binson {
    //------------ Helpers

    /// Unpack from Data
    /// - parameter data: The input data to unpack
    /// - returns: Binson object
    internal class func unpackBinson(data: Data) throws -> [String: BinsonValue] {

        let (byte, rest) = try unpackByte(data)
        guard byte == Mark.beginByte else {
            throw BinsonError.invalidData
        }

        let (values, rest2) = try unpackPairs(rest)
        if !rest2.isEmpty {
            throw BinsonError.trailingGarbage
        }

        return values
    }

    /// Parse one byte
    ///
    /// - parameter data: The input data to unpack.
    /// - returns: One byte data and the remainder to unpack
    private class func unpackByte(_ data: Data) throws -> (value: UInt8, remainder: Data) {
        guard data.count >= 1 else {
            throw BinsonError.insufficientData
        }
        
        return (data[data.startIndex], data.suffix(from: data.startIndex.advanced(by: 1)))
    }
    
    /// Shift bytes to form an integer.
    ///
    /// - parameter data: The input data to unpack.
    /// - parameter count: The byte size of the integer.
    ///
    /// - returns: An integer representation of `size` bytes of data.
    private class func unpackInteger(_ data: Data, count: Int) throws -> (value: UInt64, remainder: Data) {
        assert(count > 0)

        guard data.count >= count else {
            throw BinsonError.insufficientData
        }
        
        var value: UInt64 = 0
        for i in (0 ..< count).reversed() {
            let byte = data[data.startIndex.advanced(by: i)]
            value = value << 8 | UInt64(byte)
        }
        
        return (value, data.suffix(from: data.startIndex.advanced(by: count)))
    }
    
    /// Parse bytes to build a string.
    ///
    /// - parameter data: The input data to unpack.
    /// - parameter length: The length of the string.
    ///
    /// - returns: A string representation of `size` bytes of data.
    private class func unpackString(_ data: Data, value: UInt8) throws -> (value: String, remainder: Data) {
        
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

        guard let (size, rest) = try? unpackInteger(data, count: count) else {
            throw BinsonError.invalidData
        }

        let length = Int(size)

        guard rest.count >= length else {
            throw BinsonError.insufficientData
        }
        
        let subdata = rest[rest.startIndex..<rest.startIndex.advanced(by: length)]
        guard let result = String(data: subdata, encoding: .utf8) else {
            throw BinsonError.invalidData
        }

        return (result, rest.suffix(from: rest.startIndex.advanced(by: length)))
    }
    
    /// Parse bytes to form an array of Binson Values.
    private class func unpackBytes(_ data: Data, value: UInt8) throws -> (value: [UInt8], remainder: Data) {
        
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

        let subdata = rest.subdata(in: rest.startIndex..<rest.startIndex.advanced(by: length))
        let values = [UInt8](subdata)

        return (values, rest.suffix(from: rest.startIndex.advanced(by: length)))
    }
    
    /// Parse bytes to form an array of Binson Values.
    ///
    /// - parameter data: The input data to unpack.
    /// - returns: An array of Values + remainder.
    private class func unpackArray(_ data: Data) throws -> (value: [BinsonValue], remainder: Data) {
        var values = [BinsonValue]()
        var rest = data

        while rest.first != Mark.endArrayByte {
            let (tempValue, tempRest) = try unpackValue(rest)
            rest = tempRest

            guard let value = tempValue else {
                // End marker should not appear here
                throw BinsonError.invalidData
            }
            values.append(value)
        }

        return (values, rest.suffix(from: rest.startIndex.advanced(by: 1)))
    }

    /// Unpacks a series of Key, Value Pairs and returns the remaining data for further scanning.
    ///
    /// - parameter data: The input data to unpack.
    /// - returns: A key value dictionary and the remaining data.
    private class func unpackPairs(_ data: Data) throws -> (pairs: [String: BinsonValue], remainder: Data) {
        var data = data
        var pairs = [String: BinsonValue]()
        var prevName: String?

        while !data.isEmpty {
            var first: String?
            var second: BinsonValue?
            (first, second, data) = try unpackPair(data)

            /// Special ending MARK for a Binson object
            guard let name = first, let value = second else {
                break
            }

            // Field names must unique and sorted in ascending order
            if let prev = prevName, name <= prev {
                throw BinsonError.invalidFieldName
            }

            pairs[name] = value
            prevName = name
        }

        return (pairs, data)
    }

    /// Unpacks Key, Value Pair and returns the remaining data for further scanning.
    ///
    /// - parameter data: The input data to unpack.
    /// - returns: A Key, a Value + remainder.
    private class func unpackPair(_ data: Data) throws -> (name: String?, value: BinsonValue?, remainder: Data) {
        
        guard let (first, rest) = try? unpackValue(data) else {
            throw BinsonError.invalidData
        }
        
        guard let name = first else {
            // We found the end MARK and value will be nil
            return (nil, nil, rest)
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
    /// - returns: A Value + remainder.
    class func unpackValue(_ data: Data)
        throws -> (value: BinsonValue?, remainder: Data) {
        
        guard !data.isEmpty else {
            throw BinsonError.insufficientData
        }
        
        let value = data.first!
        let data = data.suffix(from: data.startIndex.advanced(by: 1))
        
        switch value {
            
        case Mark.beginByte:
            let (values, remainder) = try unpackPairs(data)
            let binson = Binson(values: values)
            return (BinsonValue(binson), remainder)
        
        case Mark.endByte:
            return (nil, data)
            
        // False
        case Mark.falseByte:
            return (BinsonValue(false), data)
            
        // True
        case Mark.trueByte:
            return (BinsonValue(true), data)
            
        // String
        case Mark.string1Byte ... Mark.string4Byte:
            let (string, remainder) = try unpackString(data, value: value)
            return (BinsonValue(string), remainder)
            
        // Bytes
        case Mark.bytes1Byte ... Mark.bytes4Byte:
            let (bytes, rest) = try unpackBytes(data, value: value)
            return (BinsonValue(bytes), rest)

        // Double
        case Mark.doubleByte:
            let (intValue, remainder) = try unpackInteger(data, count: 8)
            let double = Double(bitPattern: intValue.bigEndian)
            return (BinsonValue(double), remainder)
            
        // Int 8
        case Mark.integer1Byte:
            let (number, rest) = try unpackInteger(data, count: 1)
            let integer = Int8(bitPattern: UInt8(truncatingIfNeeded: number))
            return (BinsonValue(integer), rest)
            
        // Int 16
        case Mark.integer2Byte:
            let (number, rest) = try unpackInteger(data, count: 2)
            let integer = Int16(bitPattern: UInt16(truncatingIfNeeded: number))
            return (BinsonValue(integer), rest)
            
        // Int 32
        case Mark.integer4Byte:
            let (number, rest) = try unpackInteger(data, count: 4)
            let integer = Int32(bitPattern: UInt32(truncatingIfNeeded: number))
            return (BinsonValue(integer), rest)
            
        // Int 64
        case Mark.integer8Byte:
            let (number, rest) = try unpackInteger(data, count: 8)
            let integer = Int64(bitPattern: number)
            return (BinsonValue(integer), rest)
            
        // Array
        case Mark.beginArrayByte:
            let (array, rest) = try unpackArray(data)
            return (BinsonValue(array), rest)
            
        default:
            throw BinsonError.invalidData
        }
    }
}
