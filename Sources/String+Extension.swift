//  String+Extension.swift
//  Binson

import Foundation

/// String to Data
extension String {
    var data: Data? {
        return self.data(using: .utf8, allowLossyConversion: false)
    }
}

/// String to/from Base64
extension String {

    public init?(base64: String) {
        guard let data = Data(base64Encoded: base64) else { return nil }
        self = String(data: data, encoding: .utf8)!
    }
    
    /// Base64 property
    public var base64: String {
        return self.toBase64()
    }
    
    /// Encode a String to Base64
    public func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    /// Decode a String from Base64. Returns nil if unsuccessful.
    public func fromBase64() -> String? {
        return String(base64: self)
    }
}
