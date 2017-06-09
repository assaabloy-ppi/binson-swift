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
            XCTAssert(false, "\(b3) - Should have been empty")
        } else {
            XCTAssert(true, "Hepp")
        }
        
        if let b4 = Builder.unpack(data: input_data) {
            XCTAssert(false, "\(b4) - Should have been empty")
        } else {
            XCTAssert(true, "Hepp")
        }
        
        // let b2 = Builder.unpack(data: input_data)!
        
        // XCTAssertEqual(b1.hex, Binson().hex)
        // XCTAssertEqual(b2.hex, Binson().hex)
    }
    
    /*
    func testUnpackUnlock() {
        let input_hex = "4014016314017514016910011401741802020214017a404141"
        let input_data = Data([0x40, 0x14, 0x01, 0x63, 0x14, 0x01, 0x75, 0x14,
                               0x01, 0x69, 0x10, 0x01, 0x14, 0x01, 0x74, 0x18,
                               0x02, 0x02, 0x02, 0x14, 0x01, 0x7a, 0x40, 0x41,
                               0x41])
        
        let unlock1 = Builder.unpack(hex: input_hex)!
        let unlock2 = Builder.unpack(data: input_data)!
        
        XCTAssertEqual(unlock1.value(key: "c"), "u")
        XCTAssertEqual(unlock2.value(key: "c"), "u")
        
        XCTAssertEqual(unlock1.value(key: "i"), 1)
        XCTAssertEqual(unlock2.value(key: "i"), 1)
        
        XCTAssertEqual(unlock1.value(key: "t"), [0x02,0x02])
        XCTAssertEqual(unlock2.value(key: "z"), Value.object(Binson()))
    }
 
    */
}
