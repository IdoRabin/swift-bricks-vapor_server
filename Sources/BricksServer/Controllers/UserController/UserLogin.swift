//
//  UserLogin.swift
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

fileprivate let dlog : DSLogger? = DLog.forClass("UserLogin")
extension UserController {
    
    // MARK: Reqauesr
    fileprivate struct UserLoginRequest : Content, JSONSerializable { // todo: , UserLoginable
        let username : String
        let userPassword : String
        let userDomain : String
        let remember_me : Int?
        var usernameType: MNUserPIIType
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
//        try await UserTokenAuthenticator().authenticate(request: req).get()
//        if let selfUser = req.selfUser { // getSelfUser(isTryDeepQuery:true) {
//            return selfUser
//        }
        dlog?.warning("TODO: Remimplement getSelfUser(req:)")
        return nil
    }
    
    // MARK: actual request/s
    /// Login a user to the system
    /// - Parameter req  login reuqest content
    /// - Returns: UserLoginResponse containing the User structure and the bearerToken
    func login(req: Request) async throws -> UserLoginResponse {
        throw Abort(.internalServerError, reason: "Unknown error has occured")
        
//        // https://stackoverflow.com/questions/3391242/should-i-hash-the-password-before-sending-it-to-the-server-side
//        // TL;DR: NO, the client should never hash the pwd!
//        // UserLoginRequest is validatable
//        let loginReq = try req.content.decode(UserLoginRequest.self)
//        guard let user = try await UserMgr.shared.get(db: req.db, username: loginReq.username, selfUser: nil) else {
//            throw AppError(code: .user_login_failed_user_not_found,
//                           reason: "User was not found")
//        }
//        
//        // Check if already logged in or logged in as other user:
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
