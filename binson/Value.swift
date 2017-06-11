//
//  Value.swift
//  Binson

import Foundation

public enum Constant {
    static let onebyte    : Byte = 0x00
    static let twobytes   : Byte = 0x01
    static let fourbytes  : Byte = 0x02
    static let eightbytes : Byte = 0x03
    
    static let twoto7     = UInt64(Int8.max)
    static let twoto15    = UInt64(Int16.max)
    static let twoto31    = UInt64(Int32.max)
}

/// A Value can take either form is:
public enum Value {
    case `nil`
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case bytes([Byte])
    case array([Value])
    case object(Binson)
}

/// Initializers for Convenience
extension Value {
    public init() {
        self = .nil
    }
    public init(_ value: Bool) {
        self = .bool(value)
    }
    public init(_ value: Int64) {
        self = .int(value)
    }
    public init(_ value: Float) {
        self = .double(Double(value))
    }
    public init(_ value: Double) {
        self = .double(value)
    }
    public init<I: Integer>(_ value: I) {
        self = .int(value.toIntMax())
    }
    public init(_ value: String) {
        self = .string(value)
    }
    public init(_ value: [Value]) {
        self = .array(value)
    }
    public init(_ value: Value) {
        self = value
    }
    public init(_ value: [Byte]) {
        self = .bytes(value)
    }
}

extension Value: Equatable {
    public static func ==(lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case (.nil, .nil):
            return true
        case (.bool(let lhv), .bool(let rhv)):
            return lhv == rhv
        case (.int(let lhv), .int(let rhv)):
            return lhv == rhv
        case (.double(let lhv), .double(let rhv)):
            return lhv == rhv
        case (.string(let lhv), .string(let rhv)):
            return lhv == rhv
        case (.bytes(let lhv), .bytes(let rhv)):
            return lhv == rhv
        case (.array(let lhv), .array(let rhv)):
            return lhv == rhv
        default:
            return false
        }
    }
}

extension Value: Hashable {
    public var hashValue: Int {
        switch self {
        case .nil: return 0
        case .bool(let value): return value.hashValue
        case .int(let value): return value.hashValue
        case .double(let value): return value.hashValue
        case .string(let string): return string.hashValue
        case .bytes(let bytes): return bytes.count
        case .array(let array): return array.count
        default: return 0
        }
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nil:
            return "nil"
        case .bool(let value):
            return "bool(\(value))"
        case .int(let value):
            return "int(\(value))"
        case .double(let value):
            return "double(\(value))"
        case .string(let string):
            return "string(\(string))"
        case .bytes(let bytes):
            return "bytes(\(bytes))"
        case .array(let array):
            return "array(\(array.description))"
        default: return "unknown"
        }
    }
}

extension Value : CustomDebugStringConvertible {
    public var debugDescription: String { return description }
}

extension Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension Value: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Value...) {
        self = .array(elements)
    }
}

extension Value: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) {
        self = .int(value)
    }
}

extension Value: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Value: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
}

extension Value: ExpressibleByExtendedGraphemeClusterLiteral {
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
}

extension Value {
    public var count: Int? {
        switch self {
        case .array(let array):
            return array.count
        default:
            return nil
        }
    }
    
    public var integerValue: Int64? {
        switch self {
        case .int(let value):
            return value
        default:
            return nil
        }
    }
    
    public var arrayValue: [Value]? {
        switch self {
        case .array(let array):
            return array
        default:
            return nil
        }
    }
    
    public var boolValue: Bool? {
        switch self {
        case .bool(let value):
            return value
        default:
            return nil
        }
    }
    
    public var doubleValue: Double? {
        switch self {
        case .double(let value):
            return value
        default:
            return nil
        }
    }
    
    public var stringValue: String? {
        switch self {
        case .string(let string):
            return string
        default:
            return nil
        }
    }
    
    public var bytesValue: [Byte]? {
        switch self {
        case .bytes(let bytes):
            return bytes
        default:
            return nil
        }
    }
}

func packBytes(_ value: UInt64, parts: Int) -> Data {
    precondition(parts > 0)
    
    let bytesw = stride(from: (8 * (parts - 1)), through: 0, by: -8).map { shift in
        return UInt8(truncatingBitPattern: value >> UInt64(shift))
    }
    
    return Data(bytesw)
}

func packNegative(_ value: Int64) -> Data {
    
    return Data()
}

/// Packs an unsigned integer into an array of bytes.
///
/// - returns: A Binson byte representation.
func packPositive(_ v: UInt64) -> Data {
    
    if v <=  Constant.twoto7 {
        return Data([Mark.integer1Byte, Byte(truncatingBitPattern: v)])
        
    } else if v <= Constant.twoto15 {
        return Data([Mark.integer2Byte]) + packBytes(v, parts: 2)
        
    } else if v <= Constant.twoto31 {
        return Data([Mark.integer4Byte]) + packBytes(v, parts: 4)
        
    } else {
        return Data([Mark.integer8Byte]) + packBytes(v, parts: 8)
    }
}

/// Packs an integer into a byte array. Depending on size it will require
/// 1 to 8 bytes (8 to 64 bits)/// Packs an unsigned integer into an array of bytes.
///
/// - returns: A Binson byte representation.
func packNumber(_ i: Int64) -> Data {
    if i >= 0 { return packPositive(UInt64(i)) }
    else { return packNegative(i)
        
    }
}

/// Packs a Value into an array of bytes.
///
/// - parameter value: The Value to encode
/// - returns: A Binson byte representation
///
extension Value {
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
            
            precondition(count <= 0xffff_ffff)
            
            let prefix: Data
            if count <= 0x19 {
                prefix = Data([Mark.string1Byte, Byte(count)])
            } else if count <= 0xff {
                prefix = Data([Mark.string2Byte, Byte(count)])
            } else {
                prefix = Data([Mark.string4Byte, Byte(count)])
            }
            
            return prefix + utf8
            
        case .bytes(let bytes):
            let count = UInt32(bytes.count)
            precondition(count <= 0xffff_ffff)
            
            let prefix: Data
            if count <= 0xff {
                prefix = Data([Mark.bytes1Byte, UInt8(count)])
            } else if count <= 0xffff {
                prefix = Data([Mark.bytes2Byte]) + packBytes(UInt64(count), parts: 2)
            } else {
                prefix = Data([Mark.bytes4Byte]) + packBytes(UInt64(count), parts: 4)
            }
            
            return prefix + bytes

            
        case .array(let array):
            let count = UInt32(array.count)
            precondition(count <= 0xffff_ffff)
            
            let prefix = Data([Mark.beginArrayByte])
            let payload = array.flatMap { $0.pack() }
            let suffix = Data([Mark.endArrayByte])
            
            return prefix + payload + suffix
            
        case .object(let binson):
            return binson.pack()
            
        default: return Data([0x00])
            
        }
    }
}

