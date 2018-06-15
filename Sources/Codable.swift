//
//  Codable.swift
//  Binson
//
//  Created by Fredrik Littmarck on 2018-03-20.
//  Copyright © 2018 Assa Abloy Shared Technologies. All rights reserved.
//

import Foundation

/// `BinsonEncoder` facilitates the encoding of `Encodable` values into Binson.
open class BinsonEncoder {
    /*
    public enum TypeConversionHandling {
        case fail
        case warn
        case silent
    }
*/
    open var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}
    
    // MARK: - Encoding Values
    /// Encodes the given top-level value and returns a Binson object.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Binson` object containing the encoded Binson data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T : Encodable>(_ value: T) throws -> Binson {
        let encoder = _BinsonEncoder(userInfo: userInfo)
        
        guard let topLevel = try encoder.box_(value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }

        guard case let .object(object) = topLevel else {
            throw EncodingError.invalidValue(topLevel, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) must be of object type."))
        }
        return object
    }
}

// MARK: - _BinsonEncoder
fileprivate class _BinsonEncoder : Encoder {
    fileprivate var storage: _BinsonEncodingStorage

    public var codingPath: [CodingKey]

    private(set) var userInfo: [CodingUserInfoKey : Any] = [:]

    fileprivate init(userInfo: [CodingUserInfoKey : Any], codingPath: [CodingKey] = []) {
        self.userInfo = userInfo
        self.storage = _BinsonEncodingStorage()
        self.codingPath = codingPath
    }
    
    fileprivate var canEncodeNewValue: Bool {
        return self.storage.count == self.codingPath.count
    }
    
    public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        let topContainer: Binson
        if self.canEncodeNewValue {
            topContainer = self.storage.pushKeyedContainer()
        } else {
            guard let last = storage.containers.last, case let .object(object) = last else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
            
            topContainer = object
        }
        
        let container = _BinsonKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
        return KeyedEncodingContainer(container)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        let topContainer: BinsonArray
        if self.canEncodeNewValue {
            topContainer = self.storage.pushUnkeyedContainer()
        } else {
            guard let last = storage.containers.last, case let .array(array) = last else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }
            
            topContainer = array
        }
        return _BinsonUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

fileprivate struct _BinsonEncodingStorage {
    private(set) fileprivate var containers: [BinsonValue] = []
    
    fileprivate init() {}
    
    fileprivate var count: Int {
        return self.containers.count
    }
    
    fileprivate mutating func pushKeyedContainer() -> Binson {
        let dict = Binson()
        self.containers.append(BinsonValue(dict))
        return dict
    }
    
    fileprivate mutating func pushUnkeyedContainer() -> BinsonArray {
        let array = BinsonArray()
        self.containers.append(BinsonValue(array))
        return array
    }
    
    fileprivate mutating func push(container: BinsonValue) {
        self.containers.append(container)
    }
    
    fileprivate mutating func popContainer() -> BinsonValue {
        precondition(self.containers.count > 0, "Empty container stack.")
        return self.containers.popLast()!
    }
}

fileprivate struct _BinsonKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K
    
    private let encoder: _BinsonEncoder
    
    private let container: Binson
    
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _BinsonEncoder, codingPath: [CodingKey], wrapping container: Binson) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
        
    // MARK: - KeyedEncodingContainerProtocol Methods
    public mutating func encodeNil(forKey key: Key) throws {
        let debugDescription = "Unable to encode nil in Binson!"
        throw EncodingError.invalidValue(NSNull(), EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription))
    }
    public mutating func encode(_ value: Bool, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: Int, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: Int8, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: Int16, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: Int32, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: Int64, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt8, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt16, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt32, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt64, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    public mutating func encode(_ value: String, forKey key: Key) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    public mutating func encode(_ value: Float, forKey key: Key) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }

    public mutating func encode(_ value: Double, forKey key: Key) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }
    
    public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let dictionary = Binson()
        self.container[key.stringValue] = BinsonValue(dictionary)
        
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        let container = _BinsonKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let array = BinsonArray()
        self.container[key.stringValue] = BinsonValue(array)
        
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return _BinsonUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }
    
    public mutating func superEncoder() -> Encoder {
        return _BinsonReferencingEncoder(referencing: self.encoder, key: _BinsonKey.super, wrapping: BinsonValue(self.container))
    }
    
    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return _BinsonReferencingEncoder(referencing: self.encoder, key: key, wrapping: BinsonValue(self.container))
    }
}

fileprivate struct _BinsonUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    private let encoder: _BinsonEncoder
    
    private let container: BinsonArray
    
    private(set) public var codingPath: [CodingKey]
    
    public var count: Int {
        return self.container.count
    }
    
    fileprivate init(referencing encoder: _BinsonEncoder, codingPath: [CodingKey], wrapping container: BinsonArray) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    
    public mutating func encodeNil() throws {
        let debugDescription = "Unable to encode nil in Binson!"
        throw EncodingError.invalidValue(NSNull(), EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription))
    }
    public mutating func encode(_ value: Bool)   throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: Int)    throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: Int8)   throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: Int16)  throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: Int32)  throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: Int64)  throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt)   throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt8)  throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt16) throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt32) throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt64) throws { self.container.append(self.encoder.box(value)) }
    public mutating func encode(_ value: String) throws { self.container.append(self.encoder.box(value)) }
    
    public mutating func encode(_ value: Float)  throws {
        // Since the float may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(_BinsonKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.append(try self.encoder.box(value))
    }

    public mutating func encode(_ value: Double) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(_BinsonKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.append(try self.encoder.box(value))
    }
    
    public mutating func encode<T : Encodable>(_ value: T) throws {
        self.encoder.codingPath.append(_BinsonKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.append(try self.encoder.box(value))
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        self.codingPath.append(_BinsonKey(index: self.count))
        defer { self.codingPath.removeLast() }
        
        let dictionary = Binson()
        self.container.append(BinsonValue(dictionary))
        
        let container = _BinsonKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self.codingPath.append(_BinsonKey(index: self.count))
        defer { self.codingPath.removeLast() }
        
        let array = BinsonArray()
        self.container.append(BinsonValue(array))
        return _BinsonUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }
    
    public mutating func superEncoder() -> Encoder {
        return _BinsonReferencingEncoder(referencing: self.encoder, key: _BinsonKey(index: self.container.count), wrapping: BinsonValue(self.container))
    }
}

extension _BinsonEncoder : SingleValueEncodingContainer {
    fileprivate func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
    }
    
    public func encodeNil() throws {
        let debugDescription = "Unable to encode nil in Binson!"
        throw EncodingError.invalidValue(NSNull(), EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription))
    }
    
    public func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }
    
    public func encode<T : Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }
}

// MARK: - Concrete Value Representations
extension _BinsonEncoder {
    /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
    fileprivate func box(_ value: Bool)   -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: Int) -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: Int8) -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: Int16) -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: Int32) -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: Int64) -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: UInt) -> BinsonValue { return BinsonValue(Int64(bitPattern: UInt64(value))) }
    fileprivate func box(_ value: UInt8) -> BinsonValue { return BinsonValue(Int64(bitPattern: UInt64(value))) }
    fileprivate func box(_ value: UInt16) -> BinsonValue { return BinsonValue(Int64(bitPattern: UInt64(value))) }
    fileprivate func box(_ value: UInt32) -> BinsonValue { return BinsonValue(Int64(bitPattern: UInt64(value))) }
    fileprivate func box(_ value: UInt64) -> BinsonValue { return BinsonValue(Int64(bitPattern: value)) }
    fileprivate func box(_ value: String) -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ double: Double) throws -> BinsonValue { return BinsonValue(double) }
    
    fileprivate func box(_ data: Data) throws -> BinsonValue { return BinsonValue(data) }

    fileprivate func box<T : Encodable>(_ value: T) throws -> BinsonValue {
        return try self.box_(value) ?? BinsonValue(Binson())
    }
    
    // This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
    fileprivate func box_<T : Encodable>(_ value: T) throws -> BinsonValue? {
        if T.self == Data.self || T.self == NSData.self {
            return try self.box((value as! Data))
        } else if T.self == URL.self || T.self == NSURL.self {
            // Encode URLs as single strings.
            return self.box((value as! URL).absoluteString)
        }
        
        // The value should request a container from the _BinsonEncoder.
        let depth = self.storage.count
        do {
            try value.encode(to: self)
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                let _ = self.storage.popContainer()
            }
            throw error
        }
        
        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }
        
        return self.storage.popContainer()
    }
}

fileprivate class _BinsonReferencingEncoder : _BinsonEncoder {
    fileprivate let encoder: _BinsonEncoder

    private let key: CodingKey
    private let reference: BinsonValue
    
    fileprivate init(referencing encoder: _BinsonEncoder, key: CodingKey, wrapping value: BinsonValue) {

        switch value {
        case .array(_), .object(_):
            break
        default:
            preconditionFailure("Trying to reference non container type")
        }
        self.encoder = encoder
        self.reference = value
        self.key = key
        super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath)

        self.codingPath.append(key)
    }
    
    fileprivate override var canEncodeNewValue: Bool {
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }
    
    deinit {
        let value: BinsonValue
        switch self.storage.count {
        case 0: value = BinsonValue(Binson())
        case 1: value = self.storage.popContainer()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }
        
        switch self.reference {
        case .array(let array):
            array.insert(value, at: key.intValue!)
            
        case .object(let object):
            object[key.stringValue] = value

        default:
            fatalError("Non container type referenced")
        }
    }
}

//===----------------------------------------------------------------------===//
// Shared Key Types
//===----------------------------------------------------------------------===//
fileprivate struct _BinsonKey : CodingKey {
    public var stringValue: String
    public var intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }
    
    fileprivate init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
    
    fileprivate static let `super` = _BinsonKey(stringValue: "super")!
}

//===----------------------------------------------------------------------===//
// Shared ISO8601 Date Formatter
//===----------------------------------------------------------------------===//
// NOTE: This value is implicitly lazy and _must_ be lazy. We're compiled against the latest SDK (w/ ISO8601DateFormatter), but linked against whichever Foundation the user has. ISO8601DateFormatter might not exist, so we better not hit this code path on an older OS.
/*@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
fileprivate var _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
*/

//===----------------------------------------------------------------------===//
// Error Utilities
//===----------------------------------------------------------------------===//
fileprivate extension EncodingError {
    /// Returns a `.invalidValue` error describing the given invalid floating-point value.
    ///
    ///
    /// - parameter value: The value that was invalid to encode.
    /// - parameter path: The path of `CodingKey`s taken to encode this value.
    /// - returns: An `EncodingError` with the appropriate path and debug description.
    fileprivate static func _invalidFloatingPointValue<T : FloatingPoint>(_ value: T, at codingPath: [CodingKey]) -> EncodingError {
        let valueDescription: String
        if value == T.infinity {
            valueDescription = "\(T.self).infinity"
        } else if value == -T.infinity {
            valueDescription = "-\(T.self).infinity"
        } else {
            valueDescription = "\(T.self).nan"
        }
        
        let debugDescription = "Unable to encode \(valueDescription) directly in JSON. Use JSONEncoder.NonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded."
        return .invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription))
    }
}
