//
//  Proxy.swift
//  
//
//  Created by Lukas Schmidt on 24.04.20.
//

import Foundation

/// A wrapper around your model that a document uses to track changes the model instance.
///
/// A proxy is provided to the ``Document/change(message:_:)`` as an interface for updating your document's model.
///
/// ## Topics
///
/// ### Getting the Current State of your Document
///
/// - ``Proxy/get()``
///
/// ### Updating a Document
///
/// - ``Proxy/set(_:)``
///
/// ### Updating a Counter Model
///
/// - ``Proxy/increment(_:)``
/// - ``Proxy/decrement(_:)``
///
/// ### Updating a Text Model
///
/// - ``Proxy/insert(_:at:)-4pr84``
/// - ``Proxy/insert(_:at:)-64k5z``
/// - ``Proxy/insert(contentsOf:at:)``
/// - ``Proxy/delete(at:)``
/// - ``Proxy/delete(_:charactersAtIndex:)``
/// - ``Proxy/replaceSubrange(_:with:)-65ff4``
/// - ``Proxy/replaceSubrange(_:with:)-3vg23``
///
/// ### Updating a Table Model
///
/// - ``Proxy/add(_:)``
/// - ``Proxy/row(by:)``
/// - ``Proxy/removeRow(by:)``
///
/// ### Viewing Conflicts in a Document
///
/// - ``Proxy/conflicts(index:)``
/// - ``Proxy/conflicts(dynamicMember:)``
///
/// ### Inspecting a Proxy
///
/// - ``Proxy/objectId``
/// - ``Proxy/subscript(dynamicMember:)-2yow9``
/// - ``Proxy/subscript(dynamicMember:)-9yayd``
/// - ``Proxy/subscript(dynamicMember:)-4p1lt``
/// - ``Proxy/subscript(dynamicMember:)-4irc0``
///
/// ### Converting to a type-erased Proxy
///
/// - ``Proxy/toAny()``

@dynamicMemberLookup
public final class Proxy<Wrapped> {

    init(
        context: Context,
        objectId: ObjectId?,
        path: [Context.KeyPathElement],
        value: @escaping () -> Wrapped?
    ) {
        self.context = context
        self.objectId = objectId
        self.path = path
        self.valueResolver = value
    }

    init(
        context: Context,
        objectId: ObjectId?,
        path: [Context.KeyPathElement],
        value: @autoclosure @escaping () -> Wrapped?
    ) {
        self.context = context
        self.objectId = objectId
        self.path = path
        self.valueResolver = value
    }
    
    /// The Id of the object this proxy represents.
    public let objectId: ObjectId?
    let context: Context
    let path: [Context.KeyPathElement]
    private let valueResolver: () -> Wrapped?

    let objectDecoder = ObjectDecoder()
    let objectEncoder = ObjectEncoder()
    
    /// Returns the current instance of your document's model.
    public func get() -> Wrapped {
        return valueResolver()!
    }

    private var map: Map {
        guard case .map(let map)? = objectId.map({ context.getObject(objectId: $0) }) else {
            fatalError("Must be map")
        }

        return map
    }

    /// Returns the current value of the property using a KeyPath you provide to your model.
    public subscript<Y>(dynamicMember dynamicMember: KeyPath<Wrapped, Y>) -> Proxy<Y> {
        let fieldName = dynamicMember.fieldName!

        let objectId = map[fieldName]?.objectId
        return Proxy<Y>(
            context: context,
            objectId: objectId,
            path: path + [.init(key: .string(fieldName), objectId: objectId)],
            value: self.valueResolver()?[keyPath: dynamicMember]
        )
    }

    func convertToKeyPath<T>(keyPath: AnyKeyPath) -> KeyPath<T, Any>? {
        guard let convertedKeyPath = keyPath as? KeyPath<T, Any> else {
            return nil
        }
        return convertedKeyPath
    }

    /// Returns the current value of the property using a KeyPath you provide to your model.
    public subscript<Y>(dynamicMember dynamicMember: AnyKeyPath) -> Proxy<Y> {
        guard let convertedKeyPath = dynamicMember as? KeyPath<Wrapped, Y> else {
            fatalError()
        }
        let fieldName = convertedKeyPath.fieldName!
        let objectId = map[fieldName]?.objectId
        return Proxy<Y>(
            context: context,
            objectId: objectId,
            path: path + [.init(key: .string(fieldName), objectId: objectId)],
            value: self.valueResolver()?[keyPath: convertedKeyPath]
        )
    }

    /// Returns the current value of the optional property using a KeyPath you provide to your model.
    public subscript<Y>(dynamicMember dynamicMember: KeyPath<Wrapped, Y?>) -> Proxy<Y>? {
        let fieldName = dynamicMember.fieldName!
        let objectId = map[fieldName]?.objectId
        return Proxy<Y>(
            context: context,
            objectId: objectId,
            path: path + [.init(key: .string(fieldName), objectId: objectId)],
            value: self.valueResolver()?[keyPath: dynamicMember]
        )
    }

    /// Returns a mutable proxy to a property in your model at the writable KeyPath you provide.
    public subscript<Y>(dynamicMember dynamicMember: WritableKeyPath<Wrapped, Y>) -> MutableProxy<Y> {
        let keyPath: KeyPath = dynamicMember as KeyPath
        let fieldName = keyPath.fieldName!

        let objectId = map[fieldName]?.objectId
        return MutableProxy<Y>(
            context: context,
            objectId: objectId,
            path: path + [.init(key: .string(fieldName), objectId: objectId)],
            value: self.valueResolver()?[keyPath: dynamicMember]
        )
    }

    /// Returns an mutable proxy to an optional property in your model at the writable KeyPath you provide.
    public subscript<Y>(dynamicMember dynamicMember: WritableKeyPath<Wrapped, Y?>) -> MutableProxy<Y>? {
        let fieldName = dynamicMember.fieldName!
        let objectId = map[fieldName]?.objectId
        return MutableProxy<Y>(
            context: context,
            objectId: objectId,
            path: path + [.init(key: .string(fieldName), objectId: objectId)],
            value: self.valueResolver()?[keyPath: dynamicMember]
        )
    }
    
    func set(newValue: Object) {
        guard let lastPathKey = path.last?.key else {
            if case .map(let root) = newValue {
                set(rootObject: root)
            }
            return
        }
        switch lastPathKey {
        case .string(let key):
            let path = Array(self.path.dropLast())
            context.setMapKey(path: path, key: key, value: newValue)
        case .index(let index):
            let path = Array(self.path.dropLast())
            context.setListIndex(path: path, index: index, value: newValue)
        }
    }
    
    func set(rootObject: Map) {
        for (key, value) in rootObject {
            context.setMapKey(path: path, key: key, value: value)
        }
    }

    public func mergeChangesFrom(other: Proxy<Wrapped>) {

        //                let objectId = list[position].objectId
        //                return Proxy<Wrapped.Element>(
        //                    context: context,
        //                    objectId: objectId,
        //                    path: path + [.init(key: .index(position), objectId: objectId)],
        //                    value: self.get()[position]
        //                )
        //            }
        //        }

        var root = context.getObject(objectId: .root)
        var otherRoot = other.context.getObject(objectId: .root)
//        compareCodableObjects(root, otherRoot)
            switch (root, otherRoot) {
            case let (.text(text), .text(otherText)):
                if text != otherText {
                    set(newValue: otherRoot)
                }
            case let (.map(tmap), .map(otherMap)):

                tmap.mapValues.forEach { key, value in
                    guard let otherValue = otherMap[key] else { return }
                    switch (value, otherValue) {
                    case let (.map(innerMap), .map(innerOtherMap)):
                        innerMap.mapValues.forEach { innerKey, innerValue in
                            print(innerKey)
                            print(innerValue)
                            let innerCurrProxy = Proxy<Any>(
                                context: context,
                                objectId: innerValue.objectId,
                                path: path + [.init(key: .string(innerKey), objectId: innerValue.objectId)],
                                value: innerValue
                            )
                            let otherObjectID = innerOtherMap[innerKey]?.objectId
                            let innerOtherCurrProxy = Proxy<Any>(
                                context: other.context,
                                objectId: otherObjectID,
                                path: other.path + [.init(key: .string(innerKey), objectId: otherObjectID)],
                                value: innerOtherMap[innerKey]
                            )
                            print(innerCurrProxy)
                            innerCurrProxy.mergeChangesFrom(other: innerOtherCurrProxy)
                        }
                    default:
                        break
                    }
//                    currProxy.mergeChangesFrom(other: otherCurrProxy)
                }
            case let (.table(table), .table(otherTable)):
                break
            case let (.list(list), .list(otherList)):
                break
            case let (.counter(counter), .counter(otherCounter)):
                break
            case let (.date(date), .date(otherDate)):
                break
            case let (.primitive(primitive), .primitive(otherPrimitive)):
                if primitive != otherPrimitive {
                    set(newValue: otherRoot)
                }
            default:
                fatalError()
            }
    }
//
//    // Helper function to convert a Codable object to a JSON dictionary
//    func codableToJSONDictionary<T: Codable>(_ object: T) -> [String: Any]? {
//        let encoder = JSONEncoder()
//
//        guard let data = try? encoder.encode(object),
//              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
//            return nil
//        }
//
//        return json
//    }
//
//    // Recursive function to compare two JSON dictionaries and find the path of a change
//    func compareJSONDictionaries(_ lhs: [String: Any], _ rhs: [String: Any], path: String = "") {
//        for (key, lhsValue) in lhs {
//            let newPath = path.isEmpty ? key : path + "." + key
//
//            if let rhsValue = rhs[key] {
//                if type(of: lhsValue) != type(of: rhsValue) {
//                    print("Type mismatch at path: \(newPath)")
//                } else {
//                    if let lhsValue = lhsValue as? [String: Any], let rhsValue = rhsValue as? [String: Any] {
//                        compareJSONDictionaries(lhsValue, rhsValue, path: newPath)
//                    } else if let lhsValue = lhsValue as? CustomStringConvertible, let rhsValue = rhsValue as? CustomStringConvertible {
//                        if lhsValue.description != rhsValue.description {
//                            print("Value mismatch at path: \(newPath)")
//                        }
//                    }
//                }
//            } else {
//                print("Key not found in the second JSON dictionary: \(newPath)")
//            }
//        }
//    }
//
//    // Compare two Codable objects and find the exact path of a change
//    func compareCodableObjects<T: Codable>(_ lhs: T, _ rhs: T) {
//        guard let lhsJSON = codableToJSONDictionary(lhs),
//              let rhsJSON = codableToJSONDictionary(rhs) else {
//            print("Failed to convert objects to JSON dictionaries")
//            return
//        }
//
//        compareJSONDictionaries(lhsJSON, rhsJSON)
//    }
//
//
//    func codableToJSONDictionary1<T: Codable>(_ object: T) -> [String: Any]? {
//        let encoder = JSONEncoder()
//
//        guard let data = try? encoder.encode(object),
//              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
//            return nil
//        }
//
//        return json
//    }
//
//    func applyChanges<T: Codable>(_ lhs: inout T, _ rhs: T) {
//        guard let lhsJSON = codableToJSONDictionary1(lhs),
//              let rhsJSON = codableToJSONDictionary1(rhs) else {
//            print("Failed to convert objects to JSON dictionaries")
//            return
//        }
//
//        applyChangesRecursively(lhs: &lhs, rhs: rhsJSON, path: [])
//    }
//
//
//    func applyChangesRecursively<T: Codable>(lhs: inout T, rhs: [String: Any], path: [String]) {
//        let lhsMirror = Mirror(reflecting: lhs)
//
//        for (key, rhsValue) in rhs {
//            var newPath = path
//            newPath.append(key)
//
//            if let lhsChild = lhsMirror.descendant(<#T##first: MirrorPath##MirrorPath#>, <#T##rest: MirrorPath...##MirrorPath#>) {
//                if type(of: lhsChild) != type(of: rhsValue) {
//                    print("Type mismatch at path: \(newPath.joined(separator: "."))")
//                } else {
//                    if let lhsValue = lhsChild as? [String: Any], let rhsValue = rhsValue as? [String: Any] {
//                        applyChangesRecursively(lhs: &lhs, rhs: rhsValue, path: newPath)
//                    } else if let lhsValue = lhsChild as? CustomStringConvertible, let rhsValue = rhsValue as? CustomStringConvertible {
//                        if lhsValue.description != rhsValue.description {
//                            self[keyPath: <#T##KeyPath<Proxy<Wrapped>, Value>#>]
//                            lhs[keyPath: keyPathFromTuplePath(tuplePath: newPath)] = rhsValue
//                        }
//                    }
//                }
//            } else {
//                lhs[keyPath: keyPathFromTuplePath(tuplePath: newPath)] = rhsValue
//            }
//        }
//    }
}
//        applyChangesRecursively(lhs: &lhs, rhs: rhsJSON, path: [])
//    }
//
//    func applyChangesRecursively<T: Codable>(lhs: inout Automerge.Document<T>, rhs: [String: Any], path: [String]) {
//        for (key, rhsValue) in rhs {
//            var newPath = path
//            newPath.append(key)
//
//            if let lhsValue = lhs.get(path: newPath) {
//                if type(of: lhsValue) != type(of: rhsValue) {
//                    print("Type mismatch at path: \(newPath.joined(separator: "."))")
//                } else {
//                    if let lhsValue = lhsValue as? [String: Any], let rhsValue = rhsValue as? [String: Any] {
//                        applyChangesRecursively(lhs: &lhs, rhs: rhsValue, path: newPath)
//                    } else if let lhsValue = lhsValue as? CustomStringConvertible, let rhsValue = rhsValue as? CustomStringConvertible {
//                        if lhsValue.description != rhsValue.description {
//                            lhs.rootProxy().set(newValue: rhsValue)
//                            lhs.set(path: newPath, value: rhsValue)
//                        }
//                    }
//                }
//            } else {
//                lhs.set(path: newPath, value: rhsValue)
//            }
//        }
//    }
//}
//
