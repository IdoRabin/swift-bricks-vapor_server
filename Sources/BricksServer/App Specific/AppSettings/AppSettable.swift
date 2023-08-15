//
//  AppSettable.swift
//  Bricks
//
//  Created by Ido on 07/07/2022.
//

import Foundation
import DSLogger
import MNUtils
import MNVaporUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppSettable")

fileprivate weak var appSettings : AppSettings? = nil

protocol AppSettableKind {
    static var valueType : any Any.Type { get }
    var valueType : any Any.Type { get }
}

extension AppSettableKind /* default implementation */ {
    var valueType : any Any.Type {
        return Self.valueType
    }
}

typealias AppSettableValue = Equatable & Codable & Sendable

extension AppSettable : AppSettableKind {
    static var valueType : any Any.Type {
        return T.self
    }
    
    func setValue<TOther>(_ val : TOther) {
        guard let val = val as? T else {
            dlog?.note("AppSettable<\(TOther.self)>.setValue: \(val). failed: Types mismatch: the param value type should be expected as a: \(valueType.self), not \(TOther.self).")
            return
        }
        self.wrappedValue = val as T
    }

    func getValue<TOther>()->TOther? {
        guard T.self == valueType else {
            dlog?.note("AppSettable<\(TOther.self)>.getValue:. failed: Types mismatch: the return value type should be expected as a: \(valueType.self), not \(TOther.self).")
            return nil
        }
        return self.wrappedValue as? TOther
    }
}

// MARK: AppSettable protocol - depends on AppSettings
@propertyWrapper
final class AppSettable<T:AppSettableValue> : Codable {
    nonisolated private let lock = MNLock(name: "\(AppSettable.self)")

    static var settingsInstance : AppSettings? {
        get {
            return appSettings
        }
        set {
            if appSettings != nil {
                dlog?.warning("AppSettable changing the defined AppSettings!")
            }
            appSettings = newValue
        }
    }
    static func setSettingsInstance(instance: AppSettings) {
        if appSettings == nil {
            appSettings = instance
        } else {
            dlog?.warning("AppSettable \(Self.self) | \(self) already has appSettings defined!")
        }
    }
    
    enum CodingKeys : String, CodingKey, CaseIterable {
        case name  = "name"
        case value = "value"
    }
    
    // MARK: properties
    private var _value : T
    @SkipEncodeSendable var name : String = ""
    
    var wrappedValue : T {
        get {
            return lock.withLock {
                return _value
            }
        }
        set {
            lock.withLockVoid {
                let oldValue = _value
                let newValue = newValue
                if newValue != oldValue {
                    _value = newValue
                    let changedKey = name.count > 0 ? "\(self.name)" : "\(self)"
                    AppSettings.shared.noteChange(key:changedKey, newValue: newValue)
                }
            }
        }
    }

    init(name newName:String, `default` defaultValue : T) {
        
        // basic setup:
        self.name = newName
        self._value = defaultValue
        
        AppSettings.registerDefaultValue(key:newName, value:defaultValue)
        guard AppSettings.sharedIsLoaded else {
            return
        }
        
        dlog?.info("ha!!!!! \(newName) : \(defaultValue)")
        self.wrappedValue = defaultValue
        
        // Adv. setup:
//        if let value = AppSettings.shared.getOtherValue(named:"newName") {
//
//        }
//        Task {
//            var newValue : T = defaultValue
//            // dlog?.info("searching for [\(newName)] in \(AppSettings.shared.other.keysArray.descriptionsJoined)")
//            if let loadedVal = await AppSettings.shared.other[newName] as? T {
//                newValue = loadedVal
//                let keys = await AppSettings.shared.other.keysArray.descriptionsJoined
//                dlog?.success("found and set for [\(newName)] in \(keys)")
//            } else {
//                if Debug.IS_DEBUG && AppSettings.shared.other[newName] != nil {
//                    let desc = await AppSettings.shared.other[newName].descOrNil
//                    dlog?.warning("failed cast \(desc) as \(T.self)")
//                }
//
//                // newValue =
//            }
//            return newValue
//        }
//
//        if let newValue = newValue {
//            dlog?.info("Default value [\(self.name)] - setting to \(newValue)")
//            self._value = newValue
//        } else {
//            dlog?.info("Default value [\(self.name)] - NOT FOUND- set \(newValue)")
//        }
    }
    
    // MARK: AppSettable: Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode only whats needed
        self.name = try container.decode(String.self, forKey: .name)
        self._value = try container.decode(T.self, forKey: .value)
    }
    
    // MARK: AppSettable: Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try lock.withLockVoid {
            try container.encode(name,   forKey: .name)
            try container.encode(_value, forKey: .value)
        }
    }
}
