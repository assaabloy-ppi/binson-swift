//
//  CodableTests.swift
//  Binson-test
//
//  Created by Fredrik Littmarck on 2018-06-11.
//  Copyright © 2018 Assa Abloy Shared Technologies. All rights reserved.
//

import Foundation


import XCTest
@testable import Binson


class BinsonEncoderTests: XCTestCase {

    var encoder: BinsonEncoder!

    override func setUp() {
        encoder = BinsonEncoder()
    }

    func testEmptyEncodable() {
        class TestObj: Encodable {
        }

        do {
            let bn = try encoder.encode(TestObj())
            XCTAssertEqual(bn.hex, "4041")
        } catch {
            XCTFail()
        }
    }

    func testBasicEncodable() {
        class TestObj: Encodable {
            let c = "u"
        }

        do {
            let bn = try encoder.encode(TestObj())
            XCTAssertEqual(bn.hex, "4014016314017541")
        } catch {
            XCTFail()
        }
    }

    func testArrayEncodable() {
        class TestObj: Encodable {
            let co = ["co", "u"]
        }

        do {
            let bn = try encoder.encode(TestObj())
            XCTAssertEqual(bn.hex, "401402636f421402636f1401754341")
        } catch {
            XCTFail()
        }
    }

    func testIntegerEncodable() {
        class TestObj: Encodable {
            let i = 1
        }

        do {
            let bn = try encoder.encode(TestObj())
            XCTAssertEqual(bn.hex, "40140169100141")
        } catch {
            XCTFail()
        }
    }

    func testNegIntegerEncodable() {
        class TestObj: Encodable {
            let i = -1
        }

        do {
            let bn = try encoder.encode(TestObj())
            XCTAssertEqual(bn.hex, "4014016910ff41")
        } catch {
            XCTFail()
        }
    }

    func testNestedEncodable() {
        class TestObj: Encodable {
            class NestedTestObj: Encodable {
                let i = "Happy birthday"
                let r = false
            }
            let i = 230
            let e = 23.0992
            let b = true
            let t = Data([0x02, 0x02, 0x04])
            let array = ["co", "u"]
            let z = NestedTestObj()
        }

        do {
            let bn = try encoder.encode(TestObj())

            XCTAssertEqual(bn["b"], true)
            XCTAssertEqual(bn["i"], 230)
            XCTAssertEqual(bn["array"], [ "co", "u" ])
            XCTAssertEqual(bn["e"], 23.0992)
            XCTAssertEqual(bn["t"], BinsonValue([UInt8]([0x02, 0x02, 0x04])))

            XCTAssertNotEqual(bn["d"], 23.09)
            XCTAssertNotEqual(bn["e"], 23.09922)
            XCTAssertNotEqual(bn["e"], [ "co", "u" ])

            if let binson = bn["z"]?.objectValue {
                XCTAssertEqual(binson.value(key: "i"), "Happy birthday")
                XCTAssertEqual(binson.value(key: "r"), false)
            } else {
                XCTFail("Binson encode failed")
            }
        } catch {
            XCTFail()
        }
    }

    func testEncodeNil() {
        class TestObj: Encodable {
            let c: Int? = nil
        }

        do {
            let bn = try encoder.encode(TestObj())
            XCTAssertEqual(bn.hex, "4041")
        } catch {
            XCTFail()
        }
    }
}
