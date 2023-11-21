//
//  UserPasswordAuthenticator.swift
//  
//
//  Created by Ido on 20/07/2023.
//

import Foundation
import Vapor
import JWT
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

// Follows the BasicAuthenticator / AsyncAuthenticator pattern BUT:
// We do not use Vapor.AsyncAuthenticator because it requires header "basic asdasd|asdasd", and for POST messages we may use the body and not the header:
class UserPasswordAuthenticator : Vapor.AsyncMiddleware {
    
    // MARK: Types
    // MARK: Const
    // MARK: Static
    static let PWD_HASHING_COST = 12
    
    // MARK: Properties / members
    
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
        
        dlog?.info("LOGIN authenticateLoginUserInfo user: \(user.id.descOrNil) loginInfo: \(loginInfo.id.descOrNil)")
        
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
        guard inputDomain.lowercased() == userPII.piiDomain.lowercased() else {
            throw AppError(.user_login_failed_bad_credentials, reason: "domain mismatch")
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
        dlog?.info("Middleware will authenticate(basic:) for req:\(req.id)")
        
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

        do {
            try await user.forceLoadAllPropsIfNeeded(db: req.db)
            
            dlog?.info("LOGIN User: \(user)")
            dlog?.info("LOGIN loginInfos: \(user.loginInfos)")
            var lastError : AppError? = nil
            for loginInfo in user.loginInfos {
                do {
                    if try await self.authenticateLoginUserInfo(loginRequset: loginRequest, for: req, user:user, loginInfo: loginInfo) {
                        // Was authenticated
                        req.saveToReqStore(key: ReqStorageKeys.loginInfos, value: [loginInfo], alsoSaveToSession: true)
                        req.auth.login(user) // User auth in Vapor's internal system - needed for GuardMiddleware to operate correctly
                        wasAuth = true
                    }
                } catch let error {
                    lastError = AppError(fromError: error, defaultErrorCode: .user_login_failed, reason:"login error")
                }
            }
            
            if wasAuth {
                dlog?.success("LOGIN success for user: \(user) username: \(loginRequest.username)")
            } else if let lastError = lastError {
                // One of the iterations had an error:
                throw lastError
            } else {
                // Unknown error
                throw AppError(code: .user_login_failed_name_and_password, reason: "Username or password mismatch")
            }
        } catch let error {
            dlog?.warning("authenticate(basic:) failed to verifyPwdPlainText error: \(error)")
            throw AppError(fromError: error, defaultErrorCode: .user_login_failed_name_and_password, reason: "Login credentials exception (98)")
        }
    }
    
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let isRequiresAuth = (request.route?.mnRoute.requiredAuth.contains(.userPassword) == true)
        // dlog?.note(" >>>> \(Self.self).respond(to: \(request.url.string) req-id:\(request.id)) isRequiresAuth: \(isRequiresAuth)")
        if isRequiresAuth {
            
            var loginRequest : UserLoginRequest? = nil
            if let basic = request.headers.basicAuthorization {
                loginRequest = UserLoginRequest(basicAuth: basic, domain: request.domain ?? AppServer.DEFAULT_DOMAIN)
            }
            
            // We try to parse the body as a UserLoginRequest
            if loginRequest == nil && request.method == .POST{
                loginRequest = try request.content.decode(UserLoginRequest.self)
            }
            
            if let loginRequest = loginRequest {
                request.saveToReqStore(key: ReqStorageKeys.loginRequest, value: loginRequest)
                try await self.authenticate(loginRequest: loginRequest, for: request)
            } else {
                throw AppError(code: .user_login_failed_bad_credentials, reason: "Login credentials malformed")
            }
        }
        
        return try await next.respond(to: request)
    }
} // End of class
