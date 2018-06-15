//
//  File: BinsonArray.swift
//  Package: Binson
//
//  Created by Fredrik Littmarck on 2018-06-15.
//

import Foundation

/**
 Wraps a [BinsonValue] into a class with reference semantics. Should be useable in the same way as a the standard
 Array.
 */
public class BinsonArray {
    public typealias InternalArray = Array<BinsonValue>

    private var array = InternalArray()

    public typealias Index = InternalArray.Index
    public typealias Element = InternalArray.Element
    public typealias Indices = InternalArray.Indices
    public typealias Iterator = InternalArray.Iterator
    public typealias SubSequence = InternalArray.SubSequence

    public required init() {
    }

    public required init<S>(_ elements: S) where S : Sequence, BinsonArray.Element == S.Element {
        array = InternalArray(elements)
    }

    public func pack() -> Data {
        let prefix = Data([Mark.beginArrayByte])
        let payload = array.flatMap { $0.pack() }
        let suffix = Data([Mark.endArrayByte])

        return prefix + payload + suffix
    }
}

extension BinsonArray: RandomAccessCollection, MutableCollection {
    public func makeIterator() -> IndexingIterator<InternalArray> {
        return array.makeIterator()
    }

    public var startIndex: Index {
        return array.startIndex
    }

    public var endIndex: Index {
        return array.endIndex
    }

    public func index(after i: Index) -> Index {
        return array.index(after: i)
    }

    public subscript(index: Index) -> BinsonValue {
        get { return array[index] }
        set { array[index] = newValue }
    }
}

extension BinsonArray: RangeReplaceableCollection {

    public func replaceSubrange<C>(_ subrange: Range<BinsonArray.Index>, with newElements: C) where C : Collection, BinsonArray.Element == C.Element {
        array.replaceSubrange(subrange, with: newElements)
    }

    // Simple wrappers for commonly used cases
    public func append(_ newElement: BinsonArray.Element) {
        array.append(newElement)
    }

    public func append<S>(contentsOf newElements: S) where S : Sequence, BinsonArray.Element == S.Element {
        array.append(contentsOf: newElements)
    }

    public func insert(_ newElement: BinsonArray.Element, at i: BinsonArray.Index) {
        array.insert(newElement, at: i)
    }
}

extension BinsonArray: Hashable {
    public var hashValue: Int {
        return array.count
    }
}

extension BinsonArray: Equatable {
    public static func == (lhs: BinsonArray, rhs: BinsonArray) -> Bool {
        return lhs.array == rhs.array
    }
}

extension BinsonArray: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return array.description
    }

    public var debugDescription: String {
        return array.debugDescription
    }
}
