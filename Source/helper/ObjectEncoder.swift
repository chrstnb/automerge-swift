//
//  File.swift
//  
//
//  Created by Lukas Schmidt on 19.04.21.
//

import Foundation

public final class ObjectEncoder {

    public func encode<T: Encodable>(_ value: T) throws -> Object {
        let objectEncoding = ObjectEncoding(encodedData: ObjectEncoding.Data())
        if let date = value as? Date {
            return .date(date)
        }
        if let counter = value as? Counter {
            return .counter(counter)
        }
        if let text = value as? Text {
            return .text(text)
        }
        if let url = value as? URL {
            return .primitive(.string(url.absoluteString))
        }
        try value.encode(to: objectEncoding)
        let object = objectEncoding.data.root
        return object
    }

    public func encode<T: Encodable>(_ value: Table<T>) throws -> Object {
        var entries: [ObjectId: Object] = [:]
        for id in value.ids {
            entries[id] = try encode(value[id])
        }
        return .table(Table(tableValues: entries))
    }
}

extension Object {

    mutating func set(value: Object, at codingPath: [CodingKey]) {
        guard codingPath.count != 0 else {
            self = value
            return
        }
        var codingPath = codingPath
        if case .map(var map) = self {
            let key = codingPath.removeFirst().stringValue
            if var valueAtKey = map[key] {
                valueAtKey.set(value: value, at: codingPath)
                map[key] = valueAtKey
            } else {
                map[key] = value
            }
            self = .map(map)
        } else if let key = codingPath.removeFirst().intValue,
                  case .list(var list) = self {
            if list.count <= key {
                list.append(value)
            } else {
                var valueAtKey = list[key]
                valueAtKey.set(value: value, at: codingPath)
                list[key] = valueAtKey
            }
            self = .list(list)
        }
    }
    
}


