//
//  RememberMeType.swift
//
//
//  Created by Ido on 08/11/2023.
//

import Foundation
import MNUtils


/// Allows future upgrading beyond the simple "remember me" or not bool value
public enum RememberMeType : String, MNDBEnum {
    case rememberMe = "remember_me"
    case forgetMe = "forget_me"
    
    var intValue : Int {
        switch self {
        case .rememberMe: return 1
        case .forgetMe: return 0
        }
    }
    
    public init?(intValue: Int) {
        for enumVal in RememberMeType.allCases {
            if intValue == enumVal.intValue {
                self = enumVal
                return
            }
        }
        return nil
    }
    
    public init?(boolValue: Bool) {
        self = boolValue ? .rememberMe : .forgetMe
    }
}
