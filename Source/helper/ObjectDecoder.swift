//
//  File.swift
//  
//
//  Created by Lukas Schmidt on 29.04.21.
//

import Foundation

public final class ObjectDecoder {

    public let encoder = JSONEncoder()
    public let decoder = JSONDecoder()

    public func decode<T: Codable>(_ object: Object) throws -> T {
        let encoded = try encoder.encode(object)
        return try decoder.decode(T.self, from: encoded)
    }

    public func decode<T: Codable>(_ object: [String: Object]) throws -> [String: T] {
        let encoded = try encoder.encode(object)
        return try decoder.decode([String: T].self, from: encoded)
    }

}
