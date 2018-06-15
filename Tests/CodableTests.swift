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



    func testBasicTypes() {

        class TestObject: Encodable {
            class NestedTestObject: Encodable {
                var int8: Int8 = 10
                var data: Data = Data(bytes: [0x10, 0x20, 0x30])
            }

            var bool: Bool = true
            var int8: Int8 = 1
            var int16: Int16 = 2
            var int32: Int32 = 3
            var int64: Int64 = 4
            var double: Double = 3.14
            var object: NestedTestObject = NestedTestObject()
            var array: [Int32] = [0x234, 0x453453, 0x234235]
            var data: Data = Data(bytes: [0x50, 0x60, 0x70, 0x80])
        }

        let testObject = TestObject()

        let encoder = BinsonEncoder()
        do {
            let binson = try encoder.encode(testObject)
            print(binson)
            // TODO: Check result

        } catch {
            XCTFail()
        }
    }

    func testUnsupportedTypes() {

        class TestObject: Encodable {
            var uint8: UInt8 = 5
        }

        let testObject = TestObject()

        let encoder = BinsonEncoder()
        do {
            let binsonDict = try encoder.encode(testObject)
            print(binsonDict)

            // TODO: Check result

        } catch {
            XCTFail()
        }


    }
}
