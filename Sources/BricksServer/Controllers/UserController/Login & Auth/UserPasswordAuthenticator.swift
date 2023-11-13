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

// Do NOT add the middleware to all routes during Config!
// This middleware should only be used for the login or auth routes
class UserPasswordAuthenticator : Vapor.AsyncBasicAuthenticator {
    
    // MARK: Types
    // MARK: Const
    // MARK: Static
    static let PWD_HASHING_COST = 12
    
    // MARK: Properties / members
    
    // MARK: Private
    /// Things to do when login was successful
    /// - Parameters:
    ///   - req: request
    ///   - user: user to log in
    ///   - pii: piiInfo used for this login
    ///   - loginInfo: MNUserLoginInfo for the piiInfo
    private func execSuccessfulLogin(req: Vapor.Request, user:AppUser, pii:MNUserPII) {
        req.auth.login(user)
        
        // Create a login/logout history record:
        
        // Save lastUsed dates etc
        
    }
    
    // MARK: Public
    
    static func digestPwdPlainText(plainText:String) throws ->String {
        return try BCryptDigest().hash(plainText, cost: Self.PWD_HASHING_COST)
    }
    
    static private func verifyPwdPlainText(plainText:String, withExistinHashedPwd existingHashed:String) throws ->Bool {
        return try Bcrypt.verify(plainText, created: existingHashed)
    }
    
    private func authenticateLoginUserInfo(basic: Vapor.BasicAuthorization, for req: Vapor.Request, user:MNUser, loginInfo:MNUserLoginInfo) async throws -> Bool {
        dlog?.info("authenticateLoginUserInfo      userPII: \(loginInfo) pii: \(loginInfo.userPII.descOrNil)")
        try await loginInfo.forceLoadAllPropsIfNeeded(db: req.db)
        
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
            self.execSuccessfulLogin(req: req, user: user, pii: userPII)
            return true
        }
        
        return false
    }
    
    /// Authenticate that the username and password are in the DB and valid (user may have multiple MNUserLoginInfos, i.e logins)
    /// NOTE: Assumes req storage has .user
    func authenticate(basic: Vapor.BasicAuthorization, for req: Vapor.Request) async throws {
        dlog?.info("authenticate(basic:) \(basic)")
        
        // Check server is running
        if req.application.appServer == nil || req.application.appServer?.isBooting == true {
            throw AppError(code: .http_stt_expectationFailed, reason: "Server not online")
        }
        
        do {
            var wasAuth = false
            if let user : AppUser = req.getFromReqStore(key: ReqStorageKeys.user) {
                try await user.forceLoadAllPropsIfNeeded(db: req.db)
                
                dlog?.info("LOGIN User: \(user)")
                dlog?.info("LOGIN loginInfos: \(user.loginInfos)")
                var lastError : AppError? = nil
                for loginInfo in user.loginInfos {
                    do {
                        if try await self.authenticateLoginUserInfo(basic: basic, for: req, user:user, loginInfo: loginInfo) {
                            // Was authenticated
                        }
                    } catch let error {
                        lastError = AppError(fromError: error, defaultErrorCode: .user_login_failed, reason:"login error")
                    }
                }
                if let lastError = lastError {
                    // One of the iterations had an error:
                    
                }

                //dlog?.successOrFail(condition: wasAuth, succStr: "login for user:\(user.displayName) success!", failStr: "failed login for user: \(user.displayName)")
                if !wasAuth {
                    // Failed login, but for "normal" reason - most probably pwd mismatch
                    throw AppError(code: .user_login_failed_name_and_password, reason: "Username or password mismatch")
                }
            }
        } catch let error {
            dlog?.warning("authenticate(basic:) failed to verifyPwdPlainText error: \(error)")
            throw AppError(fromError: error, defaultErrorCode: .user_login_failed_name_and_password, reason: "Login credentials exception (98)")
        }
    }
} // End of class
