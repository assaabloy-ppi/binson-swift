//  WhiteBoxTests.swift
//  binsonTests
//
//  Created by Kenneth Pernyer on 2017-06-07.
//  Copyright © 2017 Assa Abloy. All rights reserved.

import XCTest
@testable import Binson

class WhiteBoxTests: XCTestCase {

    func testInternalPacking() {
        let number: UInt64 = 80000000000
        let data1 = packBytes(number, parts: 1)
        // "00"
        
        let data2 = packBytes(number, parts: 2)
        // "2000"
        
        let data3 = packBytes(number, parts: 3)
        // "5f2000"
        
        let data4 = packBytes(number, parts: 4)
        // "a05f2000"
        
        let data5 = packBytes(number, parts: 5)
        // "12a05f2000"
        
        let data6 = packBytes(number, parts: 6)
        // "0012a05f2000"
        
        let data7 = packBytes(number, parts: 7)
        // "000012a05f2000"
        
        let data8 = packBytes(number, parts: 8)
        // "00000012a05f2000"
        
        /*
        print(data1.hex, data2.hex, data3.hex, data4.hex,
              data5.hex, data6.hex, data7.hex, data8.hex,
              separator: "\n")
         */
        
        XCTAssertEqual(data1.hex.count, 2)
        XCTAssertEqual(data2.hex.count, 4)
        XCTAssertEqual(data3.hex.count, 6)
        XCTAssertEqual(data4.hex.count, 8)
        XCTAssertEqual(data5.hex.count, 10)
        XCTAssertEqual(data6.hex.count, 12)
        XCTAssertEqual(data7.hex.count, 14)
        XCTAssertEqual(data8.hex.count, 16)

    }
    
    func testMarksBinson() {
        let desc = Mark.beginByte.description
        let desc2 = Mark.endByte.description
        XCTAssertEqual(desc, "64")
        XCTAssertEqual(desc2, "65")
    }
}
