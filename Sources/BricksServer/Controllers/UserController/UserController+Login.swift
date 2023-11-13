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
    
    // MARK: Reqauesr
    fileprivate struct UserLoginRequest : Content, JSONSerializable { // todo: , UserLoginable
        static let USER_DOMAIN_EMPTY = ""
        static let USER_DOMAIN_DEFAULT = AppServer.DEFAULT_DOMAIN
        
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
        
        init(username:String, userPassword:String, userDomain: String? = nil, rememberMe:RememberMeType = .forgetMe, usernameType:MNUserPIIType? = nil) {
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
        
        static var empty : UserLoginRequest {
            return UserLoginRequest(username: "", userPassword: "", userDomain: Self.USER_DOMAIN_EMPTY)
        }
        
        var isEmpty : Bool {
            return username == "" && 
                userPassword == "" &&
                userDomain == Self.USER_DOMAIN_EMPTY
        }
        
        func asPiiInfo() throws -> MNPIIInfo? {
            
            // TODO Sanitizae and guard Guard user name and pwd input guard username.count > MIN_USER
            let hashedPwd = try UserPasswordAuthenticator.digestPwdPlainText(plainText: userPassword)
            return MNPIIInfo(piiType: usernameType,
                             strValue: username, // any str field for the username, may be email or any other unique user identifier that is not a scret, known to the user
                             domain: userDomain,
                             hashedPwd: hashedPwd)
        }
        
        init(from decoder: Decoder) throws {
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
                    case "true", "yes":
                        self.rememberMe = .rememberMe
                    case "false":
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
    }
    
    // MARK: Resposne
    struct UserLoginResponse : AppEncodableVaporResponse {
        let user : AppUser
        let bearerToken : BearerToken
        var isNewlyRenewed : Bool {
            return abs(bearerToken.createdDate.timeIntervalSinceNow) < UserController.accessTokenRecentlyRenewedTimeInterval
        }
    }
    
    // MARK: fileprivate util functions
    fileprivate func getSelfUser(req: Request) async throws->AppUser? {
        try await UserTokenAuthenticator().authenticate(request: req)
        if let selfUser = req.selfUser { // getSelfUser(isTryDeepQuery:true) {
            return selfUser
        }
        dlog?.warning("TODO: Remimplement getSelfUser(req:)")
        return nil
    }
    
    // MARK: actual request/s
    /// Login a user to the system
    /// - Parameter req  login reuqest content
    /// - Returns: UserLoginResponse containing the User structure and the bearerToken
    func login(req: Request) async throws -> UserLoginResponse {

        // https://stackoverflow.com/questions/3391242/should-i-hash-the-password-before-sending-it-to-the-server-side
        // TL;DR: NO, the client should never hash the pwd!
        // UserLoginRequest is validatable
        guard let appServer = req.application.appServer, appServer.isBooting == false else {
            throw AppError(code: .http_stt_expectationFailed, reason: "Server not online")
        }
        
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
            
        guard let pii = try loginReq.asPiiInfo() else {
            throw AppError(code: .user_login_failed_bad_credentials, reason: "Bad credientials: User identifying info not found.")
        }
        
        // Find user and permission:
        let permissionGiver : AppPermissionGiver = req.selfUser ?? appServer.defaultPersmissionGiver
        let users = try await self.dbFindUsers(db: req.db, pii: pii, permissionGiver: permissionGiver)
        guard let user = users.first else {
            throw AppError(code: .user_login_failed_user_not_found, reason: "User was not found")
        }
        
        // Load all relevant sub-components:
        try await user.forceLoadAllPropsIfNeeded(db: req.db)

        // Save pii and user info into req storage:
        req.saveToReqStore(key: ReqStorageKeys.user.self, value: user)
        //req.saveToReqStore(key: ReqStorageKeys.loginInfos.self, value: loginInfos)
        let passAuthenticator = req.application.middleware.getMiddleware(ofType: UserPasswordAuthenticator.self) ?? UserPasswordAuthenticator()
        let basicAuthorization = BasicAuthorization(username: pii.strValue, password: loginReq.userPassword)
        
        // Authenticate using Vapor mechanisms:
        try await passAuthenticator.authenticate(basic: basicAuthorization, for: req)
        
        // TODO: Check if already logged in or logged in as other user:
            // Return what ?
            
        // Authenticate user?
        
        
//        let selfUser = req.getSelfUser(isTryDeepQuery: true)
//        let token = req.getAccessToken(context: "/user/login")
//        
//        if let selfUser = selfUser, let token = token, token.expirationDate.isInTheFuture {
//            if selfUser.id != user.id {
//                // Logout other usr from this session
//                dlog?.warning("Logging out (from the sessin) the other user: \(selfUser.description)")
//                req.saveToSessionStore(selfUser: user, selfAccessToken: token)
//            } else {
//                // Check if the existing self user only needs a new token (old token has expired?).
//                if token.isExpired {
//                    // Renew acces token / make new:
//                    
//                } else {
//                    throw Abort(appErrorCode: .http_stt_alreadyReported,
//                                reason: "User already logged in." +  Debug.StringOrEmpty("token expires on: \(token.expirationDate.formatted()))"))
//                }
//            }
//        }
//        
//        // Login requst start:
//        dlog?.info("login: \(loginReq)")
        throw AppError(code: .user_login_failed_bad_credentials, reason: "User login failed: bad credientials (unk)")
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
