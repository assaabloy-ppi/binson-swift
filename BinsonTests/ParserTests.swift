//
//  ParserTests.swift
//  PoTSDK
//
//  Created by Kenneth Pernyer on 2017-09-01.
//  Copyright © 2017 Assa Abloy. All rights reserved.
//

import XCTest
@testable import Binson

class ParserTests: XCTestCase {
    
    func testParsingBinsonObject() {
        /*
        let value: Value = Value(["co", "u"])
        var binson = Binson()
        binson += ("co", value)
        binson += ("b", true)
        binson += ("z", "Olles pengar")
        binson += ("a", 7812)
        binson += ("zwerter", "Empty")
        
        let parser1 = BinsonParser(binson)
        let parser2 = BinsonParser(binson)
        let parser3 = BinsonParser(binson)

        do {
            guard let (k1, p1) = parser1.get() else {
                XCTAssert(true)
                return
            }
        
        XCTAssertEqual(k1, "a")
        XCTAssertEqual(p1, 7812)
        
        guard let (k2, v2) = try? parser2.skip(2).get() else {
            XCTAssert(true)
            return
        }
        
        XCTAssertEqual(k2, "co")
        XCTAssertEqual(v2, value)
        
        guard let (k3, v3) = try? parser3.goto("z").get() else {
            XCTAssert(true)
            return
        }
        
        XCTAssertEqual(k3, "co")
        XCTAssertEqual(v3, "Olles pengar")
        
        
        guard let (k4, v4) = parser4.goto("a") else {
            XCTAssert(true)
            return
        }
        
        guard let (k5, v5) = parser5.next() else {
            XCTAssert(true)
            return
        }
        
        XCTAssertEqual(k5, "zwerter")
        XCTAssertEqual(v5, "Empty")
        } catch BinsonError.notFound {
            XCTAssert(true)
        }
 
 */
    }
    
    func testParsingBinsonStream() {

    }
    
}
