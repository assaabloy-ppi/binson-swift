//
//  Builder.swift
//  Binson
//
//  Created by Kenneth Pernyer on 2017-05-12

import Foundation

public class Builder {

    /// Unpack from Hex
    ///
    public class func unpack(hex: String) -> Binson? {
        let raw = Data(bytes: Array<Byte>(hex: hex))
        return Builder.unpack(data: raw)
    }

    /// Unpack from InputStream
    ///
    public class func unpack(stream: InputStream) -> Binson? {
        let raw = Data(input: stream)
        return Builder.unpack(data: raw)
    }

    /// Unpack from Data
    ///
    public class func unpack(data: Data) -> Binson? {
        var binson = Binson()

        guard data.count >= 1 else {
            return nil
        }
        guard data[0] == Mark.beginByte else {
            return nil
        }

        guard data[0] == Mark.beginByte else {
            return nil
        }

        return binson
    }
}

func hepp(data: Data) {
while !data.isEmpty {
    var key: Value
    var value: Value
    
    //(key, data) = try Value.unpack(data)
    //(value, data) = try Value.unpack(data)
    
    // dict.updateValue(value, forKey: key.stringValue!)
}
}
