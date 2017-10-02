//  BuilderTests.swift
//  binson
//
//  Created by Kenneth Pernyer on 2017-06-08.

import XCTest
@testable import Binson

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

    func testUnpackBinsonUnlock() {
        let bn = Binson()
            .append("c", "u")
            .append("i", 1)
            .append("z", .object(Binson()))
            .append("t", Value.bytes([0x02, 0x02]))
    
        let input_hex_b1 = "4014016314017514016910011401741802020214017a404141"
        let input_hex_b2 = "0x4014016314017514016910011401741802020214017a404141"
        
        if let b4 = Builder.unpack(hex: input_hex_b1) {
            XCTAssertEqual(b4.hex, bn.hex)
        } else {
            XCTAssert(false, "Hepp")
        }
        
        if let b5 = Builder.unpack(hex: input_hex_b2) {
            XCTAssertEqual(b5.hex, bn.hex)
        } else {
            XCTAssert(false, "Hepp")
        }
    }

    func testUnpackBinson() {
        let empty_hex_a1 = ""
        let empty_hex_a2 = "0x"

        let input_hex_a1 = "4041"
        let input_hex_a2 = "0x4041"

        let empty_data = Data()
        let input_data = Data([0x40, 0x41])

        if let b1 = Builder.unpack(hex: empty_hex_a1) {
            XCTAssert(false, "\(b1) - Should have been empty")
        } else {
            XCTAssert(true, "Hepp")
        }
        
        if let b2 = Builder.unpack(hex: empty_hex_a2) {
            XCTAssert(false, "\(b2) - Should have been empty")
        } else {
            XCTAssert(true, "Hepp")
        }
        
        if let b3 = Builder.unpack(data: empty_data) {
            XCTAssert(false, "\(b3) - Should have been empty")
        } else {
            XCTAssert(true, "Hepp")
        }
        
        if let b4 = Builder.unpack(hex: input_hex_a1) {
            XCTAssertEqual(b4.hex, Binson().hex)
        } else {
            XCTAssert(false, "Hepp")
        }
        
        if let b5 = Builder.unpack(hex: input_hex_a2) {
            XCTAssertEqual(b5.hex, Binson().hex)
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
        } else {
            XCTAssert(false, "Hepp")
        }
    }
    
    func testUnpack230Bytes() {
        let input_data = Data([0x40, 0x14, 0x01, 0x63, 0x19, 0xe6, 0x00, 0xae, 0xc2, 0x08, 0x96, 0x14, 0xa2, 0xe9, 0x42, 0x5d, 0x95, 0x24, 0x37, 0xc6, 0x11, 0xb2, 0xc2, 0xa6, 0xe1, 0xb3, 0x33, 0xe6, 0x2c, 0x1f, 0xf8, 0x09, 0xa6, 0x45, 0x3a, 0x33, 0x02, 0x89, 0x2f, 0x88, 0x19, 0x6a, 0x60, 0x1f, 0xc4, 0xdc, 0xfd, 0xbb, 0x62, 0x89, 0xdc, 0xf4, 0xec, 0x21, 0xf2, 0xa9, 0x6a, 0xda, 0xcc, 0x49, 0x30, 0x0f, 0xa7, 0x65, 0x65, 0x2d, 0xec, 0x10, 0xcb, 0xd5, 0x0d, 0x40, 0x14, 0x01, 0x61, 0x18, 0x01, 0x0f, 0x14, 0x02, 0x66, 0x72, 0x18, 0x20, 0x9d, 0x1e, 0x40, 0xe2, 0xf2, 0xd4, 0x56, 0xf9, 0xab, 0x21, 0xa7, 0xc8, 0x4a, 0x23, 0x1b, 0xc9, 0x4f, 0x87, 0x90, 0xa3, 0x22, 0x52, 0x0f, 0x1a, 0x60, 0x61, 0xe6, 0xcc, 0x0a, 0xa9, 0xf7, 0xc9, 0x14, 0x01, 0x70, 0x42, 0x18, 0x21, 0x0a, 0x35, 0x72, 0x39, 0xb7, 0x0e, 0xd9, 0x4c, 0x61, 0x1c, 0x4f, 0xaf, 0xef, 0x19, 0x29, 0x9d, 0x01, 0xc1, 0x8c, 0xda, 0xba, 0xe1, 0xe2, 0x4d, 0xbb, 0xdd, 0x56, 0xd6, 0xae, 0xf6, 0x0c, 0x76, 0x5d, 0x18, 0x02, 0x14, 0x15, 0x14, 0x02, 0x6c, 0x75, 0x43, 0x14, 0x02, 0x74, 0x63, 0x18, 0x0c, 0x50, 0x01, 0x0b, 0xcc, 0x7c, 0x01, 0x6b, 0xf3, 0x7c, 0x01, 0x00, 0x00, 0x14, 0x02, 0x74, 0x6e, 0x14, 0x0a, 0x44, 0x65, 0x6d, 0x6f, 0x43, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x14, 0x02, 0x74, 0x6f, 0x18, 0x20, 0x55, 0x29, 0xce, 0x8c, 0xcf, 0x68, 0xc0, 0xb8, 0xac, 0x19, 0xd4, 0x37, 0xab, 0x0f, 0x5b, 0x32, 0x72, 0x37, 0x82, 0x60, 0x8e, 0x93, 0xc6, 0x26, 0x4f, 0x18, 0x4b, 0xa1, 0x52, 0xc2, 0x35, 0x7b, 0x41, 0x41 ])
        if let binson = Builder.unpack(data: input_data) {
            XCTAssertEqual(binson["c"].bytesValue?.count, 230 )
            XCTAssertEqual(input_data.hex, binson.hex)
        } else {
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
        } else {
            XCTAssert(false, "Hepp")
        }
    }

    func testUnpackUnlock() {
        let expected = "4014016314017514016910011401741802020214017a404141"
        
        let input_data = Data([0x40, 0x14, 0x01, 0x63, 0x14, 0x01, 0x75, 0x14,
                               0x01, 0x69, 0x10, 0x01, 0x14, 0x01, 0x74, 0x18,
                               0x02, 0x02, 0x02, 0x14, 0x01, 0x7a, 0x40, 0x41,
                               0x41])
        
        let bn = Binson()
            .append("c", "u")
            .append("i", 1)
            .append("z", .object(Binson()))
            .append("t", Value.bytes([0x02, 0x02]))
        
        if let unlock = Builder.unpack(data: input_data) {
            XCTAssertEqual(unlock["c"], "u")
            XCTAssertEqual(unlock["i"], 1)
            
            XCTAssertEqual(bn, unlock)
            XCTAssertEqual(expected, unlock.hex)
        } else {
            XCTAssert(false, "Hepp")
        }
    }
    
    func testUnpackLongerTag() {

        let expected = "401402636f14017541"

        let input_data = Data([0x40, 0x14, 0x02, 0x63, 0x6f, 0x14, 0x01, 0x75, 0x41])
        
        if let unlock = Builder.unpack(data: input_data) {
            XCTAssertEqual(unlock.value(key: "co"), "u")
            
            XCTAssertEqual(expected, unlock.hex)
        } else {
            XCTAssert(false, "Hepp")
        }
    }
    
    func testUnpackLongInteger() {
        
        let expected = "4014016311e60041"
        
        let input_data = Data([0x40, 0x14, 0x01, 0x63, 0x11, 0xe6, 0x00, 0x41])
        
        if let binson = Builder.unpack(data: input_data) {
            // print(binson.description)
            XCTAssertEqual(binson.value(key: "c"), 230)
            
            XCTAssertEqual(expected, binson.hex)
        } else {
            XCTAssert(false, "Hepp")
        }
    }
    
    func testUnpackArray() {
        let input_data = Data([0x40, 0x14, 0x02, 0x63, 0x6f, 0x42, 0x14, 0x02, 0x63, 0x6f, 0x14, 0x01, 0x75, 0x43, 0x41])

        if let binson = Builder.unpack(data: input_data) {
            XCTAssertEqual(binson.value(key: "co"), Value(["co", "u"]))
            
            XCTAssertEqual(input_data.hex, binson.hex)
        } else {
            XCTAssert(false, "Hepp")
        }
    }
    
    func testUnpackDelegation() {

        let delegation = Data([0x40, 0x14, 0x05, 0x63, 0x68, 0x61, 0x69, 0x6e, 0x40, 0x14, 0x02, 0x63, 0x68, 0x42, 0x19, 0xe6, 0x00, 0xae, 0xc2, 0x08, 0x96, 0x14, 0xa2, 0xe9, 0x42, 0x5d, 0x95, 0x24, 0x37, 0xc6, 0x11, 0xb2, 0xc2, 0xa6, 0xe1, 0xb3, 0x33, 0xe6, 0x2c, 0x1f, 0xf8, 0x09, 0xa6, 0x45, 0x3a, 0x33, 0x02, 0x89, 0x2f, 0x88, 0x19, 0x6a, 0x60, 0x1f, 0xc4, 0xdc, 0xfd, 0xbb, 0x62, 0x89, 0xdc, 0xf4, 0xec, 0x21, 0xf2, 0xa9, 0x6a, 0xda, 0xcc, 0x49, 0x30, 0x0f, 0xa7, 0x65, 0x65, 0x2d, 0xec, 0x10, 0xcb, 0xd5, 0x0d, 0x40, 0x14, 0x01, 0x61, 0x18, 0x01, 0x0f, 0x14, 0x02, 0x66, 0x72, 0x18, 0x20, 0x9d, 0x1e, 0x40, 0xe2, 0xf2, 0xd4, 0x56, 0xf9, 0xab, 0x21, 0xa7, 0xc8, 0x4a, 0x23, 0x1b, 0xc9, 0x4f, 0x87, 0x90, 0xa3, 0x22, 0x52, 0x0f, 0x1a, 0x60, 0x61, 0xe6, 0xcc, 0x0a, 0xa9, 0xf7, 0xc9, 0x14, 0x01, 0x70, 0x42, 0x18, 0x21, 0x0a, 0x35, 0x72, 0x39, 0xb7, 0x0e, 0xd9, 0x4c, 0x61, 0x1c, 0x4f, 0xaf, 0xef, 0x19, 0x29, 0x9d, 0x01, 0xc1, 0x8c, 0xda, 0xba, 0xe1, 0xe2, 0x4d, 0xbb, 0xdd, 0x56, 0xd6, 0xae, 0xf6, 0x0c, 0x76, 0x5d, 0x18, 0x02, 0x14, 0x15, 0x14, 0x02, 0x6c, 0x75, 0x43, 0x14, 0x02, 0x74, 0x63, 0x18, 0x0c, 0x50, 0x01, 0x0b, 0xcc, 0x7c, 0x01, 0x6b, 0xf3, 0x7c, 0x01, 0x00, 0x00, 0x14, 0x02, 0x74, 0x6e, 0x14, 0x0a, 0x44, 0x65, 0x6d, 0x6f, 0x43, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x14, 0x02, 0x74, 0x6f, 0x18, 0x20, 0x55, 0x29, 0xce, 0x8c, 0xcf, 0x68, 0xc0, 0xb8, 0xac, 0x19, 0xd4, 0x37, 0xab, 0x0f, 0x5b, 0x32, 0x72, 0x37, 0x82, 0x60, 0x8e, 0x93, 0xc6, 0x26, 0x4f, 0x18, 0x4b, 0xa1, 0x52, 0xc2, 0x35, 0x7b, 0x41, 0x43, 0x41, 0x14, 0x04, 0x68, 0x6f, 0x73, 0x74, 0x40, 0x14, 0x03, 0x64, 0x6f, 0x63, 0x42, 0x14, 0x02, 0x65, 0x6e, 0x14, 0x00, 0x43, 0x14, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x42, 0x14, 0x02, 0x65, 0x6e, 0x14, 0x03, 0x48, 0x65, 0x6a, 0x43, 0x14, 0x03, 0x70, 0x75, 0x62, 0x18, 0x20, 0x35, 0x72, 0x39, 0xb7, 0x0e, 0xd9, 0x4c, 0x61, 0x1c, 0x4f, 0xaf, 0xef, 0x19, 0x29, 0x9d, 0x01, 0xc1, 0x8c, 0xda, 0xba, 0xe1, 0xe2, 0x4d, 0xbb, 0xdd, 0x56, 0xd6, 0xae, 0xf6, 0x0c, 0x76, 0x5d, 0x41, 0x14, 0x0a, 0x6b, 0x65, 0x79, 0x48, 0x6f, 0x6c, 0x64, 0x65, 0x72, 0x73, 0x42, 0x40, 0x14, 0x03, 0x64, 0x6f, 0x63, 0x42, 0x14, 0x02, 0x65, 0x6e, 0x14, 0x00, 0x43, 0x14, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x42, 0x14, 0x02, 0x65, 0x6e, 0x14, 0x04, 0x48, 0x61, 0x77, 0x6b, 0x43, 0x14, 0x03, 0x70, 0x75, 0x62, 0x18, 0x20, 0x9d, 0x1e, 0x40, 0xe2, 0xf2, 0xd4, 0x56, 0xf9, 0xab, 0x21, 0xa7, 0xc8, 0x4a, 0x23, 0x1b, 0xc9, 0x4f, 0x87, 0x90, 0xa3, 0x22, 0x52, 0x0f, 0x1a, 0x60, 0x61, 0xe6, 0xcc, 0x0a, 0xa9, 0xf7, 0xc9, 0x41, 0x40, 0x14, 0x03, 0x64, 0x6f, 0x63, 0x42, 0x14, 0x02, 0x65, 0x6e, 0x14, 0x00, 0x43, 0x14, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x42, 0x14, 0x02, 0x65, 0x6e, 0x14, 0x0a, 0x44, 0x65, 0x6d, 0x6f, 0x43, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x43, 0x14, 0x03, 0x70, 0x75, 0x62, 0x18, 0x20, 0x55, 0x29, 0xce, 0x8c, 0xcf, 0x68, 0xc0, 0xb8, 0xac, 0x19, 0xd4, 0x37, 0xab, 0x0f, 0x5b, 0x32, 0x72, 0x37, 0x82, 0x60, 0x8e, 0x93, 0xc6, 0x26, 0x4f, 0x18, 0x4b, 0xa1, 0x52, 0xc2, 0x35, 0x7b, 0x41, 0x43, 0x14, 0x04, 0x75, 0x6e, 0x69, 0x74, 0x40, 0x14, 0x03, 0x64, 0x6f, 0x63, 0x42, 0x14, 0x02, 0x65, 0x6e, 0x14, 0x27, 0x50, 0x65, 0x72, 0x6d, 0x69, 0x73, 0x73, 0x69, 0x6f, 0x6e, 0x20, 0x74, 0x6f, 0x20, 0x6c, 0x6f, 0x63, 0x6b, 0x20, 0x61, 0x6e, 0x64, 0x20, 0x75, 0x6e, 0x6c, 0x6f, 0x63, 0x6b, 0x20, 0x74, 0x68, 0x65, 0x20, 0x6c, 0x6f, 0x63, 0x6b, 0x2e, 0x43, 0x14, 0x06, 0x68, 0x70, 0x4e, 0x61, 0x6d, 0x65, 0x14, 0x02, 0x6c, 0x75, 0x14, 0x05, 0x6c, 0x65, 0x76, 0x65, 0x6c, 0x10, 0x02, 0x14, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x42, 0x14, 0x02, 0x65, 0x6e, 0x14, 0x0b, 0x6c, 0x6f, 0x63, 0x6b, 0x2f, 0x75, 0x6e, 0x6c, 0x6f, 0x63, 0x6b, 0x43, 0x14, 0x01, 0x70, 0x42, 0x18, 0x02, 0x14, 0x15, 0x14, 0x02, 0x6c, 0x75, 0x43, 0x14, 0x04, 0x74, 0x79, 0x70, 0x65, 0x14, 0x02, 0x68, 0x70, 0x41, 0x41])
        
        if let binsonDelegation = Builder.unpack(data: delegation) {
            // print(binsonDelegation.description)
            XCTAssertEqual(delegation.hex, binsonDelegation.hex)
        } else {
            XCTAssert(false, "Hepp")
        }
    }
    
    func testStaticJSONtoBinson() {
        let json =
        """
         {
              "b" : true,
              "i" : 230,
              "array" : [ "co", "u" ],
              "e" : 23.099229999999999,
              "d" : 23,
              "t" : "0x020204",
               "bertil" : "0xBertil",
             "z" : {
                    "r" : false,
                    "i" : "Happy birthday"
              }
          }
        """
        
        let bn = Builder.unpack(jsonstring: json)!
        XCTAssertEqual(bn["b"], true)
        XCTAssertEqual(bn["i"], 230)
        XCTAssertEqual(bn["array"], [ "co", "u" ])
        XCTAssertEqual(bn["e"], 23.099229999999999)
        XCTAssertEqual(bn["d"], 23)
        XCTAssertEqual(bn["t"], Value.bytes([0x02, 0x02, 0x04]))
        XCTAssertEqual(bn["bertil"], "0xBertil")

        XCTAssertNotEqual(bn.value(key: "d"), 23.09)
        XCTAssertNotEqual(bn.value(key: "e"), 23.09922)
        XCTAssertNotEqual(bn.value(key: "e"), [ "co", "u" ])
        
        if let bn2 = bn["z"].objectValue {
            XCTAssertEqual(bn2.value(key: "i"), "Happy birthday")
            XCTAssertEqual(bn2.value(key: "r"), false)
        } else {
            XCTAssert(false)
        }
    }
}
