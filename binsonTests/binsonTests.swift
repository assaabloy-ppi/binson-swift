//
//  binsonTests.swift
//  binsonTests
//
//  Created by Kenneth Pernyer on 2017-06-07.
//  Copyright © 2017 Assa Abloy. All rights reserved.
//

import XCTest
@testable import binson

class binsonTests: XCTestCase {
    
    func testBasicBinson() {
        
        let binson = Binson()
        let str = binson.pack().toHexString("\\x")
        XCTAssertEqual(str, "\\x40\\x41")
    }
    
    func testStringBinson() {
        
        var binson = Binson()
        binson += ("c", "u")

        let str = binson.hex
        XCTAssertEqual(str, "4014016314017541")
    }

    func testIntegerBinson() {
        
        var binson = Binson()
        binson += ("i", 1)
        
        let str = binson.hex
        XCTAssertEqual(str, "40140169100141")
    }

    func testByteArrayBinson() {
        // bytes      = bytesLen raw
        // bytesLen   = %x18 int8 / %x19 int16 / %x1a int32

        // TODO: check initializers for Array and Bytes
        var binson = Binson()
        binson += ("t", Value.bytes([0x02, 0x02]))
        
        let str = binson.hex
        XCTAssertEqual(str, "401401741802020241")
    }
    
    func testBinsonInBinson() {
        
        var binson = Binson()
        binson += ("z", Value.object(Binson()))
        
        let str = binson.hex
        XCTAssertEqual(str, "4014017a404141")
    }

    /*
     Hex representation: 4014016314017514016910011401741802020214017a404141
     Array representation:
     0x40, 0x14, 0x01, 0x63, 0x14, 0x01, 0x75, 0x14,
     0x01, 0x69, 0x10, 0x01, 0x14, 0x01, 0x74, 0x18,
     0x02, 0x02, 0x02, 0x14, 0x01, 0x7a, 0x40, 0x41,
     0x41
     
     * {
     *   "c": "u",          // Conversation "u" (String)
     *   "i": 1,            // Converstation instance ID (Integer)
     *   "t": {0x02,0x02},  // Lock-thing id (Byte array)
     *   "z": { }           // Parameters (Empty binson object)
     * }
     *
     */
 
    
    func testOperator() {
        
        var unlock = Binson()
        unlock += ("c", "u")
        unlock += ("i", 1)
        unlock += ("t", Value.bytes([0x02, 0x02]))
        unlock += ("z", Value.object(Binson()))
        
        XCTAssertEqual(unlock.value(key: "c"), "u")
        XCTAssertEqual(unlock.value(key: "i"), 1)
        XCTAssertEqual(unlock.value(key: "t"), Value.bytes([0x02, 0x02]))
    }
    
    func testPackUnlock() {
        let expected_hex = "4014016314017514016910011401741802020214017a404141"
        let expected_data = Data([0x40, 0x14, 0x01, 0x63, 0x14, 0x01, 0x75, 0x14,
                                  0x01, 0x69, 0x10, 0x01, 0x14, 0x01, 0x74, 0x18,
                                  0x02, 0x02, 0x02, 0x14, 0x01, 0x7a, 0x40, 0x41,
                                  0x41])
        
        var unlock = Binson()
        unlock += ("c", "u")
        unlock += ("i", 1)
        unlock += ("t", Value.bytes([0x02, 0x02]))
        unlock += ("z", Value.object(Binson()))
        
        let actual_data = unlock.pack()
        let actual_hex = actual_data.hex
        
        XCTAssertEqual(expected_hex, actual_hex)
        XCTAssertEqual(expected_data, actual_data)
    }
}
