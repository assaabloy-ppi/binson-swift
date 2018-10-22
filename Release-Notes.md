Releases
========

Also see the [Release notes in Github](https://github.com/assaabloy-ppi/binson-swift/releases)

Binson Swift 2.0, 2018-10-22
----------------------------

### Highlights:
* Introducing BinsonEncoder and BinsonDecoder with support for Codable protocols introduced in swift 4.0

### Changes
* Builder.unpack(*) methods are now throwable initializers on the Binson class itself.
* Renamed some types to reduce pollution of the global namespace. Value is now BinsonValue etc.
* Faster unpacking

### Issues Resolved
* Double type was not serialized properly


Binson Swift 1.1, 2017-11-22
---------------------------------

We're pleased to present Binson Swift 1.1.

### Highlights
* Better packing

### Issues Resolved
*


Binson Swift 1.0, 2017-08-22
----------------------------------

This release implements Binson 1.0

### Highlights
* Builder class to create Binson objects from Bytes, Data and Hex
* Value implementation for each Binson Value Type
* Pack and Unpack functions

### Issues
* Some of the Packing is overly complicated
* Some value types are not as pretty to work with
* Documentation is lacking
