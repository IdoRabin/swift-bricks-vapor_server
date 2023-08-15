//
//  AppSettingProvider.swift
//  
//
//  Created by Ido on 24/05/2023.
//

import Foundation

protocol AppSettingProvider {
    func noteChange(_ change:String, newValue:Sendable)
    func bulkChanges(block: @escaping  (_ settings : Self) -> Void)
    func resetToDefaults()
    
    var other : [String:Sendable] { get }
    var wasChanged : Bool { get }
    var isLoaded : Bool { get }
}

struct BuildType: OptionSet, Codable, Hashable {
    let rawValue: Int
    
    static let debug = BuildType(rawValue: 1 << 0)
    static let production = BuildType(rawValue: 1 << 1)
    
    // All settings
    static let all: BuildType = [.debug, .production]
    
    static var currentBuildType : BuildType {
        if Debug.IS_DEBUG {
            return .debug
        }
        return .production
    }
}

protocol AppSettingsContainer {
    func getValueFor(key:String)->(any AppSettableValue)?
    mutating func setValueFor(key:String, value:(any AppSettableValue)?)
}





