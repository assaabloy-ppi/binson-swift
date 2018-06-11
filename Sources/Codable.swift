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
    
    /// Contextual user-provided information for use during encoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]
    
    // MARK: - Constructing a Binson Encoder
    /// Initializes `self` with default strategies.
    public init() {}
    
    // MARK: - Encoding Values
    /// Encodes the given top-level value and returns its JSON representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded JSON data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T : Encodable>(_ value: T) throws -> BinsonDictionary {
        let encoder = _BinsonEncoder(userInfo: userInfo)
        
        guard let topLevel = try encoder.box_(value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }
/*
        if topLevel. {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) encoded as null Binson fragment."))
        } else if topLevel is NSNumber {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) encoded as number Binson fragment."))
        } else if topLevel is NSString {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) encoded as string Binson fragment."))
        }
  */
        guard case let .object(object) = topLevel else {
            throw EncodingError.invalidValue(topLevel, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) must be of object type."))
        }
        return object
    }
}

open class BinsonArray {
    var array = Array<BinsonValue>()

    public subscript(index: Int) -> BinsonValue {
        get { return array[index] }
        set(newValue) { array[index] = newValue }
    }

    var count: Int {
        return array.count
    }

    func append(_ value: BinsonValue) {
        array.append(value)
    }

    func insert(_ value: BinsonValue, at index: Int) {
        array.insert(value, at: index)
    }
}

open class BinsonDictionary {
    var dict = Dictionary<String, BinsonValue>()

    public subscript(key: String) -> BinsonValue? {
        get { return dict[key] }
        set(newValue) { dict[key] = newValue }
    }
}

extension BinsonDictionary: CustomDebugStringConvertible {
    public var debugDescription: String {
        return dict.debugDescription
    }
}

extension BinsonArray: CustomDebugStringConvertible {
    public var debugDescription: String {
        return array.debugDescription
    }
}

public enum BinsonValue {
    case bool(Bool)
    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
    case double(Double)
    case string(String)
    case bytes(Data)
    case array(BinsonArray)
    case object(BinsonDictionary)

    init(_ bool: Bool) {
        self = .bool(bool)
    }

    init(_ int8: Int8) {
        self = .int8(int8)
    }

    init(_ int16: Int16) {
        self = .int16(int16)
    }

    init(_ int32: Int32) {
        self = .int32(int32)
    }

    init(_ int64: Int64) {
        self = .int64(int64)
    }

    init(_ double: Double) {
        self = .double(double)
    }

    init(_ string: String) {
        self = .string(string)
    }

    init(_ bytes: Data) {
        self = .bytes(bytes)
    }

    init(_ array: BinsonArray) {
        self = .array(array)
    }

    init(_ object: BinsonDictionary) {
        self = .object(object)
    }

}

// MARK: - _BinsonEncoder
fileprivate class _BinsonEncoder : Encoder {
    // MARK: Properties
    /// The encoder's storage.
    fileprivate var storage: _BinsonEncodingStorage
    
    /// Contextual user-provided information for use during encoding.
    private(set) var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /// The path to the current point in encoding.
    public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` with the given top-level encoder options.
    fileprivate init(userInfo: [CodingUserInfoKey : Any], codingPath: [CodingKey] = []) {
        self.userInfo = userInfo
        self.storage = _BinsonEncodingStorage()
        self.codingPath = codingPath
    }
    
    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    fileprivate var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        return self.storage.count == self.codingPath.count
    }
    
    // MARK: - Encoder Methods
    public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        // If an existing keyed container was already requested, return that one.
        let topContainer: BinsonDictionary
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
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
        // If an existing unkeyed container was already requested, return that one.
        let topContainer: BinsonArray
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
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


// MARK: - Encoding Storage and Containers
fileprivate struct _BinsonEncodingStorage {
    // MARK: Properties
    /// The container stack.
    private(set) fileprivate var containers: [BinsonValue] = []
    
    // MARK: - Initialization
    /// Initializes `self` with no containers.
    fileprivate init() {}
    
    // MARK: - Modifying the Stack
    fileprivate var count: Int {
        return self.containers.count
    }
    
    fileprivate mutating func pushKeyedContainer() -> BinsonDictionary {
        let dict = BinsonDictionary()
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

// MARK: - Encoding Containers
fileprivate struct _BinsonKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K
    
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: _BinsonEncoder
    
    /// A reference to the container we're writing to.
    private let container: BinsonDictionary
    
    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _BinsonEncoder, codingPath: [CodingKey], wrapping container: BinsonDictionary) {
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
        // Since the float may be invalid and throw, the coding path needs to contain this key.
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
        let dictionary = BinsonDictionary()
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
        return _BinsonReferencingEncoder(referencing: self.encoder, key: _BinsonKey.super, wrapping: self.container)
    }
    
    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return _BinsonReferencingEncoder(referencing: self.encoder, key: key, wrapping: self.container)
    }
}

fileprivate struct _BinsonUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: _BinsonEncoder
    
    /// A reference to the container we're writing to.
    private let container: BinsonArray
    
    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]
    
    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.count
    }
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _BinsonEncoder, codingPath: [CodingKey], wrapping container: BinsonArray) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    
    // MARK: - UnkeyedEncodingContainer Methods
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
        
        let dictionary = BinsonDictionary()
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
        return _BinsonReferencingEncoder(referencing: self.encoder, at: self.container.count, wrapping: self.container)
    }
}

extension _BinsonEncoder : SingleValueEncodingContainer {
    // MARK: - SingleValueEncodingContainer Methods
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
    fileprivate func box(_ value: Int)    -> BinsonValue {
        if Int.bitWidth == 32 {
            return BinsonValue(Int32(value))
        } else {
            return BinsonValue(Int64(value))
        }
    }
    fileprivate func box(_ value: Int8)   -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: Int16)  -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: Int32)  -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: Int64)  -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ value: UInt)    -> BinsonValue {
        if UInt.bitWidth == 32 {
            return BinsonValue(Int32(bitPattern: UInt32(value)))
        } else {
            return BinsonValue(Int64(bitPattern: UInt64(value)))
        }
    }
    fileprivate func box(_ value: UInt8)   -> BinsonValue { return BinsonValue(Int8(bitPattern: value)) }
    fileprivate func box(_ value: UInt16)  -> BinsonValue { return BinsonValue(Int16(bitPattern: value)) }
    fileprivate func box(_ value: UInt32)  -> BinsonValue { return BinsonValue(Int32(bitPattern: value)) }
    fileprivate func box(_ value: UInt64)  -> BinsonValue { return BinsonValue(Int64(bitPattern: value)) }
    fileprivate func box(_ value: String) -> BinsonValue { return BinsonValue(value) }
    fileprivate func box(_ double: Double) throws -> BinsonValue { return BinsonValue(double) }
    
    fileprivate func box(_ data: Data) throws -> BinsonValue { return BinsonValue(data) }

    fileprivate func box<T : Encodable>(_ value: T) throws -> BinsonValue {
        return try self.box_(value) ?? BinsonValue(BinsonDictionary())
    }
    
    // This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
    fileprivate func box_<T : Encodable>(_ value: T) throws -> BinsonValue? {
        if T.self == Data.self || T.self == NSData.self {
            // Respect Data encoding strategy
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

// MARK: - _BinsonReferencingEncoder
/// _BinsonReferencingEncoder is a special subclass of _BinsonEncoder which has its own storage, but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
fileprivate class _BinsonReferencingEncoder : _BinsonEncoder {
    // MARK: Reference types.
    /// The type of container we're referencing.
    private enum Reference {
        /// Referencing a specific index in an array container.
        case array(BinsonArray, Int)
        
        /// Referencing a specific key in a dictionary container.
        case dictionary(BinsonDictionary, String)
    }
    
    // MARK: - Properties
    /// The encoder we're referencing.
    fileprivate let encoder: _BinsonEncoder
    
    /// The container reference itself.
    private let reference: Reference
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given array container in the given encoder.
    fileprivate init(referencing encoder: _BinsonEncoder, at index: Int, wrapping array: BinsonArray) {
        self.encoder = encoder
        self.reference = .array(array, index)
        super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath)

        self.codingPath.append(_BinsonKey(index: index))
    }
    
    /// Initializes `self` by referencing the given dictionary container in the given encoder.
    fileprivate init(referencing encoder: _BinsonEncoder,
                     key: CodingKey, wrapping dictionary: BinsonDictionary) {
        self.encoder = encoder
        self.reference = .dictionary(dictionary, key.stringValue)
        super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath)
        
        self.codingPath.append(key)
    }
    
    // MARK: - Coding Path Operations
    fileprivate override var canEncodeNewValue: Bool {
        // With a regular encoder, the storage and coding path grow together.
        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
        // We have to take this into account.
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }
    
    // MARK: - Deinitialization
    // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
    deinit {
        let value: BinsonValue
        switch self.storage.count {
        case 0: value = BinsonValue(BinsonDictionary())
        case 1: value = self.storage.popContainer()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }
        
        switch self.reference {
        case .array(let array, let index):
            array.insert(value, at: index)
            
        case .dictionary(let dictionary, let key):
            dictionary[key] = value
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
@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
fileprivate var _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()

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
