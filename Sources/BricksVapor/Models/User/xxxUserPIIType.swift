//
//  UserPIIType.swift
//
//
//  Created by Ido Rabin for Bricks on 17/1/2024.
//

import Foundation
import Logging
import MNUtils
import MNVaporUtils

fileprivate let dlog : Logger? = Logger(label:"MNUserPIITypes") // ?.setting(verbose: true)

// User personal identifying info
//  mn_user_pii_type
public enum UserPIIType : String, MNDBEnum {

    /// name of the user as one string
    case name = "name"                  // 1 // (1 << 0)
    
    /// email of the user as one string
    case email = "email"                // 2 // (1 << 1)
    
    /// personnelNr of the user as one string (expected to contain only digits and "-" minus sign)
    case personnelNr = "personnel_nr"   // 4 // (1 << 2)
    
    /// uuid of the user as one string (expected to contain only digits and "-" minus sign)
    case uuid = "uuid"                  // 8 // (1 << 3)
    
    var asOptionSet : UserPIITypeSet {
        return UserPIITypeSet(rawValue: self.asInt)
    }
    
    public init?(string: String) {
        switch string.trimmingPrefix(".") {
        case "name":         self = .name
        case "email":        self = .email
        case "personnel_nr": self = .personnelNr
        case "uuid":         self = .uuid
        default:
            dlog?.warning("init?(_ description:) failed init from string(\(string)")
            return nil
        }
    }
    
    var asInt : Int {
        switch self {
        case .name:         return 1 // (1 << 0)
        case .email:        return 2 // (1 << 1)
        case .personnelNr:  return 4 // (1 << 2)
        case .uuid:         return 8 // (1 << 3)
        }
    }
    
    public init?(_ int:Int) {
        switch int {
        case Self.name.asInt:           self = .name
        case Self.email.asInt:          self = .email
        case Self.personnelNr.asInt:    self = .personnelNr
        case Self.uuid.asInt:           self = .uuid
        default:
            return nil
        }
    }
    
    public var displayName : String {
        switch self {
        case .name:         return "username"
        case .email:        return "user email"
        case .personnelNr:  return "personnel nr."
        case .uuid:         return "unique identifier"
        }
    }
}


public extension Sequence where Element == UserPIIType {
    var rawValues : [Int] {
        return self.map { type in
            return type.asInt
        }
    }
    
    var sumValues : Int {
        return self.reduce(0, { partialResult, type in
            return partialResult + type.asInt
        })
    }

    var asOptionSet : UserPIITypeSet {
        return UserPIITypeSet(rawValue: self.sumValues)
    }
}

/// User personal identifying information type. Must be globally unique
public struct UserPIITypeSet: OptionSet, Codable, Hashable, Equatable {
    public let rawValue: Int
    
    static let name          = (1 << 0) // UserPIIType.name.rawValue
    static let email         = (1 << 1) // UserPIIType.email.rawValue
    static let personnelNr   = (1 << 2) // UserPIIType.personnelNr.rawValue
    static let uuid          = (1 << 3) // UserPIIType.uuid.rawValue
    
    public static let allCases = UserPIITypeSet(rawValue: UserPIIType.allCases.sumValues)
    public var asMNUserPIITypes : [UserPIIType] {
        return self.elements.compactMap{ elem in
            return UserPIIType(elem.rawValue)
        }
    }
    
    public init(rawValue input: Int) {
        guard input >= 0 else {
            dlog?.warning("init(rawValue: Int input \(input) has an out-of-bounds component MNUserPIIType (Zero).")
            self.rawValue = 0
            return
        }
        
        var sum : Int = 0
        var remaining = input
        for type in UserPIIType.allCases {
            if (remaining & type.asInt) == type.asInt {
                remaining -= type.asInt
                sum += type.asInt
            } else {
                dlog?.warning("init(rawValue: Int input \(input) has an out-of-bounds component MNUserPIIType.")
            }
        }
        if remaining > 0 {
            dlog?.warning("init(rawValue: Int input \(input) has an out-of-bounds component MNUserPIIType. \(remaining) remaining")
        }
        self.rawValue = sum
    }
}
