//
//  UserTokenAuthenticator.swift
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

fileprivate let dlog : DSLogger? = DLog.forClass("UserTokenAuthenticator")?.setting(verbose: false)

// Do NOT add the middleware to all routes during Config!
// This middleware should only be used for the login or auth routes
/* TODO: Consider using a CSRF token in webpage views, and have a static CSRF token creation func in this middleware? needs to use the session id or similar as seed for the token, and allow various leaf webpages to incorporate the CSRF token and send it back when calling the API from in-webpage JS, or on webform submission. search for more up-to-date packages similar to: https://github.com/brokenhandsio/vapor-csrf */
class UserTokenAuthenticator : Vapor.AsyncBearerAuthenticator {
    
    func authenticate(bearer: Vapor.BearerAuthorization, for request: Vapor.Request) async throws {
        dlog?.todo("Reimplement UserTokenAuthenticator authenticate(bearer:...)")
    }
    
    public func authenticate(request: Request) async throws {
        dlog?.todo("Reimplement UserTokenAuthenticator authenticate(request:...)")
    }
    
    
    // MARK: BearerAuthenticator
    static func updateTokenCookieName()->String {
        if MNAccessToken.TOKEN_COOKIE_NAME == MNAccessToken.TOKEN_COOKIE_DEFAULT_NAME {
            MNAccessToken.TOKEN_COOKIE_NAME = "X-\(AppConstants.APP_NAME.replacingOccurrences(of: .whitespaces, with: "-"))-BTOK-Cookie"
        }
        return MNAccessToken.TOKEN_COOKIE_NAME
    }
    
    /*
    // "Override" to the AsyncBearerAuthenticator default implementtion: finds "Authorize" header OR cookie!
    public func authenticate(request: Request) async throws {
        // dlog?.info("authenticate[REPLACED](request: \(request.method) \(request.url.string))")
        return try await self.authenticate(forUnknownRequest: request)
    }

    /// Authenticate a request even if it is not in the middlware required order. this allows detectig if user is logged in even if not required
    /// - Parameter req: request to authenticate
    func authenticate(forUnknownRequest req: Vapor.Request) async throws {
        let cookieName = Self.updateTokenCookieName()
        dlog?.verbose(" [AUT] authenticate(forUnknownRequest:request) START")
        var cookieStr : String? = nil
        
        if cookieStr == nil {
            if let cookie = req.headers.cookie?[cookieName] {
                cookieStr = cookie.string
            }
        }
        
        if cookieStr == nil {
        loop: for quads in [("Cookie", ";", "=", cookieName),("Authorization"," ", " ", "Bearer")] {
                for cookie in req.headers[quads.0] {
                    let parts = cookie.components(separatedBy: quads.1)
                    for part in parts {
                        let kv = part.split(separator: quads.2, maxSplits: 1)
                        if kv[0] == cookieName, kv.count == 2, kv[1].count > 0 && kv[1].count < 256 {
                            cookieStr = String(kv[1])
                            dlog?.verbose(" [AUT] authenticate(forUnknownRequest:request) access token found in header: [\(quads.1)]")
                            break loop
                        }
                    }
                }
            }
        }

        if let cookieStr = cookieStr {
            let bearerToken = BearerAuthorization(token: cookieStr)
            dlog?.verbose(log: .success, " [AUT] authenticate(forUnknownRequest:request) access token found")
            return try await self.authenticate(bearer: bearerToken, for: req)
        } else {
            dlog?.note(" [AUT] authenticate(forUnknownRequest:request) access token not found")
        }
    }
    
    // MARK: AsyncBearerAuthenticator
    func authenticate(bearer: Vapor.BearerAuthorization, for req: Vapor.Request) async throws {
        guard bearer.token.count > 4 else {
            throw Abort(.unauthorized, reason: "malformed / short bearer token")
        }
            
        dlog?.verbose(" [AUT] authenticate(barer:for:request) START for bearer: \(bearer.token)")
        
        if bearer.token.hasSuffix(AppConstants.ACCESS_TOKEN_SUFFIX) {
            dlog?.warning(" [AUT] bearer.token has ACCESS_TOKEN_SUFFIX!! return!")
            return
        }
        
        guard let foundAccessToken = try await AppAccessToken.find(bearerToken: bearer.token, for: req) else {
            throw Abort(mnErrorCode: .http_stt_unauthorized, reason: "Access token not found")
        }
        guard let foundUser = foundAccessToken.user else {
            throw Abort(mnErrorCode: .http_stt_unauthorized, reason: "user not found".mnDebug(add: "recvdAccessToken userUIDString: \(foundAccessToken.userUIDString.descOrNil)"))
        }

        // Load required info:
        // Should have been done already JIC
        try await foundAccessToken.forceLoadAllPropsIfNeeded(vaporRequest: req)
        try await foundUser.forceLoadAllPropsIfNeeded(db: req.db)
        
        // Check user state
        guard MNModelStatus.allLoginAlowingCases.contains(foundUser.status) else {
            throw Abort(mnErrorCode: .http_stt_unauthorized, reason: "user cannnot resume session".mnDebug(add: "foundUser.status: \(foundUser.status.rawValue)"))
        }
        
        guard !foundAccessToken.isExpired else {
            throw Abort(mnErrorCode: .http_stt_unauthorized, reason: "token is expired".mnDebug(add: " token id: \(foundAccessToken.id?.uuidString ?? "<nil>") expiration date: \(foundAccessToken.expirationDate)"))
        }
        
        guard foundAccessToken.isValid else {
            throw Abort(mnErrorCode: .http_stt_unauthorized, reason: "token is curropt".mnDebug(add: " token id: \(foundAccessToken.id?.uuidString ?? "<nil>")"))
        }
        
        guard foundAccessToken.$loginInfo.id != nil else {
            throw Abort(mnErrorCode: .http_stt_unauthorized, reason: "token login info not found")
        }
        
        // Save user details:
        req.saveToReqStore(key: ReqStorageKeys.selfLoginInfoID, value: foundAccessToken.$loginInfo.id!.uuidString, alsoSaveToSession:true)
        req.saveToReqStore(key: ReqStorageKeys.selfUserID, value: foundUser.id!.uuidString, alsoSaveToSession:true)
        req.saveToReqStore(key: ReqStorageKeys.selfUser, value: foundUser, alsoSaveToSession:true)
        req.saveToReqStore(key: ReqStorageKeys.selfAccessToken, value: foundAccessToken, alsoSaveToSession:true)
        req.auth.login(foundUser) // save in session
        
        // Save info:
        foundAccessToken.setWasUsedNow(isSaveOnDB: req.db, now: nil) // set last updated date.
        
        dlog?.success("authenticate(bearer:) AT ID: \(foundAccessToken.id.descOrNil) user: \(foundUser.displayName)")
    }
*/
}
