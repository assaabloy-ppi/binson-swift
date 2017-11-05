//  Value+Pack.swift
//  Binson
//
//  Created by Kenneth Pernyer on 2017-11-01.

import Foundation

func packBytes(_ value: UInt64, parts: Int) -> Data {
    guard parts > 0 && parts <= 8 else { return Data() }
    
    let bytes = stride(from: (8 * (parts - 1)), through: 0, by: -8).map { shift in
        return UInt8(truncatingIfNeeded: value >> UInt64(shift))
    }
    return Data(bytes)
}

/// Packs an integer into a byte array. Depending on size it will require
/// 1, 2, 4 or 8 bytes
///
/// - returns: Binson Data/Bytes representation.
func packNumber(_ i: Int64) -> Data {
    switch i {
    case Int64(Int8.min) ... Int64(Int8.max):
        let bytes = [Mark.integer1Byte,
                     Byte(i & 0x000000FF)]
        return Data(bytes)
        
    case Int64(Int16.min) ... Int64(Int16.max):
        let bytes = [Mark.integer2Byte,
                     Byte(i  & 0x000000FF),
                     Byte((i & 0x0000FF00) >> 8)]
        return Data(bytes)

    case Int64(Int32.min) ... Int64(Int32.max):
        let bytes = [Mark.integer4Byte,
                     Byte(i  & 0x000000FF),
                     Byte((i & 0x0000FF00) >> 8),
                     Byte((i & 0x00FF0000) >> 16),
                     Byte((i & 0xFF000000) >> 24)]
        return Data(bytes)

    default:
        let bytes = [Mark.integer8Byte,
                     Byte(i & 0x00000000000000FF),
                     Byte(truncatingIfNeeded: i >> UInt64(8)),
                     Byte(truncatingIfNeeded: i >> UInt64(16)),
                     Byte(truncatingIfNeeded: i >> UInt64(24)),
                     Byte(truncatingIfNeeded: i >> UInt64(32)),
                     Byte(truncatingIfNeeded: i >> UInt64(40)),
                     Byte(truncatingIfNeeded: i >> UInt64(48)),
                     Byte(truncatingIfNeeded: i >> UInt64(56))]
        return Data(bytes)
    }
}

/// Packs a Value into an array of bytes.
///
/// - parameter value: The Value to encode
/// - returns: A Binson byte representation
///
extension Value {
    public var data: Data {
        return self.pack()
    }
    
    public var hex: String {
        return self.pack().hex
    }
    
    public var json: Any {
        return self.toJson()
    }
    
    public func pack() -> Data {
        switch self {
            
        case .bool(let value):
            return Data([value ? Mark.trueByte : Mark.falseByte])
            
        case .int(let value):
            return packNumber(value)
            
        case .double(let value):
            let integerValue = value.bitPattern
            return Data([Mark.doubleByte]) + packBytes(integerValue, parts: 8)
            
        case .string(let string):
            let utf8 = string.utf8
            let count = UInt32(utf8.count)
            
            let prefix: Data
            if count <= UInt32(Int8.max) {
                prefix = Data([Mark.string1Byte, Byte(count)])
            } else if count <= UInt32(Int16.max) {
                prefix = Data([Mark.string2Byte]) + packBytes(UInt64(count), parts: 2).reversed()
            } else {
                prefix = Data([Mark.string4Byte]) + packBytes(UInt64(count), parts: 4).reversed()
            }
            
            return prefix + utf8
            
        case .bytes(let bytes):
            let count = UInt32(bytes.count)
            
            let prefix: Data
            if count <= UInt32(Int8.max) {
                prefix = Data([Mark.bytes1Byte, Byte(count)])
            } else if count <= UInt32(Int16.max) {
                prefix = Data([Mark.bytes2Byte]) + packBytes(UInt64(count), parts: 2).reversed()
            } else {
                prefix = Data([Mark.bytes4Byte]) + packBytes(UInt64(count), parts: 4).reversed()
            }
            
            return prefix + bytes
            
        case .array(let array):
            let prefix = Data([Mark.beginArrayByte])
            let payload = array.flatMap { $0.pack() }
            let suffix = Data([Mark.endArrayByte])
            
            return prefix + payload + suffix
            
        case let .object(binson):
            return binson.pack()
            
        default: return Data([0x00])
        }
    }
}

