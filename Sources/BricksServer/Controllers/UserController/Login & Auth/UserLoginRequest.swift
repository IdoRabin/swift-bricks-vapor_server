//
//  UserLoginRequest.swift
//
//
//  Created by Ido on 13/11/2023.
//

import Foundation
import Vapor
import MNUtils
import MNVaporUtils

// https://stackoverflow.com/questions/3391242/should-i-hash-the-password-before-sending-it-to-the-server-side
// TL;DR: NO, the client should never hash the pwd!

public struct UserLoginRequest : Content, JSONSerializable { // todo: , UserLoginable
    public static let USER_DOMAIN_EMPTY = ""
    public static let USER_DOMAIN_DEFAULT = AppServer.DEFAULT_DOMAIN
    
    let username : String
    let userPassword : String
    fileprivate(set) var userDomain : String = Self.USER_DOMAIN_DEFAULT
    fileprivate(set) var rememberMe : RememberMeType = .forgetMe
    fileprivate(set) var usernameType: MNUserPIIType = .name
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case username       = "username"
        case userPassword   = "password"
        case userDomain     = "domain"
        case rememberMe    = "remember_me"
        case usernameType   = "username_type"
    }
    
    public init(username:String, userPassword:String, userDomain: String? = nil, rememberMe:RememberMeType = .forgetMe, usernameType:MNUserPIIType? = nil) {
        self.username = username
        self.userPassword = userPassword
        self.userDomain = userDomain ?? Self.USER_DOMAIN_EMPTY
        self.rememberMe = rememberMe
        if username.count > 0 {
            self.usernameType = usernameType ?? MNUserPIIType.detect(string: username) ?? .name
        } else {
            self.usernameType = .name
        }
    }
    
    public static var empty : UserLoginRequest {
        return UserLoginRequest(username: "", userPassword: "", userDomain: Self.USER_DOMAIN_EMPTY)
    }
    
    public var isEmpty : Bool {
        return username == "" &&
            userPassword == "" &&
            userDomain == Self.USER_DOMAIN_EMPTY
    }
    
    public func asPiiInfo() throws -> MNPIIInfo? {
        
        // TODO Sanitizae and guard Guard user name and pwd input guard username.count > MIN_USER
        let hashedPwd = try UserPasswordAuthenticator.digestPwdPlainText(plainText: userPassword)
        return MNPIIInfo(piiType: usernameType,
                         strValue: username, // any str field for the username, may be email or any other unique user identifier that is not a scret, known to the user
                         domain: userDomain,
                         hashedPwd: hashedPwd)
    }
    
    public func asBasicAuth() throws -> BasicAuthorization {
        return BasicAuthorization(username: self.username, password: self.userPassword)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try container.decode(String.self, forKey: .username)
        self.userPassword = try container.decode(String.self, forKey: .userPassword)
        let keys = container.allKeys
        if keys.contains(.userDomain) {
            self.userDomain = try container.decode(String.self, forKey: .userDomain)
        } else {
            self.userDomain = Self.USER_DOMAIN_EMPTY
        }
        
        if keys.contains(.rememberMe) {
            let strValue = try container.decode(String.self, forKey: .rememberMe)
            if strValue.isAllDigits, let intVal = Int(strValue), let remVal = RememberMeType(intValue: intVal) {
                self.rememberMe = remVal
            } else {
                switch strValue.lowercased() {
                case "true", "yes", RememberMeType.rememberMe.rawValue:
                    self.rememberMe = .rememberMe
                case "false", RememberMeType.forgetMe.rawValue:
                    fallthrough
                default:
                    self.rememberMe = .forgetMe
                }
            }
        }
        
        if keys.contains(.usernameType) {
            self.usernameType = try container.decode(MNUserPIIType.self, forKey: .usernameType)
        } else {
            self.usernameType = MNUserPIIType.detect(string: self.username) ?? .name
        }
    }
    
    public mutating func update(for req:Request) {
        if self.userDomain == UserLoginRequest.USER_DOMAIN_EMPTY {
            self.userDomain = req.domain ?? AppServer.DEFAULT_DOMAIN
        }
    }
    
    public init?(basicAuth: BasicAuthorization? = nil, domain:String) {
        guard let basicAuth = basicAuth else {
            return nil
        }
        
        // TODO: Add sanitations and validations
        
        self.username = basicAuth.username
        self.userPassword = basicAuth.password
        self.rememberMe = RememberMeType.forgetMe
        self.userDomain = domain
        self.usernameType = MNUserPIIType.detect(string: basicAuth.username) ?? .name
    }
}

// MARK: Resposne
struct UserLoginResponse : AppEncodableVaporResponse {
    let bearerToken : String
    let isNewlyRenewed : Bool
}
