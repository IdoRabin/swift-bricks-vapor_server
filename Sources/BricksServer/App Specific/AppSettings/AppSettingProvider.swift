//
//  AppSettingProvider.swift
//  
//
//  Created by Ido on 24/05/2023.
//

import Foundation

protocol AppSettingProvider {
    func noteChange(_ change:String, newValue:Any) async
    func blockChanges(block:(_ settings : any AppSettingProvider)->Void) async
    func resetToDefaults() async
    @discardableResult func saveIfNeeded() async  ->Bool
    @discardableResult func save() async  ->Bool
    
    var other : [String:Any] { get }
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
