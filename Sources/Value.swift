//  Value.swift
//  Binson

import Foundation

/// A BinsonValue can take either form as:
public enum BinsonValue: Hashable {
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case bytes(Data)
    case array(BinsonArray)
    case object(Binson)
}

/// Initializers for Convenience
extension BinsonValue {

    init(_ bool: Bool) { self = .bool(bool) }
    init(_ int: Int) { self = .int(Int64(int)) }
    init(_ int: Int8) { self = .int(Int64(int)) }
    init(_ int: Int16) { self = .int(Int64(int)) }
    init(_ int: Int32) { self = .int(Int64(int)) }
    init(_ int: Int64) { self = .int(int) }
    init(_ double: Double) { self = .double(double) }
    init(_ string: String) { self = .string(string) }
    init(_ bytes: Data) { self = .bytes(bytes) }
    init(_ value: [UInt8]) { self = .bytes(Data(bytes: value)) }
    init(_ array: BinsonArray) { self = .array(array) }
    init(_ value: [BinsonValue]) { self = .array(BinsonArray(value)) }
    init(_ object: Binson) { self = .object(object) }
}

extension BinsonValue: CustomStringConvertible {
    public var description: String {
        switch self {
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

extension BinsonValue: CustomDebugStringConvertible {
    public var debugDescription: String { return description }
}

extension BinsonValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension BinsonValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: BinsonValue...) {
        self = .array(BinsonArray(elements))
    }
}

extension BinsonValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension BinsonValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(Int64(value))
    }
}

extension BinsonValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension BinsonValue: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
}

extension BinsonValue: ExpressibleByExtendedGraphemeClusterLiteral {
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
}

extension BinsonValue {
    public var count: Int? {
        switch self {
        case .array(let array):
            return array.count
        case .object(let object):
            return object.count
        default:
            return nil
        }
    }
    
    public var integerValue: Int64? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }
    
    public var arrayValue: [BinsonValue]? {
        if case .array(let array) = self {
            return array.values
        }
        return nil
    }
    
    public var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }
    
    public var doubleValue: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }
    
    public var stringValue: String? {
        if case .string(let string) = self {
            return string
        }
        return nil
    }

    public var dataValue: Data? {
        if case .bytes(let data) = self {
            return data
        }
        return nil
    }

    public var bytesValue: [UInt8]? {
        if case .bytes(let data) = self {
            return Array(data)
        }
        return nil
    }
    
    public var objectValue: Binson? {
        if case .object(let object) = self {
            return object
        }
        return nil
    }
    
    public subscript(key: String) -> BinsonValue? {
        get {
            if case .object(let object) = self {
                return object[key]
            }
            return nil
        }
    }
}

extension BinsonValue {
    public func toAny() -> Any {
        switch self {
        case let .bool(value):
            return value
        case let .int(value):
            return value
        case let .double(value):
            return value
        case let .string(value):
            return value
        case let .bytes(data):
            return "0x" + data.toHexString()
        case let .array(array):
            return array.values.map { $0.toAny() }
        case let .object(object):
            return object.jsonObject
        }
    }

    public static func fromAny(_ any: Any) throws -> BinsonValue {
        switch any {
        case let value as Bool:
            return BinsonValue(value)
        case let value as Int:
            return BinsonValue(Int64(value))
        case let value as Int64:
            return BinsonValue(value)
        case let value as Double:
            return BinsonValue(value)
        case let value as String:
            if value.hasPrefix("0x"), let bytes = [UInt8](hex: value) {
                return BinsonValue(bytes)
            } else {
                return BinsonValue(value)
            }
        case let array as [Any]:
            return BinsonValue(try array.map { try fromAny($0)})
        case let object as [String: Any]:
            return BinsonValue(try Builder.unpack(jsonObject: object))
        default:
            throw BinsonError.invalidData
        }
    }
}
