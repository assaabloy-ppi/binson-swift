//
//  BinsonIntegerTests.swift
//  Binson-test
//
//  Created by Kenneth Pernyer on 2017-11-01.
//

import XCTest
@testable import Binson

/*
 Example 129:   4014016911810041
 Example 128:   4014016911800041
 Example 1:   40140169 1001 41
 Example 0:   40140169100041
 Example -1:   4014016910ff41
 Example -128:   40140169108041
 Example -129:   40140169 117fff 41
 Example -32768:   4014016911008041
 Example -32769:   4014016912ff7fffff41
 Example -2147483648:   40140169120000008041
 Example -2147483649:   40140169 13ffffff7fffffffff 41
 Example -9223372036854775808:   4014016913000000000000008041
 */

class BinsonIntegerTests: XCTestCase {
    typealias Value = BinsonValue

    let posx10: (low: Value, high: Value) = (1, 127)
    let posx11: (low: Value, high: Value) = (128, 32767)
    let posx12: (low: Value, high: Value) = (32768, 2147483647)
    let posx13: (low: Value, high: Value) = (2147483648, 9223372036854775807)
    
    let negx10: (low: Value, high: Value) = (0, -128)
    let negx11: (low: Value, high: Value) = (-129, -32768)
    let negx12: (low: Value, high: Value) = (-32769, -2147483648)
    let negx13: (low: Value, high: Value) = (-2147483649, -9223372036854775808)
    
    /*
    X – Binson-objektet som hex-sträng
     127 -  0x40140161 107F 41
    -128 - 0x40140161 1080 41
    
     32767 -  0x40140161 11FF7F 41
    -32768 - 0x40140161 110080 41
    
     2147483647 -  0x40140161 12FFFFFF7F 41
    -2147483648 - 0x40140161 1200000080 41
    
     9223372036854775807 -  0x40140161 13FFFFFFFFFFFFFF7F 41
    -9223372036854775808 - 0x40140161 130000000000000080 41
     */
    
    func testPosIntegerValues() {
        let v0: Value = 0
        XCTAssertEqual(v0.hex, "1000")
        
        let v1: Value = 1
        XCTAssertEqual(v1.hex, "1001")
        
        let v1max: Value = Value(Int8.max)
        XCTAssertEqual(v1max.hex, "107f")
        
        let v1maxPlus: Value = Value(Int16(Int8.max)+1)
        XCTAssertEqual(v1maxPlus.hex, "118000")
        
        let v2max: Value = Value(Int16.max)
        XCTAssertEqual(v2max.hex, "11ff7f")
        
        let v2maxPlus: Value = Value(Int32(Int16.max)+1)
        XCTAssertEqual(v2maxPlus.hex, "1200800000")
        
        let v4max: Value = Value(Int32.max)
        XCTAssertEqual(v4max.hex, "12ffffff7f")
        
        let v4maxPlus: Value = Value(Int64(Int32.max)+1)
        XCTAssertEqual(v4maxPlus.hex, "130000008000000000")
        
        let v8max: Value = Value(Int64.max)
        XCTAssertEqual(v8max.hex, "13ffffffffffffff7f")
    }
    
    func testNegIntegerValues() {
        /*
        Example 0:
        40140169 1000 41
        Example -1:
        40140169 10ff 41
        Example -128:
        40140169 1080 41
        Example -129:
        40140169 117fff 41
        Example -32768:
        40140169 110080 41
        Example -32769:
        40140169 12ff7fffff 41
        Example -2147483648:
        40140169 1200000080 41
        */
        
        let v0: Value = Value(Int8(-0))
        XCTAssertEqual(v0.hex, "1000")
        
        let v1: Value = Value(Int8(-1))
        XCTAssertEqual(v1.hex, "10ff")
        
        let v1max: Value = Value(Int8.min)
        XCTAssertEqual(v1max.hex, "1080")
        
        let v1maxPlus: Value = Value(Int16(Int8.min)-1)
        XCTAssertEqual(v1maxPlus.hex, "117fff")
        
        let v2max: Value = Value(Int16.min)
        XCTAssertEqual(v2max.hex, "110080")
        
        let v2maxPlus: Value = Value(Int32(Int16.min)-1)
        XCTAssertEqual(v2maxPlus.hex, "12ff7fffff")
        
        let v4max: Value = Value(Int32.min)
        XCTAssertEqual(v4max.hex, "1200000080")
        
        let v4maxPlus: Value = Value(Int64(Int32.min)-1)
        XCTAssertEqual(v4maxPlus.hex, "13ffffff7fffffffff")
        
        let v8max: Value = Value(Int64.min)
        XCTAssertEqual(v8max.hex, "130000000000000080")
    }
}
