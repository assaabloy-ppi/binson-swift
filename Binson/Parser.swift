//  Parser.swift
//  Binson
//
//  Created by Kenneth Pernyer on 2017-05-05.

import Foundation

/// Mark - Protocol Inspector
public protocol Walker {
    func get() -> (String, Value)?
    
    func next() throws -> Walker
    func skip(_ n: Int16) throws -> Walker
    func goto(_ key: String) throws -> Walker
}

// MARK: - Parser
public class BinsonParser: Walker {
    
    var iterator: IndexingIterator<[String]>
    let message: Binson
    var current: String?

    init(_ message: Binson) {
        self.message = message
        
        let pairs = message.values()
        iterator = pairs.keys.sorted().makeIterator()
    }

    public func get() -> (String, Value)? {
        guard let key = current, let value = message.value(key: key) else {
            return nil
        }
        
        return (key, value)
    }
    
    public func next() throws -> Walker {
        guard let key = iterator.next() else {
            throw BinsonError.insufficientData
        }
        
        current = key
        return self
    }
    
    public func skip(_ n: Int16) throws -> Walker {
        throw BinsonError.notFound

    }
    
    public func goto(_ key: String) throws -> Walker {
        throw BinsonError.notFound
    }
}

// MARK: - ByteParser
/// FIXME
public class ByteParser: Walker {
    private let bytes: [Byte]
    
    init(data: Data) {
        bytes = data.bytes
    }
    
    public func get() -> (String, Value)? {
        return nil
    }
    
    public func next() throws -> Walker {
        throw BinsonError.insufficientData
    }
    
    public func skip(_ n: Int16) throws -> Walker {
        throw BinsonError.insufficientData
    }
    public func goto(_ key: String) throws -> Walker {
        throw BinsonError.insufficientData
    }
}
