//
//  Codable.swift
//  Binson
//
//  Created by Fredrik Littmarck on 2018-03-20.
//  Copyright © 2018 Assa Abloy Shared Technologies. All rights reserved.
//

// swiftlint:disable file_length

import Foundation

/// `BinsonEncoder` facilitates the encoding of `Encodable` values into Binson.
open class BinsonEncoder {

    /// The strategy to use for encoding `Date` values.
    public enum DateEncodingStrategy {
        /// Encode the `Date` as a UNIX timestamp (as a Binson double). Default
        case doubleSecondsSince1970

        /// Encode the `Date` as UNIX millisecond timestamp (as a Binson integer).
        case integerMillisecondsSince1970

        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601

        /// Encode the `Date` as a string formatted by the given formatter.
        case formatted(DateFormatter)

        /// Encode the `Date` as a custom value encoded by the given closure.
        ///
        /// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
        case custom((Date, Encoder) throws -> Void)
    }

    /// The strategy to use in encoding dates. Defaults to `.doubleSecondsSince1970`.
    open var dateEncodingStrategy: DateEncodingStrategy = .doubleSecondsSince1970

    open var userInfo: [CodingUserInfoKey: Any] = [:]

    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    fileprivate struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }

    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        return _Options(dateEncodingStrategy: dateEncodingStrategy,
                        userInfo: userInfo)
    }

    public init() {}
    
    // MARK: - Encoding Values
    /// Encodes the given top-level value and returns a Binson object.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Binson` object containing the encoded Binson data.
    /// - throws: An error if any value throws an error during encoding.
    open func encode(_ value: Encodable) throws -> Binson {
        let encoder = _BinsonEncoder(options: self.options)
        
        guard let topLevel = try encoder.box_(value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(value.self) did not encode any values."))
        }

        guard case let .object(object) = topLevel else {
            throw EncodingError.invalidValue(topLevel, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(value.self) must be of object type."))
        }
        return object
    }
}

// MARK: - _BinsonEncoder
private class _BinsonEncoder: Encoder {
    fileprivate var storage: _BinsonEncodingStorage

    public var codingPath: [CodingKey]

    fileprivate let options: BinsonEncoder._Options

    public var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }

    fileprivate init(options: BinsonEncoder._Options, codingPath: [CodingKey] = []) {
        self.options = options
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

private struct _BinsonEncodingStorage {
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

private struct _BinsonKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
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
    
    public mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
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

private struct _BinsonUnkeyedEncodingContainer: UnkeyedEncodingContainer {
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
    
    public mutating func encode<T: Encodable>(_ value: T) throws {
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

extension _BinsonEncoder: SingleValueEncodingContainer {
    fileprivate func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when value previously already encoded.")
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
    
    public func encode<T: Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }
}

// MARK: - Concrete Value Representations
extension _BinsonEncoder {
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

    fileprivate func box(_ date: Date) throws -> BinsonValue {
        switch self.options.dateEncodingStrategy {
        case .doubleSecondsSince1970:
            return BinsonValue(date.timeIntervalSince1970)

        case .integerMillisecondsSince1970:
            return BinsonValue(Int64(1000.0 * date.timeIntervalSince1970))

        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return BinsonValue(_iso8601Formatter.string(from: date))
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }

        case .formatted(let formatter):
            return BinsonValue(formatter.string(from: date))

        case .custom(let closure):
            let depth = self.storage.count
            do {
                try closure(date, self)
            } catch {
                // If the value pushed a container before throwing, pop it back off to restore state.
                if self.storage.count > depth {
                    let _ = self.storage.popContainer()
                }

                throw error
            }

            guard self.storage.count > depth else {
                // The closure didn't encode anything. Return the default keyed container.
                return BinsonValue(Binson())
            }

            // We can pop because the closure encoded something.
            return self.storage.popContainer()
        }
    }

    fileprivate func box(_ value: Encodable) throws -> BinsonValue {
        return try self.box_(value) ?? BinsonValue(Binson())
    }
    
    fileprivate func box_(_ value: Encodable) throws -> BinsonValue? {
        let type = Swift.type(of: value)
        if type == Date.self || type == NSDate.self {
            // Respect Date encoding strategy
            return try self.box((value as! Date))
        } else if type == Data.self || type == NSData.self {
            return try self.box((value as! Data))
        } else if type == URL.self || type == NSURL.self {
            // Encode URLs as single strings.
            return self.box((value as! URL).absoluteString)
        }
        
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

private class _BinsonReferencingEncoder: _BinsonEncoder {
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
        super.init(options: encoder.options, codingPath: encoder.codingPath)

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


/// `BinsonDecoder` facilitates the decoding of Binson into semantic `Decodable` types.
open class BinsonDecoder {

    /// The strategy to use for decoding `Date` values.
    public enum DateDecodingStrategy {
        /// Decode the `Date` from a UNIX millisecond timestamp (in a Binson double). Default
        case doubleSecondsSince1970

        /// Decode the `Date` from a UNIX millisecond timestamp (in a Binson integer).
        case integerMillisecondsSince1970

        /// Decode the `Date` from an ISO-8601-formatted string (in RFC 3339 format).
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601

        /// Decode the `Date` form a string formatted by the given formatter.
        case formatted(DateFormatter)

        /// Decode the `Date` from a custom value decoded by the given closure.
        case custom((Decoder) throws -> Date)
    }

    /// The strategy to use in encoding dates. Defaults to `.doubleSecondsSince1970`.
    open var dateDecodingStrategy: DateDecodingStrategy = .doubleSecondsSince1970

    /// Contextual user-provided information for use during decoding.
    open var userInfo: [CodingUserInfoKey: Any] = [:]

    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    fileprivate struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }

    /// The options set on the top-level decoder.
    fileprivate var options: _Options {
        return _Options(dateDecodingStrategy: dateDecodingStrategy,
                        userInfo: userInfo)
    }

    // MARK: - Constructing a Binson Decoder
    public init() {}

    // MARK: - Decoding Values
    /// Decodes a top-level value of the given type from the given Binson representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter binson: The Binson object to decode from.
    /// - returns: A value of the requested type.
    /// - throws: An error if any value throws an error during decoding.
    open func decode<T: Decodable>(_ type: T.Type, from binson: Binson) throws -> T {

        let top = BinsonValue(binson)
        let decoder = _BinsonDecoder(referencing: top, options: self.options)
        guard let value = try decoder.unbox(top, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }

        return value
    }
}

// MARK: - _BinsonDecoder
private class _BinsonDecoder: Decoder {
    // MARK: Properties
    /// The decoder's storage.
    fileprivate var storage: _BinsonDecodingStorage

    /// Options set on the top-level decoder.
    fileprivate let options: BinsonDecoder._Options

    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }

    // MARK: - Initialization
    /// Initializes `self` with the given top-level container and options.
    fileprivate init(referencing value: BinsonValue, at codingPath: [CodingKey] = [], options: BinsonDecoder._Options) {
        self.storage = _BinsonDecodingStorage()
        self.storage.push(container: value)
        self.codingPath = codingPath
        self.options = options
    }

    // MARK: - Decoder Methods
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard case .object(let binson) = self.storage.topContainer else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: Binson.self, reality: self.storage.topContainer)
        }

        let container = _BinsonKeyedDecodingContainer<Key>(referencing: self, wrapping: binson)
        return KeyedDecodingContainer(container)
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case .array(let array) = self.storage.topContainer else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: BinsonArray.self, reality: self.storage.topContainer)
        }

        return _BinsonUnkeyedDecodingContainer(referencing: self, wrapping: array)
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }

    fileprivate static func typeMismatchError(at path: [CodingKey], expectation: Any.Type, reality: BinsonValue) -> DecodingError {
        return DecodingError.typeMismatch(reality.underlyingType, DecodingError.Context(codingPath: path, debugDescription: "Expected \(expectation), but found \(reality.underlyingType) instead."))
    }
}

// MARK: - Decoding Storage
private struct _BinsonDecodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the Binson types (NSNull, NSNumber, String, Array, [String: Any]).
    private(set) fileprivate var containers: [BinsonValue] = []

    // MARK: - Initialization
    /// Initializes `self` with no containers.
    fileprivate init() {}

    // MARK: - Modifying the Stack
    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate var topContainer: BinsonValue {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.last!
    }

    fileprivate mutating func push(container: BinsonValue) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        self.containers.removeLast()
    }
}

// MARK: Decoding Containers
private struct _BinsonKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K

    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: _BinsonDecoder

    /// A reference to the container we're reading from.
    private let container: Binson

    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]

    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: _BinsonDecoder, wrapping binson: Binson) {
        self.decoder = decoder
        self.container = binson
        self.codingPath = decoder.codingPath
    }

    // MARK: - KeyedDecodingContainerProtocol Methods
    public var allKeys: [Key] {
        return self.container.keys.compactMap { Key(stringValue: $0) }
    }

    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }

    private func _errorDescription(of key: CodingKey) -> String {
        // Otherwise, just report the converted string
        return "\(key) (\"\(key.stringValue)\")"
    }

    public func decodeNil(forKey key: Key) throws -> Bool {
        guard let _ = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        return false
    }

    public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \(_errorDescription(of: key))"))
        }

        guard case .object(let binson) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: Binson.self, reality: value)
        }

        let container = _BinsonKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: binson)
        return KeyedDecodingContainer(container)
    }

    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \(_errorDescription(of: key))"))
        }

        guard case .array(let array) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: BinsonArray.self, reality: value)
        }

        return _BinsonUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        if let value = self.container[key.stringValue] {
            return _BinsonDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
        }
        throw DecodingError.keyNotFound(key,
                                        DecodingError.Context(codingPath: self.codingPath,
                                                              debugDescription: "Cannot get superDecoder -- no value found for key \(_errorDescription(of: key))"))
    }

    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: _BinsonKey.super)
    }

    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

private struct _BinsonUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    private let decoder: _BinsonDecoder

    private let container: BinsonArray

    private(set) public var codingPath: [CodingKey]

    /// The index of the element we're about to decode.
    private(set) public var currentIndex: Int

    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and array.
    fileprivate init(referencing decoder: _BinsonDecoder, wrapping container: BinsonArray) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }

    // MARK: - UnkeyedDecodingContainer Methods
    public var count: Int? {
        return self.container.count
    }

    public var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }

    private func throwIfAtEnd() throws {
        if self.isAtEnd {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
    }

    public mutating func decodeNil() throws -> Bool {
        try throwIfAtEnd()
        return false
    }

    public mutating func decode(_ type: Bool.Type) throws -> Bool {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int.Type) throws -> Int {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int8.Type) throws -> Int8 {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int16.Type) throws -> Int16 {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int32.Type) throws -> Int32 {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int64.Type) throws -> Int64 {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt.Type) throws -> UInt {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Float.Type) throws -> Float {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Double.Type) throws -> Double {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: String.Type) throws -> String {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try throwIfAtEnd()

        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BinsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]

        guard case .object(let binson) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: Binson.self, reality: value)
        }

        self.currentIndex += 1
        let container = _BinsonKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: binson)
        return KeyedDecodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]

        guard case .array(let array) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: BinsonArray.self, reality: value)
        }

        self.currentIndex += 1
        return _BinsonUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    public mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(_BinsonKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        self.currentIndex += 1
        return _BinsonDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }
}

extension _BinsonDecoder: SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    public func decodeNil() -> Bool {
        return false
    }

    public func decode(_ type: Bool.Type) throws -> Bool {
        return try self.unbox(self.storage.topContainer, as: Bool.self)!
    }

    public func decode(_ type: Int.Type) throws -> Int {
        return try self.unbox(self.storage.topContainer, as: Int.self)!
    }

    public func decode(_ type: Int8.Type) throws -> Int8 {
        return try self.unbox(self.storage.topContainer, as: Int8.self)!
    }

    public func decode(_ type: Int16.Type) throws -> Int16 {
        return try self.unbox(self.storage.topContainer, as: Int16.self)!
    }

    public func decode(_ type: Int32.Type) throws -> Int32 {
        return try self.unbox(self.storage.topContainer, as: Int32.self)!
    }

    public func decode(_ type: Int64.Type) throws -> Int64 {
        return try self.unbox(self.storage.topContainer, as: Int64.self)!
    }

    public func decode(_ type: UInt.Type) throws -> UInt {
        return try self.unbox(self.storage.topContainer, as: UInt.self)!
    }

    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try self.unbox(self.storage.topContainer, as: UInt8.self)!
    }

    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try self.unbox(self.storage.topContainer, as: UInt16.self)!
    }

    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try self.unbox(self.storage.topContainer, as: UInt32.self)!
    }

    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try self.unbox(self.storage.topContainer, as: UInt64.self)!
    }

    public func decode(_ type: Float.Type) throws -> Float {
        return try self.unbox(self.storage.topContainer, as: Float.self)!
    }

    public func decode(_ type: Double.Type) throws -> Double {
        return try self.unbox(self.storage.topContainer, as: Double.self)!
    }

    public func decode(_ type: String.Type) throws -> String {
        return try self.unbox(self.storage.topContainer, as: String.self)!
    }

    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        return try self.unbox(self.storage.topContainer, as: type)!
    }
}

// MARK: - Concrete Value Representations
extension _BinsonDecoder {
    /// Returns the given value unboxed from a container.
    fileprivate func unbox(_ value: BinsonValue, as type: Bool.Type) throws -> Bool? {

        // TODO: Support conversion of ints to bool?
        guard case .bool(let bool) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }

        return bool
    }

    fileprivate func unbox(_ value: BinsonValue, as type: Int.Type) throws -> Int? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        guard let int = Int(exactly: number) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed Binson number <\(number)> does not fit in \(type)."))
        }
        return int
    }

    fileprivate func unbox(_ value: BinsonValue, as type: Int8.Type) throws -> Int8? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        guard let int8 = Int8(exactly: number) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed Binson number <\(number)> does not fit in \(type)."))
        }
        return int8
    }

    fileprivate func unbox(_ value: BinsonValue, as type: Int16.Type) throws -> Int16? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        guard let int16 = Int16(exactly: number) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed Binson number <\(number)> does not fit in \(type)."))
        }
        return int16
    }

    fileprivate func unbox(_ value: BinsonValue, as type: Int32.Type) throws -> Int32? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        guard let int32 = Int32(exactly: number) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed Binson number <\(number)> does not fit in \(type)."))
        }
        return int32
    }

    fileprivate func unbox(_ value: BinsonValue, as type: Int64.Type) throws -> Int64? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        return number
    }

    fileprivate func unbox(_ value: BinsonValue, as type: UInt.Type) throws -> UInt? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        let uint64 = UInt64(bitPattern: number)
        guard let uint = UInt(exactly: uint64) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed Binson number <\(number)> does not fit in \(type)."))
        }
        return uint
    }

    fileprivate func unbox(_ value: BinsonValue, as type: UInt8.Type) throws -> UInt8? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        let uint64 = UInt64(bitPattern: number)
        guard let uint8 = UInt8(exactly: uint64) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed Binson number <\(number)> does not fit in \(type)."))
        }
        return uint8
    }

    fileprivate func unbox(_ value: BinsonValue, as type: UInt16.Type) throws -> UInt16? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        let uint64 = UInt64(bitPattern: number)
        guard let uint16 = UInt16(exactly: uint64) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed Binson number <\(number)> does not fit in \(type)."))
        }
        return uint16
    }

    fileprivate func unbox(_ value: BinsonValue, as type: UInt32.Type) throws -> UInt32? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        let uint64 = UInt64(bitPattern: number)
        guard let uint32 = UInt32(exactly: uint64) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed Binson number <\(number)> does not fit in \(type)."))
        }
        return uint32
    }

    fileprivate func unbox(_ value: BinsonValue, as type: UInt64.Type) throws -> UInt64? {
        guard case .int(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        return UInt64(bitPattern: number)
    }

    fileprivate func unbox(_ value: BinsonValue, as type: Float.Type) throws -> Float? {
        guard case .double(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        guard let float = Float(exactly: number) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed Binson number <\(number)> does not fit in \(type)."))
        }
        return float
    }

    fileprivate func unbox(_ value: BinsonValue, as type: Double.Type) throws -> Double? {
        guard case .double(let number) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        return number
    }

    fileprivate func unbox(_ value: BinsonValue, as type: String.Type) throws -> String? {
        guard case .string(let string) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }
        return string
    }

    fileprivate func unbox(_ value: BinsonValue, as type: Date.Type) throws -> Date? {
        switch self.options.dateDecodingStrategy {
        case .doubleSecondsSince1970:
            let doubleDate = try self.unbox(value, as: Double.self)!
            return Date(timeIntervalSince1970: doubleDate)

        case .integerMillisecondsSince1970:
            let intDate = try self.unbox(value, as: Int64.self)!
            return Date(timeIntervalSince1970: TimeInterval(intDate) / 1000.0)

        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                let string = try self.unbox(value, as: String.self)!
                guard let date = _iso8601Formatter.date(from: string) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                }

                return date
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }

        case .formatted(let formatter):
            let string = try self.unbox(value, as: String.self)!
            guard let date = formatter.date(from: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Date string does not match format expected by formatter."))
            }

            return date

        case .custom(let closure):
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try closure(self)
        }
    }

    fileprivate func unbox(_ value: BinsonValue, as type: Data.Type) throws -> Data? {
        guard case .bytes(let data) = value else {
            throw _BinsonDecoder.typeMismatchError(at: self.codingPath, expectation: type, reality: value)
        }

        return data
    }

    fileprivate func unbox<T: Decodable>(_ value: BinsonValue, as type: T.Type) throws -> T? {
        return try unbox_(value, as: type) as? T
    }

    fileprivate func unbox_(_ value: BinsonValue, as type: Decodable.Type) throws -> Any? {
        if type == Date.self || type == NSDate.self {
            return try self.unbox(value, as: Date.self)
        } else if type == Data.self || type == NSData.self {
            return try self.unbox(value, as: Data.self)
        } else if type == URL.self || type == NSURL.self {
            guard let urlString = try self.unbox(value, as: String.self) else {
                return nil
            }
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath,
                                                                        debugDescription: "Invalid URL string."))
            }

            return url
        } else {
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try type.init(from: self)
        }
    }
}

//===----------------------------------------------------------------------===//
// Shared Key Types
//===----------------------------------------------------------------------===//
private struct _BinsonKey: CodingKey {
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
@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
fileprivate var _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
