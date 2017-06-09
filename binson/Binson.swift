//
//  File: Binson.swift
//  Package: Binson
//

import Foundation

public class Binson {
    var dict: [String: Value] = [:]

    // Created empty for testing
    public init() {
    }

    public init(values: [String: Value]) {
        dict = values
    }

    public init(data: Data) {
        self.unpack(data: data)
    }

    public func append(key: String, value: Value) -> Binson {
        dict[key] = value
        return self
    }

    public func append(values: [String: Value]) -> Binson {
        values.forEach { dict.updateValue($1, forKey: $0) }
        return self
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
    
    /// Building the Binson object from binary Data
    private func unpack(data: Data) {
        /// Start fresh
        if !dict.isEmpty {
            return
        }

        let value = data.first!
        let data = data.subdata(in: 1 ..< data.endIndex)

        if value != Mark.beginByte {
           return
        } else {

        }

    }
}

/// Mark: - Operators
func += (lhs: inout Binson, rhs: (String, Value)) {
    _ = lhs.append(key: rhs.0, value: rhs.1)
}

func + (lhs: Binson, rhs: Binson) -> Binson {
    return lhs.append(values: rhs.values())
}

func + (lhs: Binson, rhs: (String, Value)) -> Binson {
    return lhs.append(key: rhs.0, value: rhs.1)
}

public enum BinsonError: Error {
    case invalidArgument
    case insufficientData
    case invalidData
}

public enum Mark {
    static let beginByte       : Byte = 0x40
    static let endByte         : Byte = 0x41
    static let beginArrayByte  : Byte = 0x42
    static let endArrayByte    : Byte = 0x43
    static let trueByte        : Byte = 0x44
    static let falseByte       : Byte = 0x45
    static let integer1Byte    : Byte = 0x10
    static let integer2Byte    : Byte = 0x11
    static let integer4Byte    : Byte = 0x12
    static let integer8Byte    : Byte = 0x13
    static let doubleByte      : Byte = 0x46
    static let string1Byte     : Byte = 0x14
    static let string2Byte     : Byte = 0x15
    static let string4Byte     : Byte = 0x16
    static let bytes1Byte      : Byte = 0x18
    static let bytes2Byte      : Byte = 0x19
    static let bytes4Byte      : Byte = 0x1a
}

extension Mark: CustomStringConvertible {
    public var description: String {
        switch self {
        default:
            return String(describing: self)
        }
    }
}
