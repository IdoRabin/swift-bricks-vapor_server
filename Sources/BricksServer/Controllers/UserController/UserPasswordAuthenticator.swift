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

//class UserPasswordAuthenticator : Vapor.BasicAuthenticator {
class UserPasswordAuthenticator : Vapor.BasicAuthenticator {
    static let PWD_HASHING_COST = 12
    
    static func digestPwdPlainText(plainText:String) throws ->String {
        return try BCryptDigest().hash(plainText, cost: Self.PWD_HASHING_COST)
    }
    
    // Authenticate that the username and password are in the DB and valid:
    func authenticate(basic: BasicAuthorization, for req: Request) -> EventLoopFuture<Void> {
        let inputUsernameStr = basic.username
        let domain = req.domain ?? AppServer.DEFAULT_DOMAIN
        var anError : MNError? = nil
        do {
//            let inputHashedPwd = try Self.digestPwdPlainText(plainText:basic.password)
//
//            // Find PIIs with this given username:
//            let piisFutures = MNUserPII.query(on: req.db).filter(\.$piiValue ~= inputUsernameStr).top(5)
//            let res = piisFutures.flatMapResult({ piis in
//                var result : Result<AppUser, MNError> = .failure(MNError(code:.user_login_failed_user_name, reason: "The user for the login credentials ware unknown"))
//                var xError : MNError? = nil
//                let count = piis.count
//                switch count {
//                case 0:
//                    xError = MNError(code:.user_login_failed_user_name, reason: "The provided login credentials were not found")
//                case 1:
//                    let pii = piis.first!
//
//                    // User the first PII to get the user:
//                    if let user = pii.loginInfo.user {
//                        dlog?.verbose("[AUT] found pii: \(pii) and user: \(user)")
//                        result = .success(user)
//                    } else {
//                        xError = MNError(code:.user_login_failed_user_name, reason: "The user for the login credentials was not found")
//                    }
//                case 2..<Int.max:
//                    fallthrough
//                default:
//                    let msg = "[AUT] found multiple (\(count)) PIIS for login string: \(basic)"
//                    dlog?.note(msg)
//                    xError = MNError(code:.user_login_failed_user_name, reason: msg)
//                }
//
//                if let err = xError {
//                    result = .failure(err)
//                }
//                return result
//            })
        } catch let error {
            dlog?.warning("authenticate(basic:) failed on BCryptDigest().hash(:cost:) error: \(error)")
            anError = MNError(fromError: error, defaultErrorCode: .user_login_failed_name_and_password, reason: "Login credentials exception.")
        }
        
        // In case no user was found
        if let error = anError {
            return req.eventLoop.makeFailedFuture(error)
        }
        return req.eventLoop.makeFailedFuture(MNError(code:.user_login_failed_user_name, reason: "The user for the login credentials was unknown: \(basic)"))
        
        /*
        req.logger.info("authenticate(basic: req: \(req.url.string) username:\(inputUsernameStr) pass:\(basic.password)")
        let users =
//        let users : [AppUser] = AppUser.query(on: req.db)
//            .filter(\.$domain == AppServer.DEFAULT_DOMAIN)
//            .range(..<2) // .top(1)
//            .all().flatMap { users in
//
//            }
        
        
        let result : EventLoopFuture<Void> = queryFuture.map { user in
            let res : EventLoopFuture<Void>!
            if let user = user {
                do {
                    if try user.verify(password: basic.password) {
                        res = req.eventLoop.makeSucceededFuture(())
                        req.auth.login(user)
                    } else {
                        res = req.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "not authorized"))
                    }
                } catch let error {
                    req.logger.notice("Failed password verifying user \(basic.username) error: \(error.localizedDescription)")
                    res = req.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "authorization failed"))
                }
            } else {
                res = req.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "authorization failed : no such user"))
            }
            
            res.whenComplete { res in
                switch res {
                case .failure(let error):
                    dlog?.warning("failed password verifying user: \(basic.username) error:\(error.localizedDescription)")
                default:
                    break
                }
            }
        }
        */
//        return result // req.eventLoop.makeFailedFuture(Abort(.unauthorized))
    }
    
}
