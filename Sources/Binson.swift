//  File: Binson.swift
//  Package: Binson
//
//  Created by Kenneth Pernyer on 2017-05-30.

import Foundation

public class Binson {
    private var dict = [String: BinsonValue]()

    public init() {
    }

    /// Unpack from Data
    /// - parameter data: The binary representation in Data to unpack.
    public convenience init(data: Data) throws {
        let values = try Binson.unpackBinson(data: data)

        self.init(values: values)
    }

    /// Unpack from Hex
    /// - parameter data: The Hex string to unpack.
    public convenience init(hex: String) throws {
        guard let bytes = [UInt8](hex: hex) else {
            throw BinsonError.invalidData
        }
        let raw = Data(bytes: bytes)
        try self.init(data: raw)
    }

    /// Unpack from InputStream
    /// - parameter data: The byte input stream to unpack.
    public convenience init(stream: InputStream) throws {
        let raw = Data(input: stream)
        try self.init(data: raw)
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

    public func append(binson other: Binson) -> Binson {
        return append(values: other.dict)
    }

    public subscript(key: String) -> BinsonValue? {
        get { return dict[key] }
        set { dict[key] = newValue }
    }

    public func value(key: String) -> BinsonValue? {
        return dict[key]
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

    public var keys: Dictionary<String, BinsonValue>.Keys {
        return dict.keys
    }

    public var values: Dictionary<String, BinsonValue>.Values {
        return dict.values
    }
}


/// Mark: - Operators
public func += (lhs: inout Binson, rhs: (String, BinsonValue)) {
    _ = lhs.append(rhs.0, rhs.1)
}

public func + (lhs: Binson, rhs: Binson) -> Binson {
    return lhs.append(binson: rhs)
}

public func + (lhs: Binson, rhs: (String, BinsonValue)) -> Binson {
    return lhs.append(rhs.0, rhs.1)
}

extension Binson: CustomStringConvertible {
    public var description: String {
        return "Binson " + self.json
    }
}

extension Binson: Equatable {
    public static func == (lhs: Binson, rhs: Binson) -> Bool {
        return lhs.dict == rhs.dict
    }
}

extension Binson: Hashable {
    public var hashValue: Int {
        return dict.hashValue
    }
}

