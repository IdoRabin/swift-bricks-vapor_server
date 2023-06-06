//
//  SettingsEnv.swift
//  
//
//  Created by Ido on 24/05/2023.
//

import Foundation

struct SettingsEnv: OptionSet, Codable {
    let rawValue: Int
    
    static let server = SettingsEnv(rawValue: 1 << 0)
    static let client = SettingsEnv(rawValue: 1 << 1)
    
    // All settings
    static let all: SettingsEnv = [.server, .client]
    
    static var currentEnv : SettingsEnv {
        #if VAPOR
        return .server
        #else
        return .client
        #endif
    }
    
    var isInCurrentEnv : Bool {
        return self.contains(Self.currentEnv)
    }
}
