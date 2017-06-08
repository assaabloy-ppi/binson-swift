//
//  Data+Extension.swift
//  Binson
//

import Foundation

extension Data {

    public var bytes: [Byte] {
        return Array(self)
    }

    public var hex: String {
        return self.bytes.toHexString()
    }
    
    public func toHexString(_ separator: String = "") -> String {
        return self.bytes.toHexString(separator)
    }
    
    public func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
    
    func toDictionary() -> [String: AnyObject]? {
        return NSKeyedUnarchiver.unarchiveObject(with: self) as? [String: AnyObject]
    }
    
    public init(input: InputStream) {
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
        buffer.deallocate(capacity: bufferSize)
    }
}

