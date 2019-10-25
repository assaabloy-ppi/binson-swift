//
//  Mark.swift
//  Binson
//
//  Created by Fredrik Littmarck on 2018-10-22.
//  Copyright © 2018 Assa Abloy Shared Technologies. All rights reserved.
//

import Foundation

public extension Binson {
    enum Mark {
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
}

extension Binson.Mark: CustomStringConvertible {
    public var description: String {
        switch self {
        default:
            return String(describing: self)
        }
    }
}
