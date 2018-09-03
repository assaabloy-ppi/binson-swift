//  Builder.swift
//  Binson
//
//  Created by Kenneth Pernyer on 2017-05-12

import Foundation

import os.log
let log = OSLog(subsystem: "binson.aa.st", category: "Builder")

public class Builder {

    /// Unpack from Hex
    /// - parameter data: The Hex string to unpack.
    /// - returns: Binson object.
    public class func unpack(hex: String) -> Binson? {
        if let bytes = [UInt8](hex: hex) {
            let raw = Data(bytes: bytes)
            return Builder.unpack(data: raw)
        } else {
            return nil
        }
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
            os_log("Failed to unpack, no starting MARK", log: log, type: .error)
            return nil
        }
        
        do {
            let (binson, rest2) = try unpackBinsonObject(rest)
            
            if !rest2.isEmpty {
                os_log("Not handling trailing garbage", log: log)
                // Not really an Error, is it?
            }
            return binson
        } catch {
            os_log("Failed to unpack Binson object: %{public}s", log: log, type: .error, error as CVarArg)
            return nil
        }
    }
    
    /// Unpack from JSON object
    /// - parameter data: The input JSON Dictionary to unpack
    /// - returns: Binson object
    public class func unpack(jsonObject: [String: Any]) throws -> Binson {
        var values = [String: BinsonValue]()
        
        for key in jsonObject.keys {
            let any = jsonObject[key]!
            values[key] = try BinsonValue.fromAny(any)
        }
        return Binson(values: values)
    }
    
    /// Unpack from JSON string
    /// - parameter data: The input JSON string to unpack
    /// - returns: Binson object
    public class func unpack(jsondata: Data) throws -> Binson {
        let json = try JSONSerialization.jsonObject(with: jsondata)

        guard let object = json as? [String: Any] else {
            throw BinsonError.invalidData
        }

        return try unpack(jsonObject: object)
    }
    
    /// Unpack from JSON data
    /// - parameter data: The input JSON data to unpack
    /// - returns: Binson object
    public class func unpack(jsonString: String) throws -> Binson {
        return try unpack(jsondata: Data(jsonString.utf8))
    }
    
    //------------ Helpers
    
    /// Unpack from Data expecting a full Binson object
    /// - parameter data: The input data to unpack
    /// - returns: Binson object and possibly a non-empty trailing remainder
    private class func unpackBinsonObject(_ data: Data) throws -> (value: Binson, remainder: Data) {
        var binson = Binson()
        var data = data
        
        while !data.isEmpty {
            var first: String?
            var second: BinsonValue?
            (first, second, data) = try unpackPair(data)
            
            /// Special ending MARK for a Binson object
            guard let name = first, let value = second else {
                break
            }

            binson += (name, value)
        }
        
        /// Return the Binson and if nested remaining data is non-empty
        return (binson, data)
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
        guard count > 0 else {
            throw BinsonError.invalidArgument
        }
        
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

        guard rest.count >= Int(size) else {
            throw BinsonError.insufficientData
        }
        
        let endIndex: Int = count+Int(size)-1
        let subdata = rest[rest.startIndex..<rest.startIndex.advanced(by: endIndex)]
        guard let result = String(data: subdata, encoding: .utf8) else {
            throw BinsonError.invalidData
        }

        return (result, rest.suffix(from: rest.startIndex.advanced(by: endIndex)))
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
        
        var values = [UInt8]()
        var rest2 = rest
        
        var byte: UInt8
        
        for _ in 0 ..< length {
            (byte, rest2) = try unpackByte(rest2)
            values.append(byte)
        }
        
        return (values, rest2)
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
            let (binson, remainder) = try unpackBinsonObject(data)
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
            let double = Double(bitPattern: intValue)
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
