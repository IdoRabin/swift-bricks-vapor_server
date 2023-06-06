//
//  File.swift
//  
//
//  Created by Ido on 23/10/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppRouteInfo")

// public var userInfo: [AnyHashable: Any]
enum RouteProductType : String, Hashable, JSONSerializable {
    case unknown
    case webPage
    case apiResponse
}

enum RouteInfoCodingKeys : String, Hashable, CodingKey, JSONSerializable {
    case ri_productType
    case ri_title
    case ri_desc
    case ri_required_auth
    case ri_fullPath
    case ri_group_name              // path group / collection names (a division of api calls / webpages under the same path / subject)
    case ri_http_methods
    case ri_body_stream_strategy
    case ri_permissions
    
    static let all :  [RouteInfoCodingKeys] = [
        .ri_productType,
        .ri_title,
        .ri_desc,
        .ri_required_auth,
        .ri_fullPath,
        .ri_group_name,
        .ri_http_methods,
        .ri_body_stream_strategy,
        .ri_permissions
    ]
    
}

/// Keys for data stored in the User of Requests:
struct PersonStorageKey : ReqStorageKey {
    typealias Value = Person
}


// Static info per page: - the info in this class does not change for specific instances of the same page.
// For the dynamic info, go to subclasses, such as DashboarPageContext

protocol AppRouteInfoable : AnyObject, JSONSerializable, Hashable, CustomStringConvertible {
    
    var title : String?  { get set }
    var desc : String?  { get set }
    var fullPath: String? { get set }
    var groupName : String? { get set }
    var bodyStreamStrategy : HTTPBodyStreamStrategy { get set }
    func asDict()-> [AnyHashable:Any]
    var isSecure : Bool { get }
    
    // Special merge:
    var productType : RouteProductType { get set }
    var requiredAuth : AppRouteAuth { get set }
    var httpMethods : Set<HTTPMethod>  { get set }
    func update(with other:(any AppRouteInfoable)?)
    func update(with dict : [AnyHashable:Any]?)
    
    // Access control? // Uncomment:
    // func updateRules(with rule:RabacRule)->Bool
    // var rulesNames : [RabacName /*of AppRule */] { get set }
    // var shortRulesNames : [String] { get }
}

extension AppRouteInfoable /* default inmplementation */ {
    
    /* Uncomment:
    var shortRulesNames : [String] {
        return self.rulesNames.map { rname in
            return rname.trimmingPrefix("\(RabacRule.self).")
        }
    }
    */
    
    var isSecure : Bool {
        // Uncomment:
        return false // self.rulesNames.count > 0
    }
    
    fileprivate func updateRulesIntoUserInfo() {
        // Uncomment:
        // self.rulesNames = self.rulesNames.sorted()
        
        // TODO: Check if the following block is to be kept?
//        if let zelf = self as? Vapor.Route {
//            dlog?.todo("updateRulesToUserInfo \(self.fullPath.descOrNil) has \(self.rulesNames.count) rules")
////            let key = RouteInfoCodingKeys.ri_permissions.rawValue
////            zelf.userInfo[key] = self.rulesNames
////            if zelf.path.fullPath.contains("/login") {
////                dlog?.info(" updateRulesIntoUserInfo - \(zelf.appRouteInfo.rulesNames.descriptionsJoined)")
////            }
//        }
    }
    
    func update(with other:(any AppRouteInfoable)?) {
        guard let other = other else {
            dlog?.note("update(with other:) - other AppRouteInfoable is nil!")
            return
        }
        // dlog?.success("[\(self.title.descOrNil)]>[\(other.title.descOrNil)] .update(with other:\(other.title ?? other.fullPath ?? "?")")
        self.title = other.title?.capitalizedFirstWord()
        self.desc = other.desc
        self.fullPath = other.fullPath
        self.groupName = other.groupName
        self.bodyStreamStrategy = other.bodyStreamStrategy
        self.productType = other.productType
        self.requiredAuth = other.requiredAuth
        self.httpMethods = other.httpMethods
        // Uncomment: self.rulesNames = other.rulesNames
        
        // Now update resources with rules:
        self.updateRulesIntoUserInfo()
    }
    
    /* // Uncomment: 
    @discardableResult
    func updateRules(with rule:RabacRule)->Bool {
        var wasChanged = false
        let newName = rule.rabacName
        if !self.rulesNames.appendIfNotAlready(newName) {
            // Update rules names:
            updateRulesIntoUserInfo()
            wasChanged = true
        }
        return wasChanged
    }*/
    
    func update(with dict : [AnyHashable:Any]?) {
        dlog?.todo("update(with dict:) !!")
    }
    
    // MARK: CustomStringConvertible
    var description: String {
        let adesc = self.title ?? self.desc ?? "Unknown name"
        var perm = " ? "
        if self.isSecure {
            /* // Uncomment:
            let rulez = self.shortRulesNames
            if rulez.count > 0 {
                perm = " rules: [\(rulez.joined(separator: ", "))]"
            } else {
                perm = " SECURE (0 rules!)"
            }*/
        } else {
            perm = " NOT SECURE❗\(String(memoryAddressOf: self))"
        }
        
        return "<\(Self.self) \(self.fullPath ?? "<no path>") \"\(adesc.safePrefix(maxSize: 30, suffixIfClipped: "…"))\"\(perm)>"
    }
}


/// Describes all the paremeters of a single routing path in the Vapor routing system.
class AppRouteInfo : AppRouteInfoable {
    
    typealias CodingKeys = RouteInfoCodingKeys
    // Info regarding a Vapor.Route to be saved into each routes' userInfo property:
    // MARK: Statics
    
    // MARK: Properties
    var title : String? = nil
    var desc : String? = nil
    var requiredAuth : AppRouteAuth = .none
    var fullPath: String? = nil
    var groupName : String? = nil
    
    var httpMethods = Set<HTTPMethod>()
    var bodyStreamStrategy : HTTPBodyStreamStrategy = .collect
    var productType : RouteProductType = .webPage
    
    // Uncomment:
    /*
    var rulesNames : [RabacName/*of Rule*/] = [] {
        didSet {
            if Debug.IS_DEBUG && rulesNames.count < oldValue.count || (rulesNames.count == 0 && oldValue.count != 0) ||
                !self.isSecure {
                dlog?.note("[\(self.fullPath.descOrNil)] Did update w/ less permissions? Not secure anymore?")
            }
        }
    }
    
    var rulesNamesOrNil : [RabacName/*of Rule*/]? {
        return (self.rulesNames.count > 0) ? self.rulesNames : nil
    }
    
    var sortedRulesNamesOrNil : [RabacName/*of Rule*/]? {
        return (self.rulesNames.count > 0) ? self.rulesNames.sorted() : nil
    }
    
    func rules()->[RabacRule] {
        return Rabac.shared.rules(byNames: self.rulesNames.sorted())
    }
    */
    
    // MARK: Private
    
    // MARK: Public
    func update(with dict:[AnyHashable:Any]) {
        func biggerString(s1:String,s2:String)->String {
            return s1.count > s2.count ? s1 : s2
        }
        
        for key in CodingKeys.all {
            if let anything = dict[key.rawValue] {
                switch key {
                case .ri_productType:   self.productType  = anything as! RouteProductType
                case .ri_title:         self.title        = anything as? String
                case .ri_desc:          self.desc  = anything as? String
                case .ri_required_auth:
                    if let auth = anything as? AppRouteAuth {
                        self.requiredAuth = self.requiredAuth.union(auth)
                    }
                    
                case .ri_fullPath:
                    
                    let pth = biggerString(s1: (anything as? String) ?? "", s2: (self.fullPath ?? ""))
                    self.fullPath = AppRoutes.normalizedRoutePath(pth)
                    
                case .ri_group_name:
                    self.groupName  = anything as? String
                    if self.groupName?.count ?? 0 == 0 {
                        dlog?.warning("no group name for: \(self.fullPath.descOrNil)")
                    }
                case .ri_http_methods:
                    if let methods = anything as? Set<HTTPMethod> {
                        self.httpMethods.formUnion(methods)
                    } else if let method = anything as? HTTPMethod {
                        self.httpMethods.update(with: method)
                    }
                    
                case .ri_body_stream_strategy:
                    self.bodyStreamStrategy = anything as! HTTPBodyStreamStrategy
                    
                case .ri_permissions:
                    dlog?.todo("Uncomment: .ri_permissions case")
                    // Uncomment:
                    /*
                    var arr : [RabacName] = []
                    if let namesz = (anything as? [RabacRule])?.rabacNames {
                        arr = namesz
                    } else if let namesz = anything as? [RabacName] {
                        arr = namesz
                    } else {
                        dlog?.warning("update(withDict) faield casting to rules names from anything: \(anything)")
                    }
                    self.rulesNames = self.rulesNames.union(with: arr).uniqueElements().sorted()
                    
                    if Debug.IS_DEBUG {
                        if self.rulesNames.count == 0 && self.fullPath?.contains("/login") == true {
                            dlog?.info("update(withDict) >> rulesNames FOR LOGIN IS EMPTY [0]")
                        } else if !self.isSecure {
                            dlog?.info("update(withDict) >> [\(self.fullPath.descOrNil)] was not secured!!")
                        }
                    }*/
                }
            } else {
                // no value for this key
            }
        }   
    }
    
    // MARK: Lifecycle
    init() { /* empty init */ }
    
    
    /*
    init(productType : RouteProductType = .apiResponse,
         title:String,
         description newDesc: String? = nil,
         requiredAuth : AppRouteAuth = .bearerToken,
         group:String? = nil) {
        
        self.productType = productType
        self.title = title
        self.desc = newDesc
        self.requiredAuth = requiredAuth
        self.groupName = group
    }*/
    
    // MARK: Decodable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        for key in CodingKeys.all {
            switch key {
            case .ri_productType:   self.productType    = try container.decode(RouteProductType.self, forKey:key)
            case .ri_title:         self.title          = try container.decode(String.self, forKey:key)
            case .ri_desc:          self.desc           = try container.decodeIfPresent(String.self, forKey:key)
            case .ri_required_auth: self.requiredAuth   = try container.decode(AppRouteAuth.self, forKey:key)
            case .ri_fullPath:      self.fullPath       = try container.decode(String.self, forKey:key)
            case .ri_group_name:    self.groupName      = try container.decodeIfPresent(String.self, forKey:key)
            case .ri_http_methods:  self.httpMethods    = try container.decode(Set<HTTPMethod>.self, forKey:key)
            case .ri_body_stream_strategy: self.bodyStreamStrategy = try container.decode(HTTPBodyStreamStrategy.self, forKey:key)
            // case .ri_permissions:
                //dlog?.todo("uncomment .ri_permissions case")
                // uncomment: self.rulesNames = try container.decodeIfPresent([RabacName].self, forKey:key)?.uniqueElements().sorted() ?? []
            default:
                break
            
            }
        }
    }
    
    // MARK: Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productType,           forKey: .ri_productType)
        try container.encode(title,                 forKey: .ri_title)
        try container.encodeIfPresent(desc,         forKey: .ri_desc)
        try container.encode(requiredAuth,          forKey: .ri_required_auth)
        try container.encode(fullPath,              forKey: .ri_fullPath)
        try container.encode(httpMethods,           forKey: .ri_http_methods)
        try container.encodeIfPresent(groupName,    forKey: .ri_group_name)
        // uncomment: try container.encodeIfPresent(sortedRulesNamesOrNil, forKey: .ri_permissions)
        try container.encode(bodyStreamStrategy,    forKey: .ri_body_stream_strategy)
    }
    
    // MARK: From / To [AnyHashable:Any] Dictionary
    convenience init(fromAnyDictionary dict:[AnyHashable:Any]) {
        self.init()
        self.update(with: dict)
    }
    
    /// Transforms the info class into an [AnyHashable:Any] dictionary
    /// - Returns: [AnyHashable:Any] dictionary with all the properties as key/value pairs
    func asDict()-> [AnyHashable:Any] {
        var result : [AnyHashable:Any] = [:]
        for key in CodingKeys.all {
            switch key {
            case .ri_productType:   result[key.rawValue] = self.productType
            case .ri_title:         result[key.rawValue] = self.title
            case .ri_desc:          result[key.rawValue] = self.desc
            case .ri_required_auth: result[key.rawValue] = self.requiredAuth
            case .ri_fullPath:      result[key.rawValue] = self.fullPath
            case .ri_group_name:    result[key.rawValue] = self.groupName
            case .ri_http_methods:  result[key.rawValue] = self.httpMethods
            case .ri_body_stream_strategy: result[key.rawValue] = self.bodyStreamStrategy
            case .ri_permissions:
                // Set into userInfo:
                dlog?.todo(" uncomment: .ri_permissions case")
                // uncomment:
//                result[key.rawValue] = self.sortedRulesNamesOrNil
//                if Debug.IS_DEBUG && self.rulesNames.count == 0 && self.fullPath?.contains("/login") == true {
//                    dlog?.info("asDict() >> rulesNames FOR LOGIN IS EMPTY [2]")
//                }
            }
        }

        return result
    }
    
    // MARK: Equatable
    static func == (lhs: AppRouteInfo, rhs: AppRouteInfo) -> Bool {
        let result = lhs.fullPath == rhs.fullPath &&
            lhs.requiredAuth == rhs.requiredAuth &&
            lhs.title == rhs.title &&
            lhs.productType == rhs.productType &&
            lhs.desc == rhs.desc &&
            lhs.groupName == rhs.groupName &&
            lhs.httpMethods == rhs.httpMethods &&
            lhs.bodyStreamStrategy == rhs.bodyStreamStrategy // &&
            // uncomment: lhs.rulesNames == rhs.rulesNames // we xpect all rules names to be sorted after any CRUD hanged to the rules names.
        
        if false && Debug.IS_DEBUG &&
            !result && // failes comparing
            lhs.title?.contains("test this route?") == true {
            // uncomment:
//            if lhs.title == rhs.title && lhs.rulesNames != rhs.rulesNames {
//                dlog?.warning("== (Equatable)  >> rulesNames lhs \(lhs.rulesNames.descriptionsJoined) != \(rhs.rulesNames.descriptionsJoined) rhs")
//            }
        }
        return result
    }
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(productType.rawValue)
        hasher.combine(title)
        hasher.combine(desc)
        hasher.combine(requiredAuth.rawValue)
        hasher.combine(fullPath)
        hasher.combine(httpMethods)
        // uncomment: hasher.combine(rulesNames)
        hasher.combine(bodyStreamStrategy)
    }
}

// NIOHTTP1.HTTPMethod
extension HTTPMethod : JSONSerializable, Hashable {

    // MARK: Hahsable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}

extension Sequence where Element == NIOHTTP1.HTTPMethod {
    var strings : [String] {
        return self.map { method in
            return "\(method)".uppercased()
        }
    }
}

extension HTTPBodyStreamStrategy : JSONSerializable, Hashable {

    enum Simplified : String, CodingKey, Codable {
        case collect = "collect"
        case stream = "stream"
    }

    var simplified : Simplified {
        switch self {
        case .collect: return .collect
        case .stream:  return .stream
        }
    }

    var byteIntCount : Int? {
        switch self {
        case .collect(let byteCnt): return byteCnt?.value
        case .stream:  return nil
        }
    }

    // MARK: Equatable
    public static func == (lhs: HTTPBodyStreamStrategy, rhs: HTTPBodyStreamStrategy) -> Bool {
        return lhs.simplified == rhs.simplified && lhs.byteIntCount == rhs.byteIntCount
    }

    // MARK: Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.simplified)
        hasher.combine(self.byteIntCount)
    }

    // MARK: Codable
    enum CodingKeys : String, CodingKey {
        case base = "base"
        case byteCount = "byte_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.simplified, forKey: CodingKeys.base)
        try container.encode(self.byteIntCount, forKey: CodingKeys.byteCount)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(Simplified.self, forKey: .base)
        let sze : Int? = try container.decode(Int?.self, forKey: .byteCount)
        switch base {
        case .stream: self = .stream
        case .collect:
            self = .collect(maxSize: sze != nil ? ByteCount(value: sze!) : nil)
        }
    }
}

/* uncomment
extension AppRouteInfo : RabacCheckable {
    
    func check(req:Vapor.Request, context: [RabacKey : Any]) async -> RabacPermission {
        guard let rulesNames = self.rulesNamesOrNil else {
            dlog?.warning("Route [\(self.description)] has no defined rules names!")
            return .forbidden(code:.forbidden, reason: "This route has no rules names!")
        }
        let rules = Rabac.shared.rules(byNames: rulesNames)
        guard rules.count == rulesNames.count else {
            dlog?.warning("Route [\(self.description)] has no defined rules!")
            return .forbidden(code:.forbidden, reason: "This route has no rules!")
        }
        
        return await rules.check(req: req, context: context)
    }
    
    func check(context: [RabacKey : Any]) async -> RabacPermission {
        guard let rulesNames = self.rulesNamesOrNil else {
            dlog?.warning("Route [\(self.description)] has no defined rules!")
            return .forbidden(code:.forbidden, reason: "This route has no rules!")
        }
        let rules = Rabac.shared.rules(byNames: rulesNames)
        guard rules.count == rulesNames.count else {
            dlog?.warning("Route [\(self.description)] has no defined rules!")
            return .forbidden(code:.forbidden, reason: "This route has no rules!")
        }
        return  await rules.check(context: context)
    }
}
 */

extension Array where Element : AppRouteInfoable {
    
    var fullPaths : [String] {
        return self.compactMap { $0.fullPath }
    }
    
    var titles : [String] {
        return self.compactMap { $0.title }
    }
    
    func groupedToRouteGroups()->[String:[Element]] {
        return self.groupBy { element in
            element.groupName ?? "<no group>"
        }
    }
    
    func sortedByGroupAndPath()->[Element] {
        let grouped = self.groupedToRouteGroups()
        var result : [Element] = []
        for key in grouped.sortedKeys {
            let val : [Element] = (grouped[key]?.sortedByPath() as? [Element]) ?? []
            result.append(contentsOf: val)
        }
        return result
    }
    
    func sortedByGroupAndTitle()->[Element] {
        let grouped = self.groupedToRouteGroups()
        var result : [Element] = []
        for key in grouped.sortedKeys {
            let val : [Element] = (grouped[key]?.sortedByPath() as? [Element]) ?? []
            result.append(contentsOf: val)
        }
        return result
    }
    
    func sortedByPath()->[Element] {
        return self.sorted { a1, a2 in
            return a1.fullPath ?? "<no path>" < a2.fullPath ?? "<no path>"
        }
    }
    
    func sortedByTitle()->[Element] {
        return self.sorted { a1, a2 in
            return a1.title ?? "<no title>" < a2.fullPath ?? "<no title>"
        }
    }
    
}
