Binson Swift
============

[![Build Status](https://travis-ci.org/assaabloy-ppi/binson-swift.svg?branch=master)](https://travis-ci.org/assaabloy-ppi/binson-swift)
[![Codebeat Quality](https://codebeat.co/badges/82efe8db-c3e8-4817-b263-032199150179)](https://codebeat.co/projects/github-com-assaabloy-ppi-binson-swift-master)
[![Code Coverage](https://codecov.io/gh/assaabloy-ppi/binson-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/assaabloy-ppi/binson-swift)

A Binson implementation in the Swift language. To be used for iOS, MacOS and Linux projects.
Read more about [Binson](http://binson.org) ...

Binson
------

Binson is an exceptionally simple binary data serialization format. It is similar in scope to JSON,
but it is faster, more compact, and significantly easier to understand.

For example Binson has full support for double precision floating point numbers (including NaN, inf).
There is a one-to-one mapping between a Binson object and its serialized bytes. Useful for cryptographic
signatures, hash codes and equals operations.

Serialization Format
--------------------

The bytes of a serialized Binson object follow this [ABNF] syntax.
```
object     = begin *field end
field      = string value
value      = boolean / integer / double / string / bytes / array / object
array      = beginArray *value endArray
string     = stringLen utf
bytes      = bytesLen raw
boolean    = true / false

begin      = %x40
end        = %x41
beginArray = %x42
endArray   = %x43
true       = %x44
false      = %x45
double     = %x46 float64
integer    = %x10 int8 / %x11 int16 / %x12 int32 / %x13 int64
stringLen  = %x14 int8 / %x15 int16 / %x16 int32
bytesLen   = %x18 int8 / %x19 int16 / %x1a int32

float64    = 8OCTET ; double precision floation point number [IEEE-754]
int8       = 1OCTET ;  8-bit signed two's complement integer
int16      = 2OCTET ; 16-bit signed two's complement integer
int32      = 4OCTET ; 32-bit signed two's complement integer
int64      = 8OCTET ; 64-bit signed two's complement integer
utf        = *OCTET ; stringLen number of [UTF-8] bytes
raw        = *OCTET ; any sequence of bytesLen bytes
```

Howto use
---------

Binson is Open Source and managed in Github. Download or clone using this link:
[github.com/assaabloy-ppi/binson-swift](
https://github.com/assaabloy-ppi/binson-swift.git)

You can also use various Package managers, e.g. Cocoapods
### Podfile

```
platform :ios, '11.0'

target 'YourProject' do
  pod 'Binson', :git => 'https://github.com/assaabloy-ppi/binson-swift.git', :tag => '2.0'
end
```

### Pod install
```shell
% pod install
```

Examples
--------

Create
------

The append function returns self, so that you can chain append commands.
```swift
let binson = Binson()
    .append("c", "u")
    .append("i", 1)
    .append("z", .object(Binson()))
    .append("t", .bytes(Data([0x02, 0x02])))
```
You are also allowed to use the `+=`operator to build the Binson object. But note that the declaration require a var declaration.
```swift
var binson = Binson()
binson += ("c", "u")

print(binson.hex)
"0x4014016314017541"
```

Codable support
---------------

Binson supports the Decodable and Encodable protocols introduced in swift 4.0, through the use of BinsonDecoder and BinsonEncoder.
This means that you can use the same modern serialization as with JSON. Some notes though:

* The swift Date type is default serialized as a double representing seconds since unix epoch. This can be changed with the DateEncoding/Decoding/Strategy options on the encoder and decoder.
* Since Binson doesn't handle nil values, optionals that are nil will be skipped.
* Integer values will be encoded as the smallest possible Binson type that fits the value.

```swift
struct TestCodable: Codable {
    struct NestedTestCodable: Codable {
        var string = "Hello"
        var double = 23.0992
    }
    var int = 230
    var bool = true
    var data = Data([0x02, 0x02, 0x04])
    var array = ["co", "u"]
    var nested = NestedTestCodable()
    var opt: Int? // Will not be encoded when nil
}
let encoder = BinsonEncoder()
let testObj = TestCodable()
let binson = try? encoder.encode(testObj)
print(binson?.json)
{
    "array" : [
        "co",
        "u"
    ],
    "bool" : true,
    "data" : "0x020204",
    "int" : 230,
    "nested" : {
        "double" : 23.0992,
        "string" : "Hello"
    }
}
```


Useful Binson object properties
-------------------------------

All Binson objects and Value types support the properties .hex, .json and .data. Data is used for binary serialization e.g. for communication with devices.

### binson.hex
```swift
print(binson.hex)
"0x4014016314017514016910011401741802020214017a404141"
```

### binson.json
```swift
print(binson.json)
{
  "c" : "u",
  "i" : 1,
  "t" : "0x0202",
  "z" : {
  }
}
```
### binson.data
```swift
print(binson.data)
Data(25 bytes)
```

Unpack
------

### from serialized Data
```swift
let binson_data = Data([0x40, 0x14, 0x01, 0x7a, 0x40, 0x41, 0x41])
if let binson = try? Binson(data: binson_data) {}
```

### from a Hexstring
```swift
if let binson = try? Binson(hex: "0x4014016314017541") {}
```

### from a JSON string
```swift
if let binson = try? Binson(jsonString: json) {}
```

Subscripts
----------

You are allowed to access properties inside a Binson object using the subscript approach.

Instead of
```swift
if let i2 = binson.value(key: "d") {
    print(i2)
}
```
using subscripts allow for cleaner code
```swift
if let i: Int64 = binson["d"].integerValue {
    print(i)
}
```
