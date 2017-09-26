//  ExtensionsTests.swift
//  BinsonTests
//
//  Created by Kenneth Pernyer on 2017-09-25.
//  Copyright © 2017 Assa Abloy. All rights reserved.

import XCTest
@testable import Binson

class ExtensionsTests: XCTestCase {
    
    func testBase64() {
        let enc64 = "SGVqIGRpbiBnYW1sYSBiYWxqdsOkeHQ="
        let str = "Hej din gamla baljväxt"
        XCTAssertEqual(enc64.fromBase64(), str)
        XCTAssertEqual(str.base64, enc64)
        XCTAssertEqual(String(base64: enc64), str)
        XCTAssertNotEqual(String(base64: str), enc64)
    }
    
    func testData() {
        let data = "Hallon".data ?? Data()
        let str = "Hallon"
        
        XCTAssertEqual(data.string, str)
        XCTAssertEqual(str.data, data)
    }
}
