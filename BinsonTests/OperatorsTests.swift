//
//  OperatorsTests.swift
//  binson
//
//  Created by Kenneth Pernyer on 2017-06-08.
//  Copyright © 2017 Assa Abloy. All rights reserved.
//

import XCTest
@testable import Binson

class OperatorsTests: XCTestCase {
    func testBinsonPlus() {
        
        var a = Binson()
        a += ("i", 1)

        var b = Binson()
        b += ("c", "u")
        
        // Add fields only ones, present in alphabetic order
        let c = a + b + a + b

        let str = c.pack().hex
        XCTAssertEqual(str, "40140163140175140169100141")
        
        let d = c + ("t", Value.bytes([0x02, 0x02]))
        let str2 = d.pack().hex
        XCTAssertEqual(str2, "4014016314017514016910011401741802020241")
    }
}
