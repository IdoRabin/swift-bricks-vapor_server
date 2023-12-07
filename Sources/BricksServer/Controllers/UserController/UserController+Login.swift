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
        
        // NOTE: the consumers of this method expect loggedInInfo.accessToken AND req.getFromReqStore(key: ReqStorageKeys.selfAccessToken)
        // to be up-to date and relationally-linked correctly after this function is done
        
        // Load loginInfo if needed
        if pii.$loginInfo.value == nil {
            _ = try await pii.$loginInfo.get(on: db)
        }
        
        let loginInfo = pii.loginInfo
        
        // Load if needed
        if loginInfo.$accessToken.value == nil {
            _ = try await loginInfo.$accessToken.get(on: db)
        }
        
        // Create / Use existing accessToken: // First encounter with access token.
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
        
        // Renew expired token
        if let existingLoginToken = loginToken, existingLoginToken.isExpired {
            dlog?.note("LOGIN    Old token has expired: \(existingLoginToken.expirationDate.debugDescription)")
            let isShouldRenew = true // TODO: RRabac & permissions to renew access token
            if isShouldRenew && user.status == .active {
                // todo: Make SURE DELETION does not require some detaching...
                // DO NOT: loginInfo.$accessToken.wrappedValue = nil
                // DO NOT: loginToken.detach()
                try await loginToken?.delete(on: db) // soft delete
                loginToken = nil
            }
        }
         
        if loginToken == nil {
            // Create new access token
            let newToken = MNAccessToken(loginInfo: loginInfo)
            newToken.$user.id = user.id
            DLog.note("LOGIN    New access token created: \(newToken) (none found)!")
            loginToken = newToken
        }

        // Save lastUsed dates etc
        let now = Date.now
        loginToken?.setWasUsedNow(isSaveOnDB: nil, now: now)
        loginInfo.setLoggedIn(true, now: now)
        // TODO: req?.routeContext?.isLoggedIn = true
        // TODO: Create a login/logout history record.
        
        // Save to request / session:
        if let req = req {
            // DO NOT: req .auth .login(user)  - this is to be called in the various authenitation Middlewares.
            req.saveToReqStore(key: ReqStorageKeys.selfUser, value: user, alsoSaveToSession: true)
            req.saveToReqStore(key: ReqStorageKeys.selfUserID, value: user.id!.uuidString, alsoSaveToSession: true)
            
            // Note: loginToken may have been replaced!
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
    /// - Returns: a Response, encoding a UserLoginResponse and settings a cookie in the header
    func login(req: Request) async throws -> Response {
        /* for reference:
            MNUser
             - personInfo : MNPersonInfo? (as child)
                - name : MNPersonName? (as field)
             - loginInfos : [MNUserLoginInfo]  (as children)
                - userPII : MNUserPII? (as child)
                - accessToken : MNAccessToken? (as child)
         */
        
        // Assumes req.auth.login(user) was called in UserPasswordAuthenticator or otherwise
        guard let appServer = req.application.appServer, appServer.isBooting == false else {
            throw AppError(code: .http_stt_expectationFailed, reason: "Server not online")
        }
        
        // Get the user we are trying to login using the pii info or session:
        let user : MNUser = try req.auth.require(MNUser.self)
        
        // Load all relevant sub-components for user:
        try await user.forceLoadAllPropsIfNeeded(db: req.db)
        
        // Check if user status allows login: (state for user)
        guard MNModelStatus.allLoginAlowingCases.contains(user.status) else {
            let isUnknown = user.status == .unknown
            let reason = isUnknown ? "unknown permissions" : "revoked permissions"
            let code : MNErrorCode = isUnknown ? .user_login_failed_no_permission : .user_login_failed_permissions_revoked
            throw AppError(code: code, reason: "User login failed: \(reason)")
        }
        
        dlog?.success("login SUCCESS \(user)")
        
        var loginRequset : UserLoginRequest? = req.getFromReqStore(key: ReqStorageKeys.loginRequest)
        if loginRequset == nil, let basic = req.headers.basicAuthorization {
            loginRequset = UserLoginRequest(basicAuth: basic, domain: req.domain ?? AppServer.DEFAULT_DOMAIN)
        }
        guard let loginReq = loginRequset else {
            throw AppError(code: .user_login_failed_name_and_password, reason: "User login failed: bad credientials (unknown)")
        }
        
        // Assumes req.getFromReqStore
        // req.saveToReqStore(key: ReqStorageKeys.loginInfos was executed
        // NOTE: assumes UserPasswordAuthenticator saved loginInfos where the first value is the value that matches the login request's PII:
        // NOTE: No need to use loginReq.asPiiInfo(), since it is assume to have been done in the UserPasswordAuthenticator and saved to using saveToReqStore(...)
        guard let loginInfos : [MNUserLoginInfo] = req.getFromReqStore(key: ReqStorageKeys.loginInfos),
                let loggedInInfo = loginInfos.first,
              let loggedInUserPII = loggedInInfo.userPII else {
            throw AppError(code: .user_login_failed_bad_credentials, reason: "User login failed: User identifying info not found")
        }
        
        // Make sure domain is correct and equals the current domain in the request and for the found loginInfo / PII:
        let reqDomain = MNDomains.sanitizeDomain(req.domain)
        
        if loginReq.userDomain == UserLoginRequest.USER_DOMAIN_EMPTY {
            throw AppError(code: .user_login_failed_bad_credentials, reason: "Bad credientials: domain access issue.")
        } else if loginReq.userDomain != reqDomain ||
                  loginReq.userDomain != loggedInUserPII.piiDomain
        {
            var msg = "Bad credientials: Domain incompatible issue."
            if Debug.IS_DEBUG {
                msg += " \(loginReq.userDomain) != \(loggedInUserPII.piiDomain) != \(reqDomain)"
            }
            throw AppError(code: .user_login_failed_bad_credentials, reason: msg)
        }
        
        // Find best permission giver for this action / request path: (RABAC?)
        // let permissionGiver : (any AppPermissionGiver)? = user // ?? req.selfUser ?? appServer.defaultPersmissionGiver
        // TODO: Complete permission to login // RRABAC
        
        
        // Check if already logged in or logged in as other user:
        if loggedInInfo.isLoggedIn == true {
            DLog.note("LOGIN    loginInfo user [\(user.displayName)] was already logged in!")
            // Return what ?
        }
        
        // Execute successful login
        // Save pii and user info into req storage, save to db etc.
        // Will also renew / replace accessToken to a valid, non-expired token
        try await self.execSuccessfulLogin(db:req.db, req: req, user: user, pii: loggedInUserPII)
        
        // Assumed to be created in execSuccessfulLogin and saved into selfAccessToken.
        let accessToken : MNAccessToken = (loggedInInfo.accessToken ?? req.getFromReqStore(key: ReqStorageKeys.selfAccessToken))!
        if accessToken.isExpired {
            dlog?.note("LOGIN    current access token has expired! \(accessToken.expirationDate.debugDescription) at: \(accessToken.expirationDate.timeIntervalSinceNow.asDDHHMMStr.descOrNil)")
            
        }
        if !accessToken.isValid {
            dlog?.note("LOGIN    current access token is not valid! at id:\(accessToken.id.descOrNil)")
        }
        
        let bearerToken = accessToken.asBearerTokenString(extraInfo: true)
        let isClientReditect = req.url.path.contains(anyOf: [DashboardController.BASE_PATH.description], isCaseSensitive: false)
        
        // Make response
        let userLoginResponse = UserLoginResponse(user: user, bearerToken: bearerToken, isNewlyRenewed: accessToken.isNewlyRenewed, isClientReditect: isClientReditect)
        let response = try await userLoginResponse.encodeResponse(for: req)
        
        // Set cookie in the headers
        let cookieName = UserTokenAuthenticator.updateTokenCookieName()
        let tokenRemainingDuration : Int  = Int(abs(accessToken.validDuration ?? accessToken.expirationDate.timeIntervalSinceNow))
        let cookie = HTTPCookies.Value(string: bearerToken,
                                       expires: accessToken.expirationDate,
                                       maxAge: Int(abs(tokenRemainingDuration)), // the time in seconds
                                       domain: req.application.http.server.configuration.hostname,
                                       isSecure: false, // TODO: Detect if TLS settings of server are active and set secure to true
                                       isHTTPOnly: !Debug.IS_DEBUG,
                                       sameSite: .lax) // HTTPCookies.SameSitePolicy.strict
        // Note this is the bearer token cookie name, not the session cookie
        response.cookies[cookieName] = cookie
        // TODO: Detect TLS settings of server: cookie isSecure:true will make the client send the cookie only when calling HTTPS and not when calling HTTP..
        
        // Return
        return response
    }
}
