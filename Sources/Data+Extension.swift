//  Data+Extension.swift
//  Binson

import Foundation

extension Data {
    var bytes: [UInt8] {
        return Array(self)
    }

    var hex: String {
        return self.bytes.toHexString()
    }
    
    var string: String {
        return self.toString() ?? ""
    }
    
    func toHexString(_ separator: String = "") -> String {
        return self.bytes.toHexString(separator)
    }
    
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
    
    init(input: InputStream) {
        self.init()
        input.open()
        defer {
            input.close()
        }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            self.append(buffer, count: read)
        }
        buffer.deallocate()
    }
}
