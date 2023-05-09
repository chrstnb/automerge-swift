//class DiffDetector {
//    public static func computeDiffs<T>(_ before: Proxy<T>, _ after: T) -> [DiffOutput] {
//        
//        let after = OptionalAnyUnwrapper.unwrap(after)
//
//        // If the current comparable values conform to KeyPathIterable, we recurse on their keypaths
//        // instead of comparing them directly.
////        if let beforeNestedStruct = before.content as? (any KeyPathIterable),
//           if let afterNestedStruct = after as? (any KeyPathIterable) {
//            var allDiffs: [DiffOutput] = []
//            let type = type(of: afterNestedStruct)
//            type.allPaths.forEach { path in
//
//                let afterChild = afterNestedStruct[keyPath: path] as Any
//                DiffOperation(path: [], diff: .map(.init(objectId: .root, type: Contet)))
//                allDiffs.append(contentsOf: diffs.map { .init(operation: $0.operation, path: [.keyPath(path)] + $0.path) })
//            }
//            return allDiffs
//        }
//
//        if let beforeEnum = before as? (any DiffableEnum),
//           let afterEnum = after as? (any DiffableEnum) {
//            if beforeEnum.label != afterEnum.label {
//                guard let afterEnum = afterEnum as? (any Equatable) else { return [] }
//                return [.init(operation: .replace(afterEnum), path: [])]
//            }
//            guard beforeEnum.innerValue != nil, afterEnum.innerValue != nil else { return [] }
//            return Self.computeDiffs(beforeEnum.innerValue, afterEnum.innerValue)
//                .map { .init(operation: $0.operation, path: [.enumPath(beforeEnum.label)] + $0.path) }
//        }
//
//        if let beforeArray = before as? [AnyHashable],
//           let afterArray = after as? [AnyHashable] {
//            // TODO(FUN-1611): use equatable over hashable
//            return computeArrayDiffs(beforeArray, afterArray)
//        }
//
//        if let beforeDict = before as? [AnyHashable: AnyHashable],
//           let afterDict = after as? [AnyHashable: AnyHashable] {
//            return computeDictDiffs(beforeDict, afterDict)
//        }
//
//        if let before = before as? (any Equatable),
//           let after = after as? (any Equatable) {
//            return before.isEqual(to: after) ? [] : [.init(operation: .replace(after), path: [])]
//        }
//
//        fatalError("Unimplemented")
//    }
//
//    static func computeArrayDiffs<T: Hashable>(_ before: [T], _ after: [T]) -> [DiffOutput] {
//        if (before as? (any KeyPathIterable)) != nil {
//            fatalError("KeyPathIterable values will not be deeply diffed.")
//        }
////        let arrayDifference = after.difference(from: before).inferringMoves()
//        var allDiffs: [DiffOutput] = []
////        for change in arrayDifference {
////            switch change {
////            case let .remove(index, _, _):
////                allDiffs.append(.init(operation: .remove, path: [.arrayIndex(index)]))
////            case let .insert(index, newElement, _):
////                allDiffs.append(.init(operation: .insert(newElement), path: [.arrayIndex(index)]))
////            }
////        }
//        return allDiffs
//    }
//
//    static func computeDictDiffs<K: Hashable, V: Hashable>(_ before: [K: V], _ after: [K: V]) -> [DiffOutput] {
////        let keyDifference = after.keys.array.difference(from: before.keys.array)
//        var allDiffs: [DiffOutput] = []
////        for change in keyDifference {
////            switch change {
////            case let .remove(_, key, _):
////                allDiffs.append(.init(operation: .remove, path: [.dictionaryKey(key)]))
////            case let .insert(_, newKey, _):
////                guard let newValue = after[newKey] else { fatalError("No value for key.") }
////                allDiffs.append(.init(operation: .insert(newValue), path: [.dictionaryKey(newKey)]))
////            }
////        }
////        let childDiffs: [[DiffOutput]] = before.map { key, value -> [DiffOutput]? in
////            guard let afterValue = after[key] else { return nil }
////            let childDiffs = computeDiffs(value, afterValue)
////            return childDiffs.map { childDiff in
////                DiffOutput(operation: childDiff.operation, path: [.dictionaryKey(key)] + childDiff.path)
////            }
////        }.compactMap { $0 }
////        allDiffs.append(contentsOf: childDiffs.flatMap { $0 })
//        return allDiffs
//    }
//}
//
//// Can be used to pull out an Any wrapped in an Any<Optional<Any>>
//public enum OptionalAnyUnwrapper {
//    static func unwrap(_ any: Any) -> Any {
//        let mirror = Mirror(reflecting: any)
//        if !mirror.isOptional {
//            return any
//        }
//        guard let (_, some) = mirror.children.first else { return any }
//        return some
//    }
//}
//
//extension Mirror {
//    var isOptional: Bool {
//        displayStyle == .optional
//    }
//}
//
//
//public struct DiffOutput: Equatable {
//    public var operation: DiffOperation
//    public var path: DiffPath
//
//    // sourcery:inline:auto:Diff.AutoInit
//    // swiftformat:disable:all
//    // swiftlint:disable all
//    public init(
//        operation: DiffOperation,
//        path: DiffPath
//    ) {
//        self.operation = operation
//        self.path = path
//    }
//    // swiftlint:enable all
//    // swiftformat:enable:all
//    // sourcery:end
//}
//
//
//public struct DiffOperation {
//    var path: [KeyPathElement]
//    var diff: Diff
//}
//public enum DiffOperation {
//    case insert(any Equatable)
//    case remove
//    case replace(any Equatable)
//}
//
//public enum PathComponent: Equatable {
//    case keyPath(AnyKeyPath)
//    case arrayIndex(Int)
//    case dictionaryKey(AnyHashable)
//    // TODO(FUN-1608): remove reliance on strings here.
//    case enumPath(String)
//}
//
//public typealias DiffPath = [PathComponent]
//
//extension DiffOperation: Equatable {
//    public static func ==(lhs: DiffOperation, rhs: DiffOperation) -> Bool {
//        switch (lhs, rhs) {
//        case (let .replace(lhsValue), let .replace(rhsValue)):
//            return lhsValue.isEqual(to: rhsValue)
//        case (let .insert(lhsValue), let .insert(rhsValue)):
//            return lhsValue.isEqual(to: rhsValue)
//        case (.remove, .remove):
//            return true
//        default:
//            return false
//        }
//    }
//
//    public var description: String {
//        switch self {
//        case let .insert(any):
//            return "Insert \(any)"
//        case .remove:
//            return "Remove"
//        case let .replace(any):
//            return "Replace \(any)"
//        }
//    }
//}
//
//extension Equatable {
//    // Allows you to compare two any equatable values.
//    func isEqual(to other: any Equatable) -> Bool {
//        guard let other = other as? Self else {
//            return false
//        }
//        return self == other
//    }
//}
//
///// Used to identify structs and classes that are deeply diffable.
///// To conform, classes/structs must provide a list of all deeply-diffed keypaths.
//public protocol KeyPathIterable {
//    static var allPaths: [AnyKeyPath] { get }
//}
//
///// Used to identify enums that are deeply diffable via associated values.
///// Provides a string-based label of the enum and an innerValue, if one exists.
//protocol DiffableEnum {}
//
//extension DiffableEnum {
//    var label: String {
//        let mirror = Mirror(reflecting: self)
//        guard mirror.displayStyle == .enum,
//              let value = mirror.children.first,
//              let label = value.label else {
//            return "\(self)"
//        }
//        return label
//    }
//
//    var innerValue: Any? {
//        let reflection = Mirror(reflecting: self)
//        guard reflection.displayStyle == .enum,
//              let value = reflection.children.first else {
//            return nil
//        }
//        return value.value
//    }
//}
//
//
//public extension Collection {
//    /// Idiomatic helper to Array(self)
//    var array: [Element] { Array(self) }
//}
