//  WhiteBoxTests.swift
//  binsonTests
//
//  Created by Kenneth Pernyer on 2017-06-07.
//  Copyright © 2017 Assa Abloy. All rights reserved.

import XCTest
@testable import Binson

class WhiteBoxTests: XCTestCase {
    typealias Value = BinsonValue

    let posx10: (low: Int64, high: Int64) = (1, 127)
    let posx11: (low: Int64, high: Int64) = (128, 32767)
    let posx12: (low: Int64, high: Int64) = (32768, 2147483647)
    let posx13: (low: Int64, high: Int64) = (2147483648, 9223372036854775807)
    
    let negx10: (low: Int64, high: Int64) = (0, -128)
    let negx11: (low: Int64, high: Int64) = (-129, -32768)
    let negx12: (low: Int64, high: Int64) = (-32769, -2147483648)
    let negx13: (low: Int64, high: Int64) = (-2147483649, -9223372036854775808)
    
    func testNumbers() {
        let p_127: Data = Value.packNumber(127)
        let p_128: Data = Value.packNumber(128)
        let p_big: Data = Value.packNumber(32767)

        let n_128: Data = Value.packNumber(-128)
        let n_129: Data = Value.packNumber(-129)
        let n_sma: Data = Value.packNumber(-32768)
        
        do {
            let (p, _) = try Builder.unpackValue(p_127)
            XCTAssertEqual(127, p?.integerValue)
        } catch { XCTFail("Could not unpack number") }
        
        do {
            let (p, _) = try Builder.unpackValue(p_128)
            XCTAssertEqual(128, p?.integerValue)
        } catch { XCTFail("Could not unpack number") }
        
        do {
            let (p, _) = try Builder.unpackValue(p_big)
            XCTAssertEqual(32767, p?.integerValue)
        } catch { XCTFail("Could not unpack number") }
        
        do {
            let (n, _) = try Builder.unpackValue(n_128)
            XCTAssertEqual(-128, n?.integerValue)
        } catch { XCTFail("Could not unpack number") }
        
        do {
            let (n, _) = try Builder.unpackValue(n_129)
            XCTAssertEqual(-129, n?.integerValue)
        } catch { XCTFail("Could not unpack number") }
        
        do {
            let (n, _) = try Builder.unpackValue(n_sma)
            XCTAssertEqual(-32768, n?.integerValue)
        } catch { XCTFail("Could not unpack number") }
    }

    func testBackForthNumbers() {
        for i in [posx10, negx10, posx11, negx11, posx12, negx12, posx13, negx13] {
            let v_low = Value.packNumber(i.low)
            let v_high = Value.packNumber(i.high)
            
            do {
                let (low, _) = try Builder.unpackValue(v_low)
                let (high, _) = try Builder.unpackValue(v_high)
                
                XCTAssertEqual(i.low, low?.integerValue)
                XCTAssertEqual(i.high, high?.integerValue)

            } catch { XCTFail("Could not unpack number") }
        }
    }
    
    func testHighLow() {
        XCTAssertEqual(posx10.high, Int64(Int8.max))
        XCTAssertEqual(posx11.high, Int64(Int16.max))
        XCTAssertEqual(posx12.high, Int64(Int32.max))
        XCTAssertEqual(posx13.high, Int64(Int64.max))

        XCTAssertEqual(negx10.high, Int64(Int8.min))
        XCTAssertEqual(negx11.high, Int64(Int16.min))
        XCTAssertEqual(negx12.high, Int64(Int32.min))
        XCTAssertEqual(negx13.high, Int64(Int64.min))
        
        for i in [posx10, negx10] {
            let v_low = Value.packNumber(i.low)
            let v_high = Value.packNumber(i.high)

            XCTAssertEqual(v_low.count, 2)
            XCTAssertEqual(v_high.count, 2)
            XCTAssertEqual(v_low[0], 0x10)
            XCTAssertEqual(v_high[0], 0x10)
        }
        
        for i in [posx11, negx11] {
            let v_low = Value.packNumber(i.low)
            let v_high = Value.packNumber(i.high)
            
            XCTAssertEqual(v_low.count, 3)
            XCTAssertEqual(v_high.count, 3)
            XCTAssertEqual(v_low[0], 0x11)
            XCTAssertEqual(v_high[0], 0x11)
        }
        
        for i in [posx12, negx12] {
            let v_low = Value.packNumber(i.low)
            let v_high = Value.packNumber(i.high)
            
            XCTAssertEqual(v_low.count, 5)
            XCTAssertEqual(v_high.count, 5)
            XCTAssertEqual(v_low[0], 0x12)
            XCTAssertEqual(v_high[0], 0x12)
        }
        
        for i in [posx13, negx13] {
            let v_low = Value.packNumber(i.low)
            let v_high = Value.packNumber(i.high)
            
            XCTAssertEqual(v_low.count, 9)
            XCTAssertEqual(v_high.count, 9)
            XCTAssertEqual(v_low[0], 0x13)
            XCTAssertEqual(v_high[0], 0x13)
        }
    }
    
    func testPackNegativeInteger() {
        let v0: Int64 = 0
        let v0ee = Value.packNumber(v0)
        XCTAssertEqual(v0ee.hex, "1000")
        
        let v1: Int64 = -1
        let v1ee = Value.packNumber(v1)
        XCTAssertEqual(v1ee.hex, "10ff")
        
        let v1max = Int64(Int8.min)
        let v1eemax = Value.packNumber(v1max)
        XCTAssertEqual(v1eemax.hex, "1080")
        
        let v1max_plus = Int64(Int8.min) - 1
        let v1eemax_plus = Value.packNumber(v1max_plus)
        XCTAssertEqual(v1eemax_plus.hex, "117fff")
        
        let v2max = Int64(Int16.min)
        let v2eemax = Value.packNumber(v2max)
        XCTAssertEqual(v2eemax.hex, "110080")
        
        let v2max_plus = Int64(Int16.min) - 1
        let v2eemax_plus = Value.packNumber(v2max_plus)
        XCTAssertEqual(v2eemax_plus.hex, "12ff7fffff")
        
        let v4max = Int64(Int32.min)
        let v4eemax = Value.packNumber(v4max)
        XCTAssertEqual(v4eemax.hex, "1200000080")
        
        let v4max_plus = Int64(Int32.min) - 1
        let v4eemax_plus = Value.packNumber(v4max_plus)
        XCTAssertEqual(v4eemax_plus.hex, "13ffffff7fffffffff")
        
        let v8max = Int64.min
        let v8eemax = Value.packNumber(v8max)
        XCTAssertEqual(v8eemax.hex, "130000000000000080")
    }
    
    func testPackPositiveInteger() {
        let v0: Int64 = 0
        let v0ff = Value.packNumber(v0)
        let v0ee = Value.packNumber(v0)
        XCTAssertEqual(v0ff.hex, "1000")
        XCTAssertEqual(v0ee.hex, "1000")
        
        let v1: Int64 = 1
        let v1ff = Value.packNumber(v1)
        let v1ee = Value.packNumber(v1)
        XCTAssertEqual(v1ff.hex, "1001")
        XCTAssertEqual(v1ee.hex, "1001")
        
        let v1max = Int64(Int8.max)
        let v1ffmax = Value.packNumber(v1max)
        let v1eemax = Value.packNumber(v1max)
        XCTAssertEqual(v1ffmax.hex, "107f")
        XCTAssertEqual(v1eemax.hex, "107f")

        let v1max_plus = Int64(Int8.max) + 1
        let v1ffmax_plus = Value.packNumber(v1max_plus)
        let v1eemax_plus = Value.packNumber(v1max_plus)
        XCTAssertEqual(v1ffmax_plus.hex, "118000")
        XCTAssertEqual(v1eemax_plus.hex, "118000")
        
        let v2max = Int64(Int16.max)
        let v2ffmax = Value.packNumber(v2max)
        let v2eemax = Value.packNumber(v2max)
        XCTAssertEqual(v2ffmax.hex, "11ff7f")
        XCTAssertEqual(v2eemax.hex, "11ff7f")
        
        let v2max_plus = Int64(Int16.max) + 1
        let v2ffmax_plus = Value.packNumber(v2max_plus)
        let v2eemax_plus = Value.packNumber(v2max_plus)
        XCTAssertEqual(v2ffmax_plus.hex, "1200800000")
        XCTAssertEqual(v2eemax_plus.hex, "1200800000")
        
        let v4max = Int64(Int32.max)
        let v4ffmax = Value.packNumber(v4max)
        let v4eemax = Value.packNumber(v4max)
        XCTAssertEqual(v4ffmax.hex, "12ffffff7f")
        XCTAssertEqual(v4eemax.hex, "12ffffff7f")
        
        let v4max_plus = Int64(Int32.max) + 1
        let v4ffmax_plus = Value.packNumber(v4max_plus)
        let v4eemax_plus = Value.packNumber(v4max_plus)
        XCTAssertEqual(v4ffmax_plus.hex, "130000008000000000")
        XCTAssertEqual(v4eemax_plus.hex, "130000008000000000")
        
        let v8max = Int64.max
        let v8ffmax = Value.packNumber(v8max)
        let v8eemax = Value.packNumber(v8max)
        XCTAssertEqual(v8ffmax.hex, "13ffffffffffffff7f")
        XCTAssertEqual(v8eemax.hex, "13ffffffffffffff7f")
    }
    
    func testInternalPacking() {
        let number: UInt64 = 80000000000
        let data1 = Value.packBytes(number, parts: 1)
        XCTAssertEqual(data1.count, 1)
        // "00"
        
        let data2 = Value.packBytes(number, parts: 2)
        XCTAssertEqual(data2.count, 2)
        // "2000"
        
        let data3 = Value.packBytes(number, parts: 3)
        XCTAssertEqual(data3.count, 3)
        // "5f2000"
        
        let data4 = Value.packBytes(number, parts: 4)
        XCTAssertEqual(data4.count, 4)
        // "a05f2000"
        
        let data5 = Value.packBytes(number, parts: 5)
        XCTAssertEqual(data5.count, 5)
        // "12a05f2000"
        
        let data6 = Value.packBytes(number, parts: 6)
        XCTAssertEqual(data6.count, 6)
        // "0012a05f2000"
        
        let data7 = Value.packBytes(number, parts: 7)
        XCTAssertEqual(data7.count, 7)
        // "000012a05f2000"
        
        let data8 = Value.packBytes(number, parts: 8)
        XCTAssertEqual(data8.count, 8)
        // "00000012a05f2000"
        
        XCTAssertEqual(data1.hex.count, 2)
        XCTAssertEqual(data2.hex.count, 4)
        XCTAssertEqual(data3.hex.count, 6)
        XCTAssertEqual(data4.hex.count, 8)
        XCTAssertEqual(data5.hex.count, 10)
        XCTAssertEqual(data6.hex.count, 12)
        XCTAssertEqual(data7.hex.count, 14)
        XCTAssertEqual(data8.hex.count, 16)
    }
}
