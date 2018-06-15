//  File: Binson.swift
//  Package: Binson
//
//  Created by Kenneth Pernyer on 2017-05-30.

import Foundation

public class Binson {
    private var dict = [String: BinsonValue]()

    public init() {
    }

    public init(values: [String: BinsonValue]) {
        dict = values
    }

    public func append(_ key: String, _ value: BinsonValue) -> Binson {
        dict[key] = value
        return self
    }

    public func append(values: [String: BinsonValue]) -> Binson {
        values.forEach { dict.updateValue($1, forKey: $0) }
        return self
    }

    public subscript(key: String) -> BinsonValue? {
        get { return dict[key] }
        set { dict[key] = newValue }
    }

    public func value(key: String) -> BinsonValue? {
        return dict[key]
    }

    public var values: [String: BinsonValue] {
        return dict
    }

    public func pack() -> Data {
        var raw = Data(bytes: [Mark.beginByte])

        for key in dict.keys.sorted() {
            raw += BinsonValue.string(key).pack()
            raw += dict[key]!.pack()
        }

        return raw + Data(bytes: [Mark.endByte])
    }

    public var data: Data {
        return self.pack()
    }
    
    public var hex: String {
        return self.pack().hex
    }
    
    public var json: String {
        let obj = jsonObject
        guard JSONSerialization.isValidJSONObject(obj) else {
            preconditionFailure("Not a valid JSON object")
        }

        let data = try! JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
        return data.toString()!
    }

    public var jsonObject: [String: Any] {
        return dict.mapValues { $0.toAny() }
    }

    public var count: Int {
        return dict.count
    }
}

/// Mark: - Operators
public func += (lhs: inout Binson, rhs: (String, BinsonValue)) {
    _ = lhs.append(rhs.0, rhs.1)
}

public func + (lhs: Binson, rhs: Binson) -> Binson {
    return lhs.append(values: rhs.values)
}

public func + (lhs: Binson, rhs: (String, BinsonValue)) -> Binson {
    return lhs.append(rhs.0, rhs.1)
}

public enum BinsonError: Error {
    case invalidArgument
    case insufficientData
    case invalidData
    case notFound
}

public enum Mark {
    static let beginByte: UInt8 = 0x40
    static let endByte: UInt8 = 0x41
    static let beginArrayByte: UInt8 = 0x42
    static let endArrayByte: UInt8 = 0x43
    static let trueByte: UInt8 = 0x44
    static let falseByte: UInt8 = 0x45
    static let integer1Byte: UInt8 = 0x10
    static let integer2Byte: UInt8 = 0x11
    static let integer4Byte: UInt8 = 0x12
    static let integer8Byte: UInt8 = 0x13
    static let doubleByte: UInt8 = 0x46
    static let string1Byte: UInt8 = 0x14
    static let string2Byte: UInt8 = 0x15
    static let string4Byte: UInt8 = 0x16
    static let bytes1Byte: UInt8 = 0x18
    static let bytes2Byte: UInt8 = 0x19
    static let bytes4Byte: UInt8 = 0x1a
}

extension Mark: CustomStringConvertible {
    public var description: String {
        switch self {
        default:
            return String(describing: self)
        }
    }
}

extension Binson: CustomStringConvertible {
    public var description: String {
        return "Binson " + self.json
    }
}

extension Binson: Equatable {
    public static func == (lhs: Binson, rhs: Binson) -> Bool {
        if lhs.dict.keys != rhs.dict.keys { return false }
        for key in lhs.dict.keys where lhs.dict[key] != rhs.dict[key] {
            return false
        }
        return true
    }
}

extension Binson: Hashable {
    public var hashValue: Int {
        return dict.count
    }
}

public class BinsonArray {
    private var array = [BinsonValue]()

    public init() {
    }

    public init(_ values: [BinsonValue]) {
        array = values
    }

    public subscript(index: Int) -> BinsonValue {
        get { return array[index] }
        set { array[index] = newValue }
    }

    public var count: Int {
        return array.count
    }

    public func append(_ value: BinsonValue) {
        array.append(value)
    }

    public func insert(_ value: BinsonValue, at index: Int) {
        array.insert(value, at: index)
    }

    public var values: [BinsonValue] {
        return array
    }

    public func pack() -> Data {
        let prefix = Data([Mark.beginArrayByte])
        let payload = array.flatMap { $0.pack() }
        let suffix = Data([Mark.endArrayByte])

        return prefix + payload + suffix
    }
}

extension BinsonArray: Hashable {
    public var hashValue: Int {
        return array.count
    }
}

extension BinsonArray: Equatable {
    public static func == (lhs: BinsonArray, rhs: BinsonArray) -> Bool {
        return lhs.array == rhs.array
    }
}

extension BinsonArray: CustomDebugStringConvertible {
    public var debugDescription: String {
        return array.debugDescription
    }
}

extension BinsonArray: CustomStringConvertible {
    public var description: String {
        return array.description
    }
}
