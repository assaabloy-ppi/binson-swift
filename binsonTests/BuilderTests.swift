//
//  BuilderTests.swift
//  binson
//
//  Created by Kenneth Pernyer on 2017-06-08.
//  Copyright © 2017 Assa Abloy. All rights reserved.
//

import XCTest
@testable import binson

class BuilderTests: XCTestCase {
    
    func testUnpackEmptyDataBinson() {
        
        let empty_data = Data()
        
        if let b1 = Builder.unpack(data: empty_data) {
            XCTAssert(false, "\(b1) - Should have been empty")
        } else {
            XCTAssert(true, "Empty Data Should return NIL")
        }
    }
    
    func testUnpackBadDataBinson() {
        
        let bad_data = Data([0x80, 0x41])
        
        if let b1 = Builder.unpack(data: bad_data) {
            XCTAssert(false, "\(b1) - Should have been empty")
        } else {
            XCTAssert(true, "Bad Data Should return NIL")
        }
    }
    
    func testUnpackEmptyObjectDataBinson() {
        
        /// Correct but "Empty"
        let basic_data = Data([0x40, 0x41, 0x34])
        
        if let b1 = Builder.unpack(data: basic_data) {
            XCTAssert(true, "\(b1) - Created empty Binson Object")
        } else {
            XCTAssert(false, "Should not fail and return NIL")
        }
    }
    
    func testUnpackBinsonInBinson() {
        
        /// Correct Binson in Binson "Empty"
        /// {
        ///  "z": { }           // Parameters (Empty binson object)
        /// }
    
        let binson_data = Data([0x40, 0x14, 0x01, 0x7a, 0x40, 0x41, 0x41])
        
        if let b1 = Builder.unpack(data: binson_data) {
            XCTAssert(true, "\(b1) - Created Binson in Binson Object")
        } else {
            XCTAssert(false, "Should not fail and return NIL")
        }
    }

    func testUnpackBinson() {
        let empty_hex = ""
        let input_hex = "4041"
        
        let empty_data = Data()
        let input_data = Data([0x40, 0x41])

        if let b1 = Builder.unpack(hex: empty_hex) {
            XCTAssert(false, "\(b1) - Should have been empty")
        } else {
            XCTAssert(true, "Hepp")
        }
        
        if let b2 = Builder.unpack(data: empty_data) {
            XCTAssert(false, "\(b2) - Should have been empty")
        } else {
            XCTAssert(true, "Hepp")
        }
        
        if let b3 = Builder.unpack(hex: input_hex) {
            XCTAssertEqual(b3.hex, Binson().hex)
        } else {
            XCTAssert(false, "Hepp")
        }
        
        if let b4 = Builder.unpack(data: input_data) {
            XCTAssertEqual(b4.hex, Binson().hex)
        } else {
            XCTAssert(false, "Hepp")
        }
    }
    
    func testUnpackBytes() {
        var binson = Binson()
        binson += ("t", Value.bytes([0x02, 0x02]))
        
        let str = binson.hex
        XCTAssertEqual(str, "401401741802020241")
        
        let input_data = Data([0x40,
                               0x14, 0x01, 0x74,
                               0x18, 0x02, 0x02, 0x02,
                               0x41])
        
        if let unlock = Builder.unpack(data: input_data) {
            XCTAssertEqual(str, unlock.hex)
        }
        else {
            XCTAssert(false, "Hepp")
        }
    }

    func testUnpackInteger() {
        let input_data = Data([0x40,
                               0x14, 0x01, 0x69,
                               0x10, 0x01,
                               0x41])
        
        if let binson = Builder.unpack(data: input_data) {
            XCTAssertEqual(binson.value(key: "i"), 1)
        }
        else {
            XCTAssert(false, "Hepp")
        }
    }

    func testUnpackUnlock() {
        let expected = "4014016314017514016910011401741802020214017a404141"
        
        let input_data = Data([0x40, 0x14, 0x01, 0x63, 0x14, 0x01, 0x75, 0x14,
                               0x01, 0x69, 0x10, 0x01, 0x14, 0x01, 0x74, 0x18,
                               0x02, 0x02, 0x02, 0x14, 0x01, 0x7a, 0x40, 0x41,
                               0x41])
        
        if let unlock = Builder.unpack(data: input_data) {
            XCTAssertEqual(unlock.value(key: "c"), "u")
            XCTAssertEqual(unlock.value(key: "i"), 1)
            
            XCTAssertEqual(expected, unlock.hex)
        }
        else {
            XCTAssert(false, "Hepp")
        }
    }
}
