//
//  AccessToken.swift
//  AccessToken
//
//  Created by Ido on 10/08/2022.
//

import Foundation
import Fluent
import JWT
import MNUtils
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("AccessToken")

// Fields will save this as a flat structure in the DB, with with keys joined by underscore ("_")
// final is needed so that we can maintain a required init()
final class AccessToken : JSONSerializable, Equatable, Hashable {
    static let SEPARATOR = "|"
    static let DEFAULT_TOKEN_EXPIRATION_DURATION : TimeInterval = TimeInterval.SECONDS_IN_A_MONTH * 1 // 1 month
    
    static fileprivate let signer = JWTSigner.hs256(key: AppConstants.ACCESS_TOKEN_JWT_KEY)
    
    // MARK: Static
    public static let emptyToken : AccessToken = AccessToken(uuid:UUID(uuidString: UID_EMPTY_STRING)!)
    public static let zerosToken = emptyToken
    
    let IS_JWT_SIGNED = true
    
    // MARK: Coding keys
    enum CodingKeys : String, CodingKey {
        case id = "id"
        case expirationDate = "expiration_date"
        case lastUsedDate = "last_used_date"
        case user = "user_id"
        case userUUIDStr = "user_id_str"
        
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
    }
    
    // MARK: Identifiable / Vapor "Model" conformance
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    var id: UUID? // NOTE: this is the ID of the AccessToken, not the id of the user
    
    @Field(key: CodingKeys.expirationDate.fieldKey)
    var expirationDate : Date
    
    @Field(key: CodingKeys.lastUsedDate.fieldKey)
    private (set) var lastUsedDate : Date
    
    @Parent(key: CodingKeys.user.fieldKey)
    var user: User
    
    @Field(key: CodingKeys.userUUIDStr.fieldKey)
    private (set) var userUIDString : String
    
    // MARK: Public
    
    /// Returns true when token has a valid uuid (not nil or corrupt) and the token has not expired yet.
    var isValid : Bool {
        guard id != nil else {
            dlog?.warning("AccessToken.isValid is false becuase the id (uuid) is the zero uuid \(UID_EMPTY_STRING)!")
            return false
        }
        return !self.isExpired
    }
    
    /// Returns true when token is expired. (expiration date has passed)
    var isExpired : Bool {
        guard !self.expirationDate.isInThePast else {
            dlog?.warning("AccessToken.isExpired is true becuase the token expiration date has passed \(self.expirationDate.description)!")
            return true
        }
        return false
    }
    
    /// Returns true when the internal property "id" is nil or equals "empty" UUID (00000000-0000-0000-0000-000000000000)
    var isEmpty : Bool {
        guard let id = self.id else {
            dlog?.warning("AccessToken.isEmpty is true becuase the id (uuid) is nil!")
            return true
        }
        
        guard id.uuidString == UID_EMPTY_STRING else {
            dlog?.warning("AccessToken.isEmpty is true becuase the id (uuid) is UID_EMPTY_STRING!")
            return true
        }
        
        return false
    }
    
    func asBearerToken()->String {
        // Bearer token: see:
        var token = (self.$user.$id.value?.uuidString ?? "")
        token += Self.SEPARATOR
        token += String(format:"%0.4f", self.expirationDate.timeIntervalSince1970)
        token = token.toBase64()
        return token
    }
    
    func wasUsedNow() {
        lastUsedDate = Date()
    }
    
    // MARK: Hahsable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    // MARK: Equatable
    static func ==(lhs:AccessToken, rhs:AccessToken)->Bool {
        // We ignore the expiration date
        return lhs.user.id == rhs.user.id
    }
    
    // MARK: Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastUsedDate, forKey: CodingKeys.lastUsedDate)
        try container.encode(expirationDate, forKey: CodingKeys.expirationDate)
        try container.encode(user.id, forKey: CodingKeys.user)
        
        var uidStr = userUIDString
        if uidStr.count == 0, let id = user.id {
            uidStr = id.uuidString
        }
        try container.encode(uidStr , forKey: CodingKeys.user)
    }
    
    init(from decoder: Decoder) throws {
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try keyed.decode(UUID.self, forKey: CodingKeys.id)
        self.expirationDate = try keyed.decode(Date.self, forKey: CodingKeys.expirationDate)
        self.lastUsedDate = try keyed.decode(Date.self, forKey: CodingKeys.lastUsedDate)
        self.userUIDString = try keyed.decodeIfPresent(String.self, forKey: CodingKeys.userUUIDStr) ?? ""
    }
    
    // MARK: Lifecycle
    
    /// Create an access token from a given bearwr token strings
//    / - Parameters:
//    /   - bearerToken: bearer token string from the user to user as the basis for the token
//    /   - allowExpired: allows creating an expired token, or throw an exception if the bearerToken leads to an expired token
    init(bearerToken : String, allowExpired:Bool = false) throws {
        
        guard let decoded = bearerToken.trimmingCharacters(in: .whitespacesAndNewlines).fromBase64()?.components(separatedBy: Self.SEPARATOR), decoded.count > 1 else {
            throw AppError(code:.misc_failed_crypto, reason: "bad access token")
        }
        guard let userId = UserUID(uuidString: decoded[0].trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AppError(code:.misc_failed_crypto, reason: "bad access token format")
        }
        
        // Three years old token?
        guard let expiration = Double(decoded[1].trimmingCharacters(in: .whitespacesAndNewlines)), expiration > -TimeInterval.SECONDS_IN_A_MONTH * 36 else {
            throw AppError(code:.misc_failed_crypto, reason: "bad access token expiration / expired long ago!.")
        }
        
        let date = Date(timeIntervalSince1970: expiration)
        self.$user.id = userId.uid // should load the whole user?
        self.userUIDString = userId.uuidString
        self.expirationDate = date
        self.lastUsedDate = Date()
        
        if self.isExpired {
            if !allowExpired {
                throw AppError(code:.misc_failed_crypto, reason: "Access token expired at: \(self.expirationDate.ISO8601Format(.iso8601)) [AT]")
            } else {
                dlog?.note("Receieved an expired access token for userId: \(userId)")
            }
        }
    }
    
    // Initializer requirement 'init()' can only be satisfied by a 'required' initializer in non-final class 'AccessToken'
    required init() {
        id = UUID()
        expirationDate = Date(timeIntervalSinceNow: AccessToken.DEFAULT_TOKEN_EXPIRATION_DURATION)
        self.lastUsedDate = Date()
    }
    
    required init(uuid:UUID) {
        id = uuid
        expirationDate = Date(timeIntervalSinceNow: AccessToken.DEFAULT_TOKEN_EXPIRATION_DURATION)
        self.lastUsedDate = Date()
    }
}
