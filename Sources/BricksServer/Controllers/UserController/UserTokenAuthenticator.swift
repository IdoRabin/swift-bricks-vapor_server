//
//  UserTokenAuthenticator.swift
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

fileprivate let dlog : DSLogger? = DLog.forClass("UserTokenAuthenticator")

// Do NOT add the middleware to all routes during Config!
// This middleware should only be used for the login or auth routes

class UserTokenAuthenticator : Vapor.AsyncBearerAuthenticator {
    
    // MARK: helper functions
    private func checkRecievedTokenAndGetUser(bearer: BearerAuthorization, for req: Request) async throws -> AppUser {
        throw AppError(code:.misc_failed_validation, reason: "Failed validating access token. (Not implemented)")
    }
    
    // MARK: BearerAuthenticator
    func authenticate(bearer: Vapor.BearerAuthorization, for req: Vapor.Request) async throws {
        guard bearer.token.count > 4 else {
            throw Abort(.unauthorized, reason: "malformed / short bearer token")
        }
            
        dlog?.info(" [AUT] authenticate(barer:for:request) start")
        
        if bearer.token.hasSuffix(AppConstants.ACCESS_TOKEN_SUFFIX) {
            // Legacy: return req.eventLoop.makeSucceededFuture(())
            // TODO: Why?
            return
        }
        
        let user = try await self.checkRecievedTokenAndGetUser(bearer: bearer, for: req)
        
//        case .success(let user):
//            dlog?.info(" [AUT]     WILL checkUserAndValidateSavedToken")
//            let userResult = self.checkUserAndValidateSavedToken(user:user, for: req)
//                .flatMap { res in
//                //dlog?.info(" [AUT]     DID checkUserAndValidateSavedToken res:\(res)")
//                switch res {
//                case .failure(let err):
//                    dlog?.fail(   " [AUT]     DID makeFailedFuture --0")
//                    return req.eventLoop.makeFailedFuture(err)
//                case .success:
//                    //dlog?.success(" [AUT]     DID makeSucceededVoidFuture!")
//                    return req.eventLoop.makeSucceededVoidFuture()
//                }
//            }
//        case .failure(let error):
//            dlog?.info(" [AUT]     WILL checkUserAndValidateSavedToken")
//            throw error
//        }
    }
    
}
/*
    private func checkRecievedTokenAndGetUser(bearer: BearerAuthorization, for req: Request) async throws->MNResult<AppUser> {

        let isAllowsExpiredToken = (req.storage[ReqStorageKeys.userTokenCreateIfExpired] == true)
        
        var recvdAccessToken : MNAccessToken
        
        do {
            recvdAccessToken = try MNAccessToken(bearerToken:bearer.token,
                                                 allowExpired: true) // isAllowsExpiredToken bool flag is checked in the following blocks, so no need fotr the init to raise an exception
        } catch let error {
            dlog?.note("Access token EXPIRED: creating an accessToken failed with error: \(error.description) isAllowsExpiredToken:\(isAllowsExpiredToken)")
        }
        
        let willMakeNewToken = (req.storage[ReqStorageKeys.userTokenMakeIfMissing] == true) && (bearer.token == "")

        let willRenewToken =  isAllowsExpiredToken &&
                              recvdAccessToken.isExpired
        
        if willMakeNewToken || willRenewToken {
            dlog?.info("Access token expired/missing, but request allows recreation")
        } else if !recvdAccessToken.isEmpty || !recvdAccessToken.isValid {
            
        } else if recvdAccessToken.isExpired && !isAllowsExpiredToken  {
            var reason = "Cannot execute: [\(req.url.path)]. Access token expired [UA]"
            if Debug.IS_DEBUG {
                reason += " \(recvdAccessToken.description)"
            }
            throw Abort(.unauthorized, reason: reason)
        }

        let promise = req.eventLoop.makePromise(of: Result<AppUser, Error>.self)
        
        // recvdAccessToken.user.load(on: req.db).whenComplete { res in
//            if let user = recvdAccessToken.$user.value, res.isSuccess {
//
//                // Store in request until we return a response:
//                req.saveToSessionStore(selfUser: user, selfAccessToken: recvdAccessToken)
//                recvdAccessToken.wasUsedNow() // set last updated date.
//                promise.succeed(.success(user))
//            } else { // res.isFailure
//                dlog?.note("checkRecievedTokenAndGetUser user was not found for id:\(recvdAccessToken.$user.$id.queryableValue().descOrNil)")
//                req.saveToSessionStore(selfUser: nil, selfAccessToken: nil)
                
                // Fallback tries to get user by id or name from params
//                promise.completeWithTask {[recvdAccessToken] in
//                    // Eithr throw or assumes completed successfullt
//                    var user : User? = nil
//                    if let userid = req.anyParameters(forKeys: ["userid"]).first?.value, let uid = UserUID(uuidString: userid) {
//                        user = try await UserMgr.shared.get(db: req.db, userid: uid, selfUser: nil)
//                        dlog?.successOrFail(condition: user != nil, "finding user by id from param 'userid'")
//                    }
//
//                    if user == nil, let username = req.anyParameters(forKeys: ["username"]).first?.value {
//                        user = try await UserMgr.shared.get(db: req.db, username: username, selfUser: nil)
//                        dlog?.successOrFail(condition: user != nil, "finding user by user name from param 'username'")
//                    }
//
//                    if let user = user {
//                        req.saveToSessionStore(selfUser: user, selfAccessToken: recvdAccessToken)
//                        promise.succeed(.success(user))
//                        do {
//                            try await recvdAccessToken.save(on: req.db).get()
//                        } catch (let error) {
//                            throw error
//                        }
//                        return .success(user)
//                    } else {
//                        switch res {
//                        case .success:
//                            // UsrId stored inside the recvdAccessToken (bearerToken) is wrong or missing
//                            throw Abort(.unauthorized, reason: "no such user or provided access token points to unknown / deleted user. Or access token revoked.")
//                        case .failure(let err):
//                            throw err
//                        }
//                    }
//                }
//            }
//        }
        
        return .failure(code: .db_failed_query, reason:"Failed validating access token. TODO: Implement checkRecievedTokenAndGetUser..")
    }
    */
/*
    private func checkUserAndValidateSavedToken(user:AppUser, for req: Request) async ->AppResult<MNAccessToken> {
        guard let uuid : UUID = user.$id.value else {
            // user loaded without a uuid
            let msg = "failed user - loaded without a uuid!"
            return .failure(code: .db_failed_load, reason: msg,
                            underlyingError: Abort(.unauthorized, reason: msg))
        }

//        let result = MNAccessToken.query(on: req.db).filter(\.$user.$id == uuid).first()
//        return result.flatMapThrowing { accessToken in
//            if let accessToken = accessToken {
//                // Validare the saved access token:
//                return .success(accessToken.isExpired == false)
//            } else {
//                throw Abort(.unauthorized, reason: "the given access token's user is unknown")
//            }
//        }
    }
    */

/*
    func authenticate(bearer: BearerAuthorization, for req: Request) -> EventLoopFuture<Void> {
        
        // "/users/8A557844-6339-4CDF-89C2-4D354334B57D"
//        let loginEx = UserMgr.shared.isRequestMakesToken(request: req)
//        UserMgr.shared.updateStorageForMakingToken(request: req,
//                                                   makeIfMissing: loginEx.makeIfMissing,
//                                                   renewIfExpired: loginEx.renewIfExpired)
//
//        // dlog?.info(" [AUT] authenticate(barer:for:request) start")
//
//        guard bearer.token.count > 4 else {
//            return req.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "malformed / short bearer token"))
//        }
//
//        if bearer.token.hasSuffix(AppConstants.ACCESS_TOKEN_SUFFIX) {
//            return req.eventLoop.makeSucceededFuture(())
//        }
//        do {
//            //dlog?.info(" [AUT] WILL checkRecievedTokenAndGetUser")
//            let getUsr = try self.checkRecievedTokenAndGetUser(bearer: bearer, for: req)
//            return getUsr.futureResult.flatMap({ result in
//                //dlog?.info(" [AUT] DID checkRecievedTokenAndGetUser result: \(result)")
//                switch result {
//                case .success(let user):
//                    //dlog?.info(" [AUT]     WILL checkUserAndValidateSavedToken")
//                    return self.checkUserAndValidateSavedToken(user:user, for: req).flatMap { res in
//                        //dlog?.info(" [AUT]     DID checkUserAndValidateSavedToken res:\(res)")
//                        switch res {
//                        case .failure(let err):
//                            dlog?.fail(   " [AUT]     DID makeFailedFuture --0")
//                            return req.eventLoop.makeFailedFuture(err)
//                        case .success:
//                            //dlog?.success(" [AUT]     DID makeSucceededVoidFuture!")
//                            return req.eventLoop.makeSucceededVoidFuture()
//                        }
//                    }
//                case .failure(let err):
//                    dlog?.fail(   " [AUT]   DID makeFailedFuture --1")
//                    return req.eventLoop.makeFailedFuture(err)
//                }
//            })
//        } catch let err {
//            dlog?.fail(   " [AUT]   DID makeFailedFuture --2: \(err.description)")
//            return req.eventLoop.makeFailedFuture(err)
//        }
    }
    
}
*/
