//  Value+Pack.swift
//  Binson
//
//  Created by Kenneth Pernyer on 2017-11-01.

import Foundation

/// Packs a Value into an array of bytes.
///
/// - parameter value: The Value to encode
/// - returns: A Binson byte representation
///
extension BinsonValue {
    public var data: Data {
        return pack()
    }
    
    public var hex: String {
        return data.hex
    }

    public func pack() -> Data {
        switch self {
            
        case .bool(let value):
            return Data([value ? Mark.trueByte : Mark.falseByte])
            
        case .int(let value):
            return BinsonValue.packNumber(value)
            
        case .double(let value):
            let integerValue = value.bitPattern
            return Data([Mark.doubleByte]) + BinsonValue.packBytes(integerValue, parts: 8)
            
        case .string(let string):
            let utf8 = string.utf8
            let count = UInt32(utf8.count)
            
            let prefix: Data
            if count <= UInt32(Int8.max) {
                prefix = Data([Mark.string1Byte, UInt8(count)])
            } else if count <= UInt32(Int16.max) {
                prefix = Data([Mark.string2Byte]) + BinsonValue.packBytes(UInt64(count), parts: 2).reversed()
            } else {
                prefix = Data([Mark.string4Byte]) + BinsonValue.packBytes(UInt64(count), parts: 4).reversed()
            }
            
            return prefix + utf8
            
        case .bytes(let data):
            let count = UInt32(data.count)
            
            let prefix: Data
            if count <= UInt32(Int8.max) {
                prefix = Data([Mark.bytes1Byte, UInt8(count)])
            } else if count <= UInt32(Int16.max) {
                prefix = Data([Mark.bytes2Byte]) + BinsonValue.packBytes(UInt64(count), parts: 2).reversed()
            } else {
                prefix = Data([Mark.bytes4Byte]) + BinsonValue.packBytes(UInt64(count), parts: 4).reversed()
            }
            
            return prefix + data
            
        case .array(let array):
            return array.pack()

        case let .object(dict):
            return dict.pack()
        }
    }

    public static func packBytes(_ value: UInt64, parts: Int) -> Data {
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
    public static func packNumber(_ i: Int64) -> Data {
        switch i {
        case Int64(Int8.min) ... Int64(Int8.max):
            let bytes = [Mark.integer1Byte,
                         UInt8(i & 0x000000FF)]
            return Data(bytes)

        case Int64(Int16.min) ... Int64(Int16.max):
            let bytes = [Mark.integer2Byte,
                         UInt8(i  & 0x000000FF),
                         UInt8((i & 0x0000FF00) >> 8)]
            return Data(bytes)

        case Int64(Int32.min) ... Int64(Int32.max):
            let bytes = [Mark.integer4Byte,
                         UInt8(i  & 0x000000FF),
                         UInt8((i & 0x0000FF00) >> 8),
                         UInt8((i & 0x00FF0000) >> 16),
                         UInt8((i & 0xFF000000) >> 24)]
            return Data(bytes)

        default:
            let bytes = [Mark.integer8Byte,
                         UInt8(i & 0x00000000000000FF),
                         UInt8(truncatingIfNeeded: i >> UInt64(8)),
                         UInt8(truncatingIfNeeded: i >> UInt64(16)),
                         UInt8(truncatingIfNeeded: i >> UInt64(24)),
                         UInt8(truncatingIfNeeded: i >> UInt64(32)),
                         UInt8(truncatingIfNeeded: i >> UInt64(40)),
                         UInt8(truncatingIfNeeded: i >> UInt64(48)),
                         UInt8(truncatingIfNeeded: i >> UInt64(56))]
            return Data(bytes)
        }
    }
}

