//
//  File: Binson.swift
//  Package: Binson
//

import Foundation

public class Binson {
    private var dict: [String: Value] = [:]

    public init() {
    }

    public init(values: [String: Value]) {
        dict = values
    }

    public func append(_ key: String, _ value: Value) -> Binson {
        dict[key] = value
        return self
    }

    public func append(values: [String: Value]) -> Binson {
        values.forEach { dict.updateValue($1, forKey: $0) }
        return self
    }

    public subscript(key: String) -> Value? {
        return dict[key]
    }
    
    public func value(key: String) -> Value? {
        return dict[key]
    }
    
    public func values() -> [String : Value] {
        return dict
    }

    public func pack() -> Data {
        var raw = Data(bytes: [Mark.beginByte])

        for key in dict.keys.sorted() {
            raw += Value.string(key).pack()
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
        do {
            let params = self.jsonParams()
            let data = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            return data.toString()!
        } catch {
            return "{}"
        }
    }

    public func jsonParams() -> [String: Any] {
        var params = [String: Any]()
        
        for key in dict.keys.sorted() {
            params[key] = dict[key]!.json
        }
        
        return params
    }
}

/// Mark: - Operators
public func += (lhs: inout Binson, rhs: (String, Value)) {
    _ = lhs.append(rhs.0, rhs.1)
}

public func + (lhs: Binson, rhs: Binson) -> Binson {
    return lhs.append(values: rhs.values())
}

public func + (lhs: Binson, rhs: (String, Value)) -> Binson {
    return lhs.append(rhs.0, rhs.1)
}

public enum BinsonError: Error {
    case invalidArgument
    case insufficientData
    case invalidData
    case notFound
}

public enum Mark {
    static let beginByte: Byte = 0x40
    static let endByte: Byte = 0x41
    static let beginArrayByte: Byte = 0x42
    static let endArrayByte: Byte = 0x43
    static let trueByte: Byte = 0x44
    static let falseByte: Byte = 0x45
    static let integer1Byte: Byte = 0x10
    static let integer2Byte: Byte = 0x11
    static let integer4Byte: Byte = 0x12
    static let integer8Byte: Byte = 0x13
    static let doubleByte: Byte = 0x46
    static let string1Byte: Byte = 0x14
    static let string2Byte: Byte = 0x15
    static let string4Byte: Byte = 0x16
    static let bytes1Byte: Byte = 0x18
    static let bytes2Byte: Byte = 0x19
    static let bytes4Byte: Byte = 0x1a
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
