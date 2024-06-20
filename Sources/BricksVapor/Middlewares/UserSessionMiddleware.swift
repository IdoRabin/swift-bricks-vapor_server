//
//  UserSessionMiddleware.swift
//
//
//  Created by Ido on 18/01/2024.
//

import Foundation
import Vapor
import MNUtils
import MNVaporUtils
import Fluent
import Logging

fileprivate let dlog : Logger? = Logger(label:"UserSessionMiddleware")

/// Does not follow session, but the User session - i.e uses the cookies to elevate and save user / accessToken into the req / session cache
/// Acts as BearerAuthenticator but with a looser
class UserSessionMiddleware : Vapor.AsyncMiddleware {
    
    // Path component strings which dictate skipping detecting the user session etc.
    public static let SKIP_PATH_COMPONENTS : [String] = ["logout", "options_check"]
    
    func checkForSession(req: Vapor.Request) async throws {
        let isLog = Debug.IS_DEBUG && false
        let isThrows = req.route?.mnRouteInfo?.requiredAuth.contains(.userToken) ?? false
        do {
            // 1. Check the auth in the request cache:
            var user : User? = req.auth.get(User.self)
            var accessToken : AccessToken? = req.auth.get(AccessToken.self)
            var debugStrs : [String]? = isLog ? [] : nil
            var userSession : UserSession? = req.getFromSessionStore(key: ReqStorageKeys.userSession)
            if user != nil && accessToken != nil && accessToken?.user.id == user?.id && userSession == nil {
                _ = try await accessToken?.$user.get(reload: false, on: req.db)
                
                // Save to session store:
                userSession = UserSession(token: accessToken!, req: req, source: .tokenRefresh)
                req.saveToSessionStore(key: ReqStorageKeys.userSession, value: userSession!)
            }
            
            // Search for user session in the session storage (assuming user sends bearer cookie from sessionFactory)
            if req.hasSession, let auserSession = userSession,
               auserSession.accessToken.$user.id != user?.id {
                user = try await auserSession.accessToken.$user.get(reload: false, on: req.db)
                accessToken = auserSession.accessToken
                debugStrs?.append("session")
                
                userSession = auserSession
                
                // Save to route cache:
                req.auth.login(user!)
                req.auth.login(accessToken!)
                
            } else if let anAccessToken = await AccessToken(fromRequestBTOKCookie: req) {
                
                // 2. User session is not in the session storage - use BTOK Cookie
                accessToken = anAccessToken
                user = anAccessToken.user
                
                // Save to route cache:
                req.auth.login(user!)
                req.auth.login(accessToken!)
                
                // Save to session store:
                userSession = UserSession(token: anAccessToken, req: req, source: .tokenRefresh)
                req.saveToSessionStore(key: ReqStorageKeys.userSession, value: userSession!)
            }
        } catch let error {
            if isThrows {
                throw error
            } else {
                dlog?.info(".userToken not required for this route: error will not throw: \(error.description)")
            }
        }
    }
    
    func respond(to req: Vapor.Request, chainingTo next: Vapor.AsyncResponder) async throws -> Vapor.Response {
        
        // Cases where we do NOT process the request and recover / create session:
        let skip = req.url.url.pathComponents.lowercased.contains(anyOf: Self.SKIP_PATH_COMPONENTS)
        
        if !skip {
            // Logout - we do not check for token etc.
            try await self.checkForSession(req: req)
        } else {
            dlog?.note("\(req.method) \(req.url.string) skipping UserSessionMiddleware")
        }
        
        return try await next.respond(to: req)
    }
    
    init(allowedRoles:[Any]? = nil) {
        dlog?.info("init \(allowedRoles?.descriptionJoined ?? "[]")")
    }
}
