//
//  UserController+Login.swift
//
//
//  Created by Ido on 01/12/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils
import MNVaporUtils
import Fluent
import FluentKit

fileprivate let dlog : DSLogger? = DLog.forClass("UserController+Login")
extension UserController {
    
    // MARK: fileprivate util functions
    fileprivate func getSelfUser(req: Request) async throws->AppUser? {
        try await UserTokenAuthenticator().authenticate(request: req)
        if let selfUser = req.selfUser { // getSelfUser(isTryDeepQuery:true) {
            return selfUser
        }
        dlog?.warning("TODO: Remimplement getSelfUser(req:)")
        return nil
    }
    
    // MARK: Private
    /// Things to do when login was successful
    /// - Parameters:
    ///   - req: request
    ///   - user: user to log in
    ///   - pii: piiInfo used for this login
    ///   - loginInfo: MNUserLoginInfo for the piiInfo
    private func execSuccessfulLogin(db:any Database, req: Vapor.Request?, user:AppUser, pii:MNUserPII) async throws {
        
        // Load if needed
        if pii.$loginInfo.value == nil {
            _ = try await pii.$loginInfo.get(on: db)
        }
        
        let loginInfo = pii.loginInfo
        
        // Load if needed
        if loginInfo.$accessToken.value == nil {
            _ = try await loginInfo.$accessToken.get(on: db)
        }
        
        // Create / Use existing accessToken:
        var loginToken : MNAccessToken? = loginInfo.accessToken
        if let at = loginInfo.accessToken {
            loginToken = at
        } else {
            // Test all available accessTokens for loginInfo compatibility
            for token in user.validAccessTokens {
                // Load if needed
                if token.$loginInfo.value == nil {
                    _ = try await token.$loginInfo.get(on: db)
                }
                
                dlog?.info("LOGIN   token.userUIDString \(token.userUIDString.descOrNil) ==? USR \(user.id?.uuidString ?? "<nil>")")
                if token.userUIDString != user.id?.uuidString {
                    continue
                }
                
                dlog?.info("LOGIN   token.userUIDString \(token.userUIDString.descOrNil) ==? PII \(pii.userId?.uuidString ?? "<nil>")")
                if token.userUIDString != pii.userId?.uuidString {
                    continue
                }
                
                dlog?.info("LOGIN   token.loginInfo \(token.loginInfo?.id?.uuidString ?? "<nil>") ==? \(pii.loginInfo.id.descOrNil)")
                if token.loginInfo?.id != pii.loginInfo.id {
                    continue
                }
                
                loginToken = token
                break
            }
        }
        if loginToken == nil {
            // Create new access token
            let newToken = MNAccessToken(loginInfo: loginInfo)
            loginInfo.accessToken = newToken
            // ? Should we? user.loginInfos.append(loginInfo)
            DLog.note("LOGIN    New access token created: \(newToken) (none found)!")
            loginToken = newToken
        }
        
        dlog?.info("LOGIN found token: \(loginToken.descOrNil)")
        
        // Save lastUsed dates etc
        let now = Date.now
        loginToken?.lastUsedDate = now // Should we mark this as a login using this accessToken?
        loginInfo.latestLoginDate = now
        
        loginInfo.isLoggedIn = true
        
        // Save to request / session:
        if let req = req {
            // DO NOT: req .auth .login(user)  - this is to be called in the various authenitation Middlewares.
            req.saveToReqStore(key: ReqStorageKeys.selfUser, value: user, alsoSaveToSession: true)
            req.saveToReqStore(key: ReqStorageKeys.selfUserID, value: user.id!.uuidString, alsoSaveToSession: true)
            req.saveToReqStore(key: ReqStorageKeys.selfAccessToken, value: loginToken, alsoSaveToSession: true)
        }
        
        // Save to db:
        try await user.save(on: db)
        try await loginInfo.save(on: db)
        try await loginToken?.save(on: db)
    }
    
    // MARK: actual request/s
    /// Login a user to the system
    /// - Parameter req  login reuqest content
    /// - Returns: UserLoginResponse containing the User structure and the bearerToken
    func login(req: Request) async throws -> UserLoginResponse {
        dlog?.info("login(req:) ------ ")
        throw AppError(code: .user_login_failed_bad_credentials, reason: "User login failed: bad credientials (unknown)")
    }
    
    func XXlogin(req: Request) async throws -> UserLoginResponse {
        throw AppError(code: .user_login_failed_bad_credentials, reason: "User login failed: bad credientials (unknown)")
        /*
        
        
        // Get the user we are trying to login using the pii info:
        var loginReq = UserLoginRequest.empty
        do {
            loginReq = try req.content.decode(UserLoginRequest.self)
        } catch let error {
            dlog?.note("login(request:...) content could not be parsed: \(error.description)")
        }
        
        // Make sure domain is correct and equals the current domain:
        if loginReq.userDomain == UserLoginRequest.USER_DOMAIN_EMPTY {
            loginReq.userDomain = req.domain ?? AppServer.DEFAULT_DOMAIN
        } else if loginReq.userDomain != req.domain {
            throw AppError(code: .user_login_failed_bad_credentials, reason: "Bad credientials: Domain access issue.")
        }
            
        guard let piiInfo = try loginReq.asPiiInfo() else {
            throw AppError(code: .user_login_failed_bad_credentials, reason: "Bad credientials: User identifying info not found.")
        }
        
        // Find user and permission:
        let permissionGiver : AppPermissionGiver = req.selfUser ?? appServer.defaultPersmissionGiver
        let users = try await self.dbFindUsers(db: req.db, pii: piiInfo, permissionGiver: permissionGiver)
        guard let user = users.first else {
            throw AppError(code: .user_login_failed_user_not_found, reason: "User was not found")
        }
        
        // Load all relevant sub-components:
        try await user.forceLoadAllPropsIfNeeded(db: req.db)

        // Save pii and user info into req storage:
        req.saveToReqStore(key: ReqStorageKeys.user.self, value: user)
        let passAuthenticator = req.application.middleware.getMiddleware(ofType: UserPasswordAuthenticator.self) ?? UserPasswordAuthenticator()
        let basicAuthorization = BasicAuthorization(username: piiInfo.strValue, password: loginReq.userPassword)
        
        // Authenticate using Vapor mechanisms:
        try await passAuthenticator.authenticate(basic: basicAuthorization, for: req)
        // Success or authenticate threw a login error:
        
        /*
            MNUser
             - personInfo : MNPersonInfo? (as child)
                - name : MNPersonName? (as field)
             - loginInfos : [MNUserLoginInfo]  (as children)
                - userPII : MNUserPII? (as child)
                - accessToken : MNAccessToken? (as child)
         */
        guard let loginInfos : [MNUserLoginInfo] = req.getFromReqStore(key: ReqStorageKeys.loginInfos, getFromSessionIfNotFound: true), let loginInfo = loginInfos.first, let userPII = loginInfo.userPII else {
            dlog?.warning("Login succeeded but no loginInfo was saved into reqStore or sessionStore!")
            throw AppError(code: .user_login_failed_bad_credentials, reason: "User login info was not found")
        }
        
        // Execute successfult login
        // Check if already logged in or logged in as other user:
        if loginInfo.isLoggedIn == true {
            DLog.note("LOGIN    loginInfo user is already logged in!")
            // Return what ?
        }
        try await self.execSuccessfulLogin(db:req.db, req: req, user: user, pii: userPII)
        
        // TODO: Create a login/logout history record:
        
        // TODO: Create a login/logout response:
        // Assumed to be created in execSuccessfulLogin and saved into selfAccessToken.
        let accessToken = (loginInfo.accessToken ?? req.getFromReqStore(key: ReqStorageKeys.selfAccessToken))!
        let bearerTokenStr = accessToken.asBearerTokenString(forClient: true)
        let response = UserLoginResponse(bearerToken: bearerTokenStr, isNewlyRenewed: accessToken.isNewlyRenewed)
        return response
        
        //
         */
    }
}


/*
 if selfUser == nil {
     
     
     
 }
 if let abort = abort  { throw abort }
 
 // Get / create self user
 if selfUser == nil { // we can assume UserMgr.isLoginRequest(request: req) returns true for the literal route called "login".
     if let userid : String = useridParam, let uid = UserUID(uuidString: userid) {
         do {
             let user = try await UserMgr.shared.get(db: req.db, userid: uid, selfUser: nil)
             dlog?.success("found user \((user?.username).descOrNil) for id: \(userid)")
             selfUser = user
         } catch let error {
             dlog?.fail("failed finding user for id: \(userid) error:\(error.description)")
             abort = Abort(appErrorCode:.user_login_failed_user_not_found, reason: "User was not found")
         }
     } else if let username = usernameParam {
         let user = try await UserMgr.shared.get(db: req.db, username: username, selfUser: selfUser)
         dlog?.info("login(req:) by username \(username) \(user.descOrNil)")
         selfUser = user
     }
 } else {
     abort = Abort(appErrorCode:.http_stt_alreadyReported, reason: "User is already logged in")
 }
 if let abort = abort  { throw abort }
 
 guard let user = selfUser else {
     // selfUser was not assigned
     //throw Abort(.unauthorized, reason: "unauthorized caH3")
     throw Abort(appErrorCode:.user_login_failed_user_not_found, reason: "User was not found")
 }

 // Get or renew the access token from the local DB:
 do {
     let token = try await UserMgr.shared.getAccessToken(request: req, makeIfMissing:true, renewIfExpired: true, user: user)
     let newToken = BearerToken(token: token.asBearerToken(), expiration: token.expirationDate)
     if token.isValid {
         return UserLoginResponse(user: user, bearerToken: newToken)
     } else {
         throw Abort(appErrorCode:.user_login_failed_bad_credentials, reason: "User token has expired")
     }
 } catch let error as NSError {
     dlog?.warning("Failed creating access token for login attempt for [\(user.username)]")
     throw Abort(appErrorCode:.user_login_failed_bad_credentials, reason: "Failed creating access token for login attempt for [\(user.username)] underlying error: \(error.domain)|\(error.code)|\(error.reason)")
 }
}

 ...
 
 
 //            let req = UserLoginRequest(username: T##String?,
 //                                       password: T##String,
 //                                       userID: T##String?,
 //                                       remember_me: T##Int?)
 //            // Fallback:
 //            // Get params regardless of request method:
 //            let allParams = req.collatedAllParams().merging(dict: req.da)
 //            let useridParam     = req.anyParameters(fromAnAllParams:allParams, forKeys: ["userid", "id"]).first?.value
 //            let usernameParam   = req.anyParameters(fromAnAllParams:allParams, forKeys: ["email", "username", "user name", "name", "user_name"]).first?.value
 //            let pwdParam        = req.anyParameters(fromAnAllParams:allParams, forKeys: ["password", "pwd", "pass", "user_pwd", "user_password"]).first?.value
 //
 //            loginReq = UserLoginRequest(username: usernameParam, password: pwdParam)
 
 
 
 ......
 
 
 
 ....
 
 */
