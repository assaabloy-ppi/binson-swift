//  Array+Extension.swift
//  Binson Utils
//
//  Support to go back and forth between Hex String and ByteArray

public typealias Byte = UInt8

extension Array where Element: BinaryInteger, Element.IntegerLiteralType == Byte {

    init?(hex: String) {
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

    func toHexString(_ separator: String = "") -> String {
        return self.lazy.reduce("") {
            var str = String($1, radix: 16)
            if str.count == 1 {
                str = "0" + str
            }
            return $0 + "\(separator)\(str)"
        }
    }
}



