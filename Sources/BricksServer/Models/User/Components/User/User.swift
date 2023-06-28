//
//
//  User.swift
//  
//
//  Created by Ido on 16/07/2022.
//

import Foundation
import MNUtils
import DSLogger

#if VAPOR
import Vapor
import Fluent
#endif

// typealias Users = [User]

fileprivate let dlog : DSLogger? = DLog.forClass("User")
fileprivate var _userInstancesCount : UInt64 = 0

enum UsernameType : String, AppModelStrEnum, Codable {
    
    // NOTE: AppModelStrEnum MUST have string values = "my_string_value" for each string case.
    case unknown = "unknown"
    case email  = "useremail"
    case domained = "domained"
    
    static var all : [UsernameType] = [
        .unknown,
        .email,
        .domained,
    ]
    
    static var allActive : [UsernameType] = {
        return Self.all.removing(elementsEqualTo: .unknown)
    }()
}

// MARK: User final class

// TODO: check why final? does Vapor/Fluent require it be final?

/*
final class User : JSONSerializable, MNUIDable {
    
    // MARK: Constants
    static let DEFAULT_USERNAME_DOMAIN = "com.\(AppConstants.APP_NAME)"
    static let USERNAME_QUALIFY_DELIMITER = "⁝" // Triple Colon Operator // https://www.compart.com/en/unicode/U+2AF6
    static let USERNAME_QUALIFY_DELIMITER_HTML = "&#8285;"
    static let USERNAME_QUALIFY_DELIMITER_PERCENT_ESCAPED = "%E2%81%9D"
    
    // MARK: Static
    @AppSettable(name: "User.cahcesFetchedRoles", default: true) static var cahcesFetchedRoles : Bool
    
    enum CodingKeys : String, CodingKey {

        // Basic
        case id             = "id"
        case person         = "person_id"
        case passwordHash   = "password_hash"
        
        // Timestamps
        case createdAt      = "created_at"
        case updatedAt      = "updated_at"
        case deletedAt      = "deleted_at"
        
        // Username components
        case qualifiedUsername = "username_qualified" // should save qaulified username - so that this field can be uniqued!
        case username       = "username" // should save qaulified username - so that this field can be uniqued!
        case usernameType   = "username_type"
        case userDomain     = "user_domain"
        
        // Permissions
        case roles          = "roles"
        
        #if VAPOR
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
        #endif
    }
    
    // MARK: Identifiable / MNUIDable / Vapor "Model" conformance
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    var id : UUID?
    
    var mnUID : MNUID? {
        guard let uid = self.id else {
            return nil
        }
        return UserUID(uid: uid)
    }
    
    @OptionalParent(key: CodingKeys.person.fieldKey)
    var person: Person?
    
    // The Username
    @Field(key: CodingKeys.username.fieldKey)
    var username : String
    
    @Enum(key: CodingKeys.usernameType.fieldKey)
    var usernameType : UsernameType
    
    @Field(key: CodingKeys.userDomain.fieldKey)
    var userDomain : String
    
    // The password (as hash value only!) never save cleartet passwords. ever.
    @Field(key: CodingKeys.passwordHash.fieldKey)
    var passwordHash : String
    
    // When this User was created.
    @Timestamp(key: CodingKeys.createdAt.fieldKey, on: .create)
    var createdAt: Date?
    
    // When this User was last updated.
    @Timestamp(key: CodingKeys.updatedAt.fieldKey, on: .update)
    var updatedAt: Date?
    
    // When this User was last updated.
    @Timestamp(key: CodingKeys.deletedAt.fieldKey, on: .delete)
    var deletedAt: Date?
    
    var qualifiedUsername : String {
        if self.userDomain != Self.DEFAULT_USERNAME_DOMAIN {
            return "\(self.userDomain)\(Self.USERNAME_QUALIFY_DELIMITER)\(self.username)"
        }
        return self.username
    }
    
    // MARK: Static private
    static func determineUsernameType(_ username:String)->UsernameType {
        var result : UsernameType = .unknown
        if username.isValidEmail() {
            result = .useremail
        } else {
            result = .domained
        }
        if Debug.IS_DEBUG && result == .unknown {
            dlog?.note(".determineUsernameType(_) from username: [\(username)] failed! .unknown!")
        }
        return result
    }
    
    static func decomposeQualifiedUsername(_ name:String, domain:String) throws ->(name:String, domain:String, usernameType:UsernameType) {
        let delim = self.USERNAME_QUALIFY_DELIMITER
        var parts = name.components(separatedBy: delim)
        if parts.count == 1 {
            parts = name.components(separatedBy: Self.USERNAME_QUALIFY_DELIMITER_HTML)
            if parts.count == 1 {
                parts = name.components(separatedBy: Self.USERNAME_QUALIFY_DELIMITER_PERCENT_ESCAPED)
            }
        }
        
        var result : (name:String, domain:String, usernameType:UsernameType) = (name:"", domain:"", usernameType:UsernameType.unknown)
        
        if parts.count == 2, parts[0] == domain {
            let untype = Self.determineUsernameType(parts[1])
            result = (name:parts[1], domain:parts[0], usernameType:untype)
        } else if parts.count == 1{
            if name.hasPrefix(domain) {
                dlog?.warning("decomposeQualifiedUsername name has domain prefix but no delimiter!")
            }
            let untype = Self.determineUsernameType((name))
            result = (name:name, domain:domain, usernameType:untype)
        }
        
        return result
    }
    
//      private init(newUserComps:NewUserComps) throws {
        // We make sure the username is parsed correctly and we derived its type and domain correctly:
//        let decomp = try Self.decomposeQualifiedUsername(newUserComps.newUsername, domain: newUserComps.newUserDomain)
//
//        // New comps, used for validation
//        let newComps = NewUserComps(newUsername: decomp.name,
//                                    newUserDomain: decomp.domain,
//                                    newUserPwd: newUserComps.newUserPwd,
//                                    newUsernameType: decomp.usernameType,
//                                    isShouldsanitize: newUserComps.isShouldsanitize)
//
//        // Validate:
//        try NewUserComps.validate(json: newComps.serializeToJsonString()!)
//
//        // Apply
//        self.id = UUID()
//        self.username = newComps.newUsername
//        self.userDomain = newComps.newUserDomain
//        self.usernameType = newComps.newUsernameType
//        self.roles = []
//        // We save only the hashed pwd:
//        do {
//            passwordHash = try Bcrypt.hash(newComps.newUserPwd)
//            // dlog?.success("bcrypt hash length: [\(passwordHash.count)]")
//        } catch let error {
//            dlog?.note("bcrypt hashing failed \(error.localizedDescription)")
//            throw Abort(.unauthorized, reason: "bcrypt hash ch4d9")
//        }
//    }
    
    convenience init(username newUsername:String, userDomain:String = DEFAULT_USERNAME_DOMAIN, pwd newPwd:String, isShouldsanitize:Bool = false) throws {
//        let comps = NewUserComps(newUsername: newUsername,
//                                 newUserDomain: userDomain,
//                                 newUserPwd: newPwd,
//                                 newUsernameType: .unknown,
//                                 isShouldsanitize: isShouldsanitize)
//
//        try self.init(newUserComps: comps)
        throw AppError(code:.http_stt_internalServerError, reason: "Unknown reason")
    }

    // MARK: Static public
    static func validateUsername(_ username:String, domain:String, type:UsernameType)->AppResult<Bool> {
        
//        let comps = NewUserComps(newUsername: username,
//                                 newUserDomain: domain,
//                                 newUserPwd: "",
//                                 newUsernameType: type,
//                                 isShouldsanitize: false)
//        // Validate:
//        do {
//            try NewUserComps.validate(json: comps.serializeToJsonString()!)
//            return .success(true)
//        } catch let error {
//            return .failure(fromError: error)
//        }
        
        return .failure(AppError(code:.http_stt_internalServerError, reason: "Unknown reason"))
        ///AppError(code:.user_invalid_username, reason: "user string cadidate should not be smaller than 4 charahters!")
    }
    
    // MARK: public
    func validateUsrname()->AppResult<Bool> {
        return Self.validateUsername(self.username, domain: self.userDomain, type: self.usernameType)
    }
    
    func validateUsrnameOrThrow() throws {
        switch self.validateUsrname() {
        case .success: break;
        case .failure(let error):
            throw error.asAbort()
        }
    }
    
    // MARK: Vapor Model
    // Vapor Model requires implementing an empty init()
    init() {
        // dlog?.info("new user empty init")
        id = UUID()
    }
    
    // MARK: Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        dlog?.warning("encode user using encoder: \("\(type(of:encoder))") \(encoder.userInfo)")
        
        // Sub-structures
        try container.encodeIfPresent(self.id, forKey:CodingKeys.id)
        try container.encode(self.passwordHash, forKey:CodingKeys.passwordHash)
        
        try container.encodeIfPresent(id?.uuidString, forKey:CodingKeys.id)
        if usernameType != .unknown {
            try container.encode(usernameType, forKey:CodingKeys.usernameType)
        }
        if userDomain != Self.DEFAULT_USERNAME_DOMAIN {
            try container.encode(userDomain, forKey:CodingKeys.userDomain)
        }
        
        if username.count > 0 {
            try container.encodeIfPresent(self.qualifiedUsername, forKey:CodingKeys.username)
        }
        
        // DO NOT ENCODE OR DECODE PASSWORD HASH! we have Fluent schema for that
        try container.encode(createdAt, forKey:CodingKeys.createdAt)
        try container.encodeIfPresent(updatedAt, forKey:CodingKeys.updatedAt)
        try container.encodeIfPresent(deletedAt, forKey:CodingKeys.deletedAt)
        
        // Sub-structures
        try container.encodeIfPresent(person, forKey:CodingKeys.person)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dlog?.warning("decode user using decoder: \("\(type(of:decoder))") \(decoder.userInfo)")
        
        self.id = try container.decodeIfPresent(UUID.self, forKey: CodingKeys.id)
        // TODO: self.person = try container.decodeIfPresent(String.self, forKey: CodingKeys.person)
        self.passwordHash = try container.decode(String.self, forKey: CodingKeys.passwordHash)
        
        // DO NOT ENCODE OR DECODE PASSWORD HASH! we have Fluent schema for that
        self.createdAt =  try container.decodeIfPresent(Date.self, forKey: CodingKeys.createdAt)
        self.updatedAt =  try container.decodeIfPresent(Date.self, forKey: CodingKeys.updatedAt)
        self.deletedAt =  try container.decodeIfPresent(Date.self, forKey: CodingKeys.deletedAt)
        if let person_id =  try container.decodeIfPresent(Date.self, forKey: CodingKeys.person) {
            dlog?.warning("TODO: handle loading PERSON by person_id: \(person_id)")
        }
        
        let qualifiedUsername = try container.decodeIfPresent(String.self, forKey: CodingKeys.qualifiedUsername)
        let username = try container.decodeIfPresent(String.self, forKey: CodingKeys.username)
        self.usernameType = try container.decodeIfPresent(UsernameType.self, forKey: CodingKeys.usernameType) ?? .unknown
        self.userDomain = try container.decodeIfPresent(String.self, forKey: CodingKeys.userDomain) ?? Self.DEFAULT_USERNAME_DOMAIN
        
        // Detect qualified username
        if let qname = qualifiedUsername ?? username {
            let truple = try Self.decomposeQualifiedUsername(qname, domain: self.userDomain)
            if truple.domain != self.userDomain {
                let sample = Debug.IS_DEBUG ? " name: \(name) domain:\(self.userDomain) != truple.domain \(truple.domain)" : ""
                throw AppError(code:.misc_failed_decoding, reason: "Qualified username was not domained correctly" + sample)
            }
            self.username = truple.name
        } else {
            self.username = username ?? "<Usernmae not found User.init(from decoder:)>"
        }
    }
    
    func beforeEncode() throws {
        // clean or hide some values before sending to external clients, check value to validate data
        // Have to *always* pass a name back, and it can't be an empty string.
        
//        let sanitized = Self.sanitizeName(candidate: username.value, forUser: self)
//        switch sanitized {
//        case .success(let sanitizedName):
//            if sanitizedName != self.username {
//                self.username = sanitizedName
//            }
//        case .failure(let err):
//            throw err
//        }
    }
    
    func afterDecode() throws {
        // Sanitize loaded info
//        let sanitized = Self.sanitizeName(candidate: username, forUser: self)
//        switch sanitized {
//        case .success(let sanitizedName):
//            if sanitizedName != self.username {
//                self.username = sanitizedName
//            }
//        case .failure(let err):
//            throw err
//        }
    }
}

// MARK: Equatable User
extension User : Equatable {
    static func == (lhs:User, rhs:User)->Bool {
        if Debug.IS_DEBUG &&
           lhs.id == rhs.id &&
           lhs.updatedAt != rhs.updatedAt {
            // Equality but other update date...
            dlog?.note("Equality between same user \(lhs.description), different updage dates..")
        }
        return lhs.id == rhs.id
    }
}

// MARK: Hashable User
extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.username)
        hasher.combine(self.usernameType)
        hasher.combine(self.userDomain)
        hasher.combine(self.passwordHash)
        hasher.combine(self.createdAt)
        
        // DO NOT: hasher.combine(self.updatedAt) - this is to allow same hash for a user that changed its properties
        hasher.combine(self.deletedAt)
    }
}

// MARK: Hashable CustomStringConvertible
extension User : CustomStringConvertible {
    var description: String {
        let nam = self.qualifiedUsername
        var arr : [String] = []
        if nam.count < 3 {
            dlog?.warning("User.descriptiong WARNING: username is < 3. chars!")
            arr.append(self.id.descOrNil)
        }
        return arr.joined(separator: " ")
    }
}


extension Sequence where Element == User {
    var ids : [UUID] {
        return self.compactMap{ $0.id }
    }
    
    var mnUIDs : [UserUID] {
        return self.compactMap{ ($0.mnUID as! UserUID)}
    }
    
    var names : [String] {
        return self.compactMap{ $0.name }
    }
    
    var usernames : [String] {
        return self.compactMap{ $0.username }
    }
    
    var qualifiedUsernames : [String] {
        return self.compactMap{ $0.qualifiedUsername }
    }
}

//    fileprivate static func sanitizeString(candidate:String?) ->AppResultUpdated<String> {
//
//        guard let candidate = candidate else {
//            return .failure(AppError(code:.user_invalid_user_input, reason: "user input cadidate should not be empty!"))
//        }
//        let origValue  = candidate
//
//        let lowers = candidate.lowercased().components(separatedBy: .whitespacesAndNewlines)
//        for lower in lowers {
//            // Input string should never contain:
//            if AppConstants.FORBIDDEN_INPUT_STRINGS_CONTAINS.contains(where: { forb in
//                forb.contains(lower)
//            }) {
//                return .failure(AppError(code:.user_invalid_user_input, reason: "user input contains forbidden sequences"))
//            }
//
//            // Input string should never equal:
//            if AppConstants.FORBIDDEN_INPUT_STRINGS_IS.contains(where: { forb in
//                forb == lower
//            }) {
//                return .failure(AppError(code:.user_invalid_user_input, reason: "user input has a forbidden word"))
//            }
//        }
//
//        var resultStr = candidate
//        var error : AppError? = nil
//        if resultStr.count == 0 {
//            let missingIdentifierStr = "\(Date().timeIntervalSince1970)"
//            resultStr = "Unknown \(missingIdentifierStr)"
//        } else {
//            resultStr = resultStr.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: .punctuationCharactersWithoutPeriod, with: ".")
//        }
//
//        if resultStr.count < 4 {
//            dlog?.warning("sanitizeString \(resultStr) < 4 chars.")
//            error = AppError(code:.user_invalid_username, reason: "user string cadidate should not be smaller than 4 charahters!")
//        }
//
//        if let error = error {
//            return .failure(error)
//        }
//
//        return AppResultUpdated<String>.sucessBy(equatingPrevValue: origValue, with: resultStr)
//    }

/// Sanitizes a user name candidate for client and server, for a given username or an unknown user.
/// - Parameters:
///   - candidate: candidate string for a usable sanitizad uername
///   - user: user that the name is about to belong to
/// - Returns: sanitized username or error describing why the name is not valid
//    fileprivate static func sanitizeName(candidate:String?, forUser user:User? = nil) ->AppResultUpdated<String> {
//
//        let sanitizeResult = sanitizeString(candidate: candidate)
//        switch sanitizeResult {
//        case .failure(let err):
//
//            return .failure(AppError(code: .http_stt_invalid_input, reason: "username failed sanitizing: \(err.reason)", underlyingError:err))
//        default:
//            // case .successChanged(let baseSanitized):
//            // case .successNoChange(let baseSanitized):
//            let baseSanitized = sanitizeResult.successValue!
//
//            var error : Error? = nil
//            var resultStr = baseSanitized
//
//            if AppConstants.FORBIDDEN_USER_NAME_CONTAINS.lowercased.contains(resultStr.lowercased()) {
//                error = AppError(code:.http_stt_invalid_input, reason: "username contains forbidden segments")
//            }
//
//            if resultStr.count < AppConstants.MIN_USERNAME_LENGTH {
//                return .failure(AppError(code:.http_stt_invalid_input, reason: "username should not be shorter than \(AppConstants.MIN_USERNAME_LENGTH) charahters!"))
//            }
//            if resultStr.count > AppConstants.MAX_USERNAME_LENGTH {
//                return .failure(AppError(code:.http_stt_invalid_input, reason: "username should not be longer than \(AppConstants.MAX_USERNAME_LENGTH) charahters!"))
//            }
//            if Debug.IS_DEBUG {
//                resultStr = resultStr.trimming(string: "**")
//                // TODO: Sanitize sanitizedStr into resultStr
//            }
//
//            // Error was found:
//            if let error = error {
//                return AppResultUpdated.failure(fromError: error)
//            }
//
//            return .sucessBy(equatingPrevValue: candidate, with: resultStr)
//        }
//    }

/// Sanitizes a user name candidate for client and server for the current user
/// - Parameters:
///   - candidate: candidate string for a usable sanitizad uername
///   - user: user that the name is about to belong to
/// - Returns: sanitized username or error describing why the name is not valid
//    fileprivate func sanitizeName(candidate:String) ->AppResultUpdated<String> {
//        return Self.sanitizeName(candidate:candidate, forUser:self)
//    }
*/
