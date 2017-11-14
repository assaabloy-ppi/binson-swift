//  Value.swift
//  Binson

import Foundation

enum Constant {
    static let onebyte: Byte = 0x00
    static let twobytes: Byte = 0x01
    static let fourbytes: Byte = 0x02
    static let eightbytes: Byte = 0x03
    
    static let twoto7  = UInt64(Int8.max)
    static let twoto15 = UInt64(Int16.max)
    static let twoto31 = UInt64(Int32.max)
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
    init() {
        self = .nil
    }
    init(_ value: Bool) {
        self = .bool(value)
    }
    init(_ value: Int64) {
        self = .int(value)
    }
    init(_ value: Int32) {
        self = .int(Int64(value))
    }
    init(_ value: Int16) {
        self = .int(Int64(value))
    }
    init(_ value: Int8) {
        self = .int(Int64(value))
    }
    init<I: BinaryInteger>(_ value: I) {
        self = .int(Int64(value))
    }
    init(_ value: Float) {
        self = .double(Double(value))
    }
    init(_ value: Double) {
        self = .double(value)
    }
    init(_ value: String) {
        self = .string(value)
    }
    init(_ value: [Value]) {
        self = .array(value)
    }
    init(_ value: Value) {
        self = value
    }
    init(_ value: [Byte]) {
        self = .bytes(value)
    }
    init(_ value: Binson) {
        self = .object(value)
    }
    init(_ value: Any) {
        self = fromJson(jsonObject: value)
    }
}

extension Value: Equatable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case (.nil, .nil):
            return true
        case (.bool(let lhv), .bool(let rhv)):
            return lhv == rhv
        case (.int(let lhv), .int(let rhv)):
            return lhv == rhv
        case (.double(let lhv), .double(let rhv)):
            return lhv == rhv
        case (.double(let lhv), .int(let rhv)):
            return lhv == Double(rhv)
        case (.int(let lhv), .double(let rhv)):
            return Double(lhv) == rhv
        case (.string(let lhv), .string(let rhv)):
            return lhv == rhv
        case (.bytes(let lhv), .bytes(let rhv)):
            return lhv == rhv
        case (.array(let lhv), .array(let rhv)):
            return lhv == rhv
        case (.object(let lhv), .object(let rhv)):
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
        case .bytes(let bytes): return bytes.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1) } // djb2
        case .array(let array): return array.count
        case .object(let object): return object.hashValue
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
        case .object(let object):
            return "object(\(object.description))"
        }
    }
}

extension Value: CustomDebugStringConvertible {
    public var debugDescription: String { return description }
}

extension Value: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .nil
    }
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
    public init(integerLiteral value: Int) {
        self = .int(Int64(value))
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
    var count: Int? {
        switch self {
        case .array(let array):
            return array.count
        default:
            return nil
        }
    }
    
    var integerValue: Int64? {
        switch self {
        case .int(let value):
            return value
        default:
            return nil
        }
    }
    
    var arrayValue: [Value]? {
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
    
    var doubleValue: Double? {
        switch self {
        case .double(let value):
            return value
        default:
            return nil
        }
    }
    
    var stringValue: String? {
        switch self {
        case .string(let string):
            return string
        default:
            return nil
        }
    }
    
    var bytesValue: [Byte]? {
        switch self {
        case .bytes(let bytes):
            return bytes
        default:
            return nil
        }
    }
    
    var objectValue: Binson? {
        switch self {
        case .object(let object):
            return object
        default:
            return nil
        }
    }
    
    subscript(key: String) -> Value {
        get {
            switch self {
            case .object(let binson):
                return binson[key]
            default:
                return nil
            }
        }
    }
}

extension Value {
    func toJson() -> Any {
        switch self {
        case let .bool(value):
            return value
        case let .int(value):
            return value
        case let .double(value):
            return value
        case let .string(value):
            return value
        case let .bytes(bytes):
           let str = "0x"
           return str + bytes.toHexString()
        case let .array(array):
            return array.map {$0.json}
        case let .object(binson):
            return binson.jsonParams()
        case .nil:
            return ""
        }
    }
}

func fromJson(jsonObject: Any) -> Value {
    switch jsonObject {
    case let value as Bool:
        return Value(value)
    case let value as Int:
        return Value(Int64(value))
    case let value as Int64:
        return Value(value)
    case let value as Double:
        return Value(value)
    case let value as String:
        if value.hasPrefix("0x"), let bytes = [Byte](hex: value) {
            return Value(bytes)
        } else {
            return Value(value)
        }
    case let array as [Any]:
        return Value(array.map {fromJson(jsonObject: $0)})
    case let objects as [String: Any]:
        return Value(Builder.unpack(jsonparams: objects)!)
    default:
        return nil
    }
}
