//
//  AppSettable.swift
//  Bricks
//
//  Created by Ido on 07/07/2022.
//

import Foundation
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppSettable")

fileprivate var appSettings : AppSettings? = nil

// MARK: AppSettable protocol - depends on AppSettings
@propertyWrapper
struct AppSettable<T:Equatable & Codable> : Codable {
    
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
        
    }
    
    enum CodingKeys : String, CodingKey, CaseIterable {
        case name  = "name"
        case value = "value"
    }
    
    // MARK: properties
    private var _value : T
    @SkipEncode var name : String = ""
    
    var wrappedValue : T {
        get {
            return _value
        }
        set {
            let oldValue = _value
            let newValue = newValue
            if newValue != oldValue {
                _value = newValue
                let changedKey = name.count > 0 ? "\(self.name)" : "\(self)"
                AppSettings.shared.noteChange(changedKey, newValue: newValue)
            }
        }
    }

    init(name newName:String, `default` defaultValue : T) {
        
        // basic setup:
        self.name = newName
        
        // Adv. setup:
        if AppSettings.isLoaded {
            // dlog?.info("searching for [\(newName)] in \(AppSettings.shared.other.keysArray.descriptionsJoined)")
            if let loadedVal = AppSettings.shared.other[newName] as? T {
                self._value = loadedVal
                dlog?.success("found and set for [\(newName)] in \(AppSettings.shared.other.keysArray.descriptionsJoined)")
            } else {
                if Debug.IS_DEBUG && AppSettings.shared.other[newName] != nil {
                    dlog?.warning("failed cast \(AppSettings.shared.other[newName].descOrNil) as \(T.self)")
                }
                
                self._value = defaultValue
            }
        } else {
            self._value = defaultValue
        }
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
        try container.encode(name,   forKey: .name)
        try container.encode(_value, forKey: .value)
    }
}
