//
//  String+Extension.swift
//  Binson

import Foundation

extension String {
    func toData() -> Data? {
        return self.data(using: .utf8, allowLossyConversion: false)
    }
}

extension String {

    public init?(base64: String) {
        guard let data = Data(base64Encoded: base64) else { return nil }
        self = String(data: data, encoding: .utf8)!
    }
    
    func isAsciiAlpha() -> Bool {
        for c in characters {
            if (!(c >= "a" && c <= "z") && !(c >= "A" && c <= "Z") ) {
                return false
            }
        }
        return true
    }
    
    func isAlphaNumeric() -> Bool {
        let alphaNumeric = NSCharacterSet.alphanumerics
        let output = self.unicodeScalars.split { !alphaNumeric.contains($0)}.map(String.init)
        if output.count == 1 {
            if output[0] != self {
                return false
            }
        }
        return output.count == 1
    }
    
    public var base64: String {
        return self.toBase64()
    }
    
    /// Encode a String to Base64
    public func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    /// Decode a String from Base64. Returns nil if unsuccessful.
    public func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
