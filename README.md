Binson Swift
============

[![Build Status](https://travis-ci.org/assaabloy-ppi/binson-swift.svg?branch=master)](https://travis-ci.org/assaabloy-ppi/binson-swift)
[![Code coverage](https://codecov.io/gh/assaabloy-ppi/binson-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/assaabloy-ppi/binson-swift)

A Binson implementation in the Swift language. To be used for iOS, MacOS and Linux projects.
Read more about [Binson](http://binson.org) ...

Binson
------

Binson is an exceptionally simple binary data serialization format. It is similar in scope to JSON,
but it is faster, more compact, and significantly easier to understand.

For example Binson has full support for double precision floating point numbers (including NaN, inf).
There is a one-to-one mapping between a Binson object and its serialized bytes. Useful for cryptographic
signatures, hash codes and equals operations.

Format
------

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
platform :ios, '10.3'

target 'YourProject' do
  use_frameworks!
  pod 'Binson', :git => 'https://github.com/assaabloy-ppi/binson-swift.git'

  target 'YourProjet-tests' do
    inherit! :search_paths
  end
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
    .append("t", .bytes([0x02, 0x02]))
```
You are also allowed to use the `+=`operator to build the Binson object. But note that the declaration require a var declaration.
```swift
var binson = Binson()
binson += ("c", "u")

print(binson.hex)
"0x4014016314017541"
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
  "i" : 1,
  "t" : "0x0202",
  "c" : "u",
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
if let binson = Builder.unpack(data: binson_data) {}
```

### from a Hexstring
```swift
if let binson = Builder.unpack(hex: "0x4014016314017541") {}
```

### from a JSON string
```swift
if let binson = Builder.unpack(jsonstring: json) {}
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
