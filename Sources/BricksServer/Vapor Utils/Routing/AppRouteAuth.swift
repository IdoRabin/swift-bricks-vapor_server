//
//  AppRouteAuth.swift
//  
//
//  Created by Ido on 23/10/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppRouteAuth")

struct AppRouteAuth: OptionSet, Equatable, Hashable, JSONSerializable {
    let rawValue: Int
    
    static let userPassword =       AppRouteAuth(rawValue: 1 << 0) // 1
    static let bearerToken =        AppRouteAuth(rawValue: 1 << 1) // 2
    static let endToEnd =           AppRouteAuth(rawValue: 1 << 2) // 4
    static let backendAccess =      AppRouteAuth(rawValue: 1 << 3) // 8
    static let oAuth =              AppRouteAuth(rawValue: 1 << 4) // 16
    static let webPageAgent =       AppRouteAuth(rawValue: 1 << 5) // 32 - user agent must be a webpage
    
    // Generalizations:
    static let empty: AppRouteAuth = []
    static let none:  AppRouteAuth = []
    static let all:       AppRouteAuth  = [.userPassword, .bearerToken, .endToEnd, .backendAccess, .oAuth, .webPageAgent]
    static let allArray: [AppRouteAuth] = [.userPassword, .bearerToken, .endToEnd, .backendAccess, .oAuth, .webPageAgent]
    
    private static func descriptionForSingle(auth:AppRouteAuth)->String? {
        var result : String? = nil
        switch auth.rawValue {
        case AppRouteAuth.userPassword.rawValue:    result = "userPassword"
        case AppRouteAuth.bearerToken.rawValue:     result = "bearerToken"
        case AppRouteAuth.endToEnd.rawValue:        result = "endToEnd"
        case AppRouteAuth.backendAccess.rawValue:   result = "backendAccess"
        case AppRouteAuth.oAuth.rawValue:           result = "oAuth"
        case AppRouteAuth.webPageAgent.rawValue:    result = "webPageAgent"
        case AppRouteAuth.none.rawValue:            result = nil // no auth needed
        default:
            dlog?.note("AppRouteAuth.descriptionForSingle(auth:AppRouteAuth) failed for: \(auth.rawValue.description).")
            return nil
        }
        
        // NOTE: To snake case!!!
        return result?.camelCaseToSnakeCase()
    }
    
    var descriptions : [String] {
        var result : [String] = []
        for element in self.elements {
            if let desc = AppRouteAuth.descriptionForSingle(auth: element) {
                result.append(desc)
            }
        }
        if result.count == 0 {
            result = ["none"]
        }
        return result
    }
    
    var description : String {
        let descs = self.descriptions
        if descs.count == 1 {
            return descs.first!
        }
        return  "[" + descs.joined(separator: ", ") + "]"
    }
    
    var isShouldFetchUser : Bool {
        return self.intersection([AppRouteAuth.bearerToken, .webPageAgent, .oAuth, .endToEnd]).isEmpty == false
    }
    
    var isShouldFetchAccessToken : Bool {
        return self.intersection([AppRouteAuth.bearerToken, .webPageAgent, .oAuth, .endToEnd]).isEmpty == false
    }
}

// MARK: Codable
extension AppRouteAuth : LosslessStrEnum {
    
    enum CodingKeys : String, CodingKey, CaseIterable {
        case type_int = "type_int"
        case type_str = "type"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if encoder.isJSONEncoder {
            try container.encode(self.descriptions, forKey: .type_str);
        } else {
            try container.encode(self.rawValue, forKey: .type_int)
        }
    }
    
    init?(parts: [String]) {
        var result : AppRouteAuth = []

        for part in parts.lowercased {
            var wasFound = false
            if ["none", "empty"].contains(part) {
                wasFound = true
            } else {
                for auth in Self.allArray {
                    let desc = Self.descriptionForSingle(auth: auth)
                    let unsnaked = desc?.snakeCaseToCamelCase()
                    if part == desc?.lowercased() || part == unsnaked?.lowercased() {
                        result.insert(auth)
                        wasFound = true
                        break
                    }
                }
            }
            
            if !wasFound && !["none", "empty"].contains(part) {
                dlog?.note("AppRouteAuth.init(_ description:String) failed for: \(parts.descriptionsJoined) in part: \"\(part)\"!")
            }
        }

        if result.isEmpty && parts.removing(objects: ["none", "empty"]).count > 0 {
            dlog?.note("AppRouteAuth.init(_ description:String) failed for: \(parts.descriptionsJoined) in all parts.")
            return nil
        }
        
        self.init(rawValue: result.rawValue)
    }
    
    init?(_ description: String) {
        guard description.count > 0 else {
            return nil
        }
        
        var result : AppRouteAuth = []
        
        if description.trimmingCharacters(in: .decimalDigits).count == 0, let num = Int(description) {
            result = AppRouteAuth(rawValue: num)
        } else {
            let parts = description.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).components(separatedBy: ",")
            result = AppRouteAuth(parts:parts) ?? []
        }
        
        self.init(arrayLiteral: result)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var val : Int = 0
        
        for key in container.allKeys {
            switch key {
            case .type_int:
                val = try container.decodeIfPresent(Int.self, forKey: key) ?? 0
            case .type_str:
                do {
                    let strings = try container.decodeIfPresent([String].self, forKey: key) ?? []
                    if let res = AppRouteAuth(parts:strings) {
                        val = res.rawValue
                    } else {
                        throw AppError(code: .misc_failed_decoding, reason: "AppRouteAuth.init(from decoder...) failed from strings: \(strings.descriptionsJoined)") // rethrow!
                    }
                } catch let error {
                    dlog?.warning("init(from decoder...) failed parsing values for key: [\(key)] - expected is an array of strings.. \(String(describing:error))")
                    throw error // rethrow!
                }
            }
        }
        
        self.init(rawValue: val)
    }
}
