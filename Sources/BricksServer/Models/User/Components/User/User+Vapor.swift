//
//  User+Vapor.swift
//  
//
//  Created by Ido on 08/07/2022.
//

import Foundation

#if VAPOR
import Vapor
import Fluent
import FluentKit
import FluentPostgresDriver
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("User")
/*
// Extensions requiring no implementations
extension User : Content {} // Convertible to / from content in an HTTP message.
extension User : Authenticatable {}
extension User : AsyncResponseEncodable, ResponseEncodable {}

/// Keys for data stored in the User of Requests:
struct UserStorageKey : ReqStorageKey {
    typealias Value = User
}

struct SelfUserStorageKey : ReqStorageKey {
    typealias Value = User
}

struct SelfUserIDStorageKey : ReqStorageKey {
    typealias Value = String
}

// MARK: ModelAuthenticatable User // Auth with bearer token
extension User : ModelAuthenticatable {
    
    static var usernameKey = \User.$username //keypath to username
    static var passwordHashKey = \User.$passwordHash // keypath to password hash

    /// Verifies that a given password for this user matches the saved password's hash
    /// - Parameter password: password to be verified for this user
    /// - Returns: Bool if given password indeed is this user's password.
    func verify(password: String) throws -> Bool {
        // Compare the password with the alread-encrypted hashed password that was saved.
        // We never save a password in plaintext or using a bidirectional encryption algo.
        try Bcrypt.verify(password, created: self.passwordHash) // using BCrypt for passwords as defined in config
    }
}
 */

#endif // #if VAPOR

