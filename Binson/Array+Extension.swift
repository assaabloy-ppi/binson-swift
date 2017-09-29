//  Array+Extension.swift
//  Binson Utils
//
//  Support to go back and forth between Hex String and ByteArray

public typealias Byte = UInt8

extension Array where Element: BinaryInteger, Element.IntegerLiteralType == Byte {

    public init?(hex: String) {
        self = [Element]()
        self.reserveCapacity(hex.unicodeScalars.lazy.underestimatedCount)
        
        var buffer: Byte?
        var skip = hex.hasPrefix("0x") ? 2 : 0
        
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48 && char.value <= 102 else {
                self.removeAll()
                return nil
            }
            
            let v: Byte
            let c: Byte = Byte(char.value)
            
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                self.removeAll()
                return nil
            }
            
            if let b = buffer as? Element, let v = v as? Element {
                self.append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        
        if let b = buffer as? Element {
            self.append(b)
        }
    }
}

extension Array where Iterator.Element == Byte {
    
    public func toHexString(_ separator: String = "") -> String {
        return self.lazy.reduce("") {
            var str = String($1, radix: 16)
            if str.characters.count == 1 {
                str = "0" + str
            }
            return $0 + "\(separator)\(str)"
        }
    }
}

public func toByteArray<T>(_ value: T) -> [Byte] {
    var value = value
    return withUnsafeBytes(of: &value) { Array($0) }
}

public func fromByteArray<T>(_ value: [Byte], _: T.Type) -> T {
    return value.withUnsafeBytes {
        $0.baseAddress!.load(as: T.self)
    }
}

public func fromByteArray2<T>(_ value: [Byte], _: T.Type) -> T {
    return value.withUnsafeBufferPointer {
        $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) {
            $0.pointee
        }
    }
}

public func toHexArray(_ value: [Byte]) -> [String] {
    return value.map { String(format: "%02x", $0) }
}

public func toHexString(_ value: [Byte]) -> String {
    return toHexArray(value).joined()
}

func rotateLeft(_ value: Byte, by: Byte) -> Byte {
    return ((value << by) & 0xFF) | (value >> (8 - by))
}

func rotateLeft(_ value: UInt16, by: UInt16) -> UInt16 {
    return ((value << by) & 0xFFFF) | (value >> (16 - by))
}

func rotateLeft(_ value: UInt32, by: UInt32) -> UInt32 {
    return ((value << by) & 0xFFFFFFFF) | (value >> (32 - by))
}

func rotateLeft(_ value: UInt64, by: UInt64) -> UInt64 {
    return (value << by) | (value >> (64 - by))
}

func rotateRight(_ value: UInt16, by: UInt16) -> UInt16 {
    return (value >> by) | (value << (16 - by))
}

func rotateRight(_ value: UInt32, by: UInt32) -> UInt32 {
    return (value >> by) | (value << (32 - by))
}

func rotateRight(_ value: UInt64, by: UInt64) -> UInt64 {
    return ((value >> by) | (value << (64 - by)))
}

public func reversed(_ byte: Byte) -> Byte {
    var v = byte
    
    v = (v & 0xF0) >> 4 | (v & 0x0F) << 4
    v = (v & 0xCC) >> 2 | (v & 0x33) << 2
    v = (v & 0xAA) >> 1 | (v & 0x55) << 1
    return v
}

public func reversed(_ uint32: UInt32) -> UInt32 {
    var v = uint32
    v = ((v >> 1) & 0x55555555) | ((v & 0x55555555) << 1)
    v = ((v >> 2) & 0x33333333) | ((v & 0x33333333) << 2)
    v = ((v >> 4) & 0x0f0f0f0f) | ((v & 0x0f0f0f0f) << 4)
    v = ((v >> 8) & 0x00ff00ff) | ((v & 0x00ff00ff) << 8)
    v = ((v >> 16) & 0xffff) | ((v & 0xffff) << 16)
    return v
}
