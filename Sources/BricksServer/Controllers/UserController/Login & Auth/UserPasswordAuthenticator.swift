//
//  UserPasswordAuthenticator.swift
//  
//
//  Created by Ido on 20/07/2023.
//

import Foundation
import Vapor
// import JWT
import MNUtils
import MNVaporUtils
import FluentKit
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("UserPasswordAuth")?.setting(verbose: true)

// https://stackoverflow.com/questions/3391242/should-i-hash-the-password-before-sending-it-to-the-server-side
// TL;DR: NO, the client should never hash the pwd before sending!

// Do NOT add the middleware to all routes during Config!
// This middleware should only be used for the login or auth routes

public struct UserLoginRequestStorageKey : ReqStorageKey {
    public typealias Value = UserLoginRequest
}

extension ReqStorageKeys {
    static public let loginRequest = UserLoginRequestStorageKey.self
}

// UserLoginRequestStorageKey

// TODO: check using the ImperialMiddleware instead. (multiple login methods / sources) https://github.com/vapor-community/Imperial/
// Follows the BasicAuthenticator / AsyncAuthenticator pattern BUT:
// We do not use Vapor.AsyncAuthenticator because it requires header "basic asdasd|asdasd", and for POST messages we may use the body and not the header:
// (UPA)
class UserPasswordAuthenticator : Vapor.AsyncMiddleware {
    
    // MARK: Types
    // MARK: Const
    // MARK: Static
    static let PWD_HASHING_COST = 12
    
    // MARK: Properties / members
    var allowedRoles:[String] = []
    
    // MARK: Lifecycle
    init(allowedRoles:[String]) {
        self.allowedRoles = allowedRoles
    }
    
    // MARK: Public
    static func digestPwdPlainText(plainText:String) throws ->String {
        return try BCryptDigest().hash(plainText, cost: Self.PWD_HASHING_COST)
    }
    
    static private func verifyPwdPlainText(plainText:String, withExistinHashedPwd existingHashed:String) throws ->Bool {
        return try Bcrypt.verify(plainText, created: existingHashed)
    }
    
    private func authenticateLoginUserInfo(loginRequset:UserLoginRequest, for req: Vapor.Request, user:MNUser, loginInfo:MNUserLoginInfo) async throws -> Bool {
        return try await authenticateLoginUserInfo(basic: loginRequset.asBasicAuth(), for: req, user: user, loginInfo: loginInfo)
    }
    
    private func authenticateLoginUserInfo(basic: Vapor.BasicAuthorization, for req: Vapor.Request, user:MNUser, loginInfo:MNUserLoginInfo) async throws -> Bool {
        try await loginInfo.forceLoadAllPropsIfNeeded(db: req.db)
        
        dlog?.verbose("authenticateLoginUserInfo checking for userId: \(user.id.descOrNil) loginInfoId: \(loginInfo.id.descOrNil)")
        
        // Check we have a saved userPII:
        guard let userPII = loginInfo.userPII else {
            throw AppError(.user_login_failed_bad_credentials, reason: "userPII not found")
        }
        
        // Check we have a saved password:
        guard let loginPasswordHashed = loginInfo.loginPasswordHashed else {
            throw AppError(.user_login_failed_bad_credentials, reason: "hashed value not found")
        }
        
        let inputUsernameStr = basic.username
        let inputDomain = req.domain ?? AppServer.DEFAULT_DOMAIN
        
        // Check domain:
        if inputDomain.isValidLocalhostIPAddress && Debug.IS_DEBUG {
            // resume on debug mode is the inpu domain is a local ip:
        } else {
            guard inputDomain.lowercased() == userPII.piiDomain.lowercased() else {
                throw AppError(.user_login_failed_bad_credentials, reason: "domain mismatch".mnDebug(add: "\(inputDomain.lowercased()) != \(userPII.piiDomain.lowercased())"))
            }
        }
            
        // Check username / pii string:
        guard inputUsernameStr.lowercased() == userPII.piiString.lowercased() else {
            throw AppError(.user_login_failed_user_name, reason: "username mismatch")
        }
    
        // TODO: Determine if should Validate PiiType?
            
        // Check password:
        // Compare saved hashed pwd with the plaintext basic.password.
        if try Self.verifyPwdPlainText(plainText: basic.password, withExistinHashedPwd: loginPasswordHashed) {
            return true
        }
        
        return false
    }
    
    
    /// Authenticate that the username and password are in the DB and valid (user may have multiple MNUserLoginInfos, i.e logins)
    /// NOTE: Assumes req storage has .user
    func authenticate(loginRequest: UserLoginRequest, for req: Vapor.Request) async throws {
        // Check server is running
        guard let appServer = req.application.appServer, appServer.isBooting == false else {
            throw AppError(code: .http_stt_expectationFailed, reason: "Server not online")
        }
        
        var wasAuth = false
        // get loginInfo using the PII username and userpassword:
        guard let piiInfo = try loginRequest.asPiiInfo() else {
            throw AppError(code: .user_login_failed_bad_credentials, reason: "Bad credientials: User identifying info not found.")
        }
        
        let users = try await appServer.users?.dbFindUsers(db: req.db, piiInfo: piiInfo, permissionGiver: appServer.defaultPersmissionGiver)
        guard users?.count ?? 0 == 1 else {
            throw AppError(code: .user_login_failed_user_not_found, reason: "User/s not found")
        }
        guard let user = users?.first else {
            throw AppError(code: .user_login_failed_user_not_found, reason: "User not found")
        }
        
        // Load loginInfos into the user if needed
        try await user.forceLoadAllPropsIfNeeded(db: req.db)
        
        var lastError : AppError? = nil
        let loginInfos = user.loginInfos
        guard loginInfos.count > 0 else {
            throw AppError(code: .user_login_failed_bad_credentials, reason: "Login info not found")
        }
        
        for loginInfo in loginInfos {
            do {
                if try await self.authenticateLoginUserInfo(loginRequset: loginRequest, for: req, user:user, loginInfo: loginInfo) {
                    // Was authenticated
                    req.saveToReqStore(key: ReqStorageKeys.loginInfos, value: [loginInfo], alsoSaveToSession: true)
                    // NOT NEEDED: we have req.auth . req.saveToReqStore(key: ReqStorageKeys.user, value: user, alsoSaveToSession: true)
                    req.auth.login(user) // User auth in Vapor's internal system - needed for GuardMiddleware to operate correctly
                    wasAuth = true
                }
            } catch let error {
                lastError = AppError(code:.user_login_failed, reason:"login error authenticating", underlyingError: error)
            }
        }
        
        if wasAuth {
            dlog?.verbose(log: .success, "authenticate(basic:) SUCCESS for user: \(user)")
        } else if let lastError = lastError {
            // One of the iterations had an error:
            throw lastError
        } else {
            // Unknown error
            throw AppError(code: .user_login_failed_name_and_password, reason: "Username or password mismatch")
        }
    }
    
    public func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let isRequiresAuth = req.routeContext.requiredAuth.contains(.userPassword) == true
        if isRequiresAuth {
            
            var loginRequest : UserLoginRequest? = nil
            if let basic = req.headers.basicAuthorization {
                loginRequest = UserLoginRequest(basicAuth: basic, domain: req.domain ?? AppServer.DEFAULT_DOMAIN)
            }
            
            // We try to parse the body as a UserLoginRequest
            if loginRequest == nil && req.method == .POST{
                loginRequest = try req.content.decode(UserLoginRequest.self)
            }
            
            if let loginRequest = loginRequest {
                req.saveToReqStore(key: ReqStorageKeys.loginRequest, value: loginRequest)
                try await self.authenticate(loginRequest: loginRequest, for: req)
            } else {
                throw AppError(code: .user_login_failed_bad_credentials, reason: "Login credentials malformed")
            }
        }
        
        return try await next.respond(to: req)
    }
} // End of class
