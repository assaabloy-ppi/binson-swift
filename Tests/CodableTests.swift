//
//  CodableTests.swift
//  Binson-test
//
//  Created by Fredrik Littmarck on 2018-06-11.
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

    func testEncodeDate() {
        class TestObj: Encodable {
            var date: Date = Date(timeIntervalSinceReferenceDate: 551019904.34397399)
        }
        do {
            let bn = try encoder.encode(TestObj())
            XCTAssertEqual(bn["date"], 551019904.34397399)
        } catch {
            XCTFail()
        }
    }
}

class BinsonDecoderTests: XCTestCase {
    var decoder: BinsonDecoder!

    override func setUp() {
        decoder = BinsonDecoder()
    }

    func testEmptyDecodable() {
        class TestObj: Decodable {
        }

        do {
            _ = try decoder.decode(TestObj.self, from: Binson())
        } catch {
            XCTFail()
        }
    }

    func testBasicDecodable() {
        class TestObj: Decodable {
            var u: String
        }
        do {
            let obj = try decoder.decode(TestObj.self, from: Binson(values: ["u": "c"]))
            XCTAssertEqual(obj.u, "c")
        } catch {
            XCTFail()
        }
    }

    func testArrayDecodable() {
        class TestObj: Decodable {
            var co: [String]
        }

        do {
            let obj = try decoder.decode(TestObj.self, from: Binson(values: ["co": ["c", "e", "f"]]))
            XCTAssertEqual(obj.co, ["c", "e", "f"])
        } catch {
            XCTFail()
        }
    }

    func testIntegerDecodable() {
        class TestObj: Decodable {
            var i: Int
        }

        do {
            let obj = try decoder.decode(TestObj.self, from: Binson(values: ["i": 298]))
            XCTAssertEqual(obj.i, 298)
        } catch {
            XCTFail()
        }
    }

    func testNegIntegerDecodable() {
        class TestObj: Decodable {
            var i: Int
        }

        do {
            let obj = try decoder.decode(TestObj.self, from: Binson(values: ["i": -23298]))
            XCTAssertEqual(obj.i, -23298)
        } catch {
            XCTFail()
        }
    }

    func testDecodeNil() {
        class TestObj: Decodable {
            enum TestObjKeys: String, CodingKey {
                case co = "co"
            }

            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: TestObjKeys.self)
                if try container.decodeNil(forKey: .co) {
                    XCTFail()
                }
            }
        }

        do {
            _ = try decoder.decode(TestObj.self, from: Binson(values: ["co": 56]))
        } catch {
            XCTFail()
        }
    }

   func testNestedDecodable() {
        class TestObj: Decodable {
            class NestedTestObj: Decodable {
                var i: String
                var r: Bool
            }
            var i: Int
            var e: Double
            var b: Bool
            var t: Data
            var array: [String]
            var z: NestedTestObj
            var missing: Int?
            var present: Int?
        }

        let bn = Binson(values:
            ["b": true,
             "i": 230,
             "array": ["co", "u"],
             "e": 23.0992,
             "t": BinsonValue(Data([0x02, 0x02, 0x04])),
             "z": BinsonValue(Binson(values:
                ["i": "Happy birthday",
                 "r": false])),
             "present": 24
             ])

        do {
            let obj = try decoder.decode(TestObj.self, from: bn)

            XCTAssertEqual(obj.b, true)
            XCTAssertEqual(obj.i, 230)
            XCTAssertEqual(obj.array, [ "co", "u" ])
            XCTAssertEqual(obj.e, 23.0992)
            XCTAssertEqual(obj.t, Data([0x02, 0x02, 0x04]))
            XCTAssertNil(obj.missing)
            XCTAssertEqual(obj.present!, 24)

            let obj2 = obj.z
            XCTAssertEqual(obj2.i, "Happy birthday")
            XCTAssertEqual(obj2.r, false)
        } catch {
            XCTFail()
        }


    }
}
