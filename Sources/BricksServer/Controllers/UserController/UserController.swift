//
//  UserController.swift
//  
//
//  Created by Ido on 16/07/2022.
//
import Foundation
import Vapor
import Fluent
import FluentKit
import DSLogger
import MNSettings
import MNUtils
import MNVaporUtils

fileprivate let dlog : DSLogger? = DLog.forClass("UserController")


/// Keys for data stored in the User of Requests:
struct UserTokenMakeIfMissingKey : /*Vapor.Utilities.*/ReqStorageKey {
    typealias Value = Bool
}
/// Keys for data stored in the User of Requests:
struct UserTokenCreateIfExpiredKey : /*Vapor.Utilities.*/ReqStorageKey  {
    typealias Value = Bool
}

/// Keys for data stored in Request.storage or Request.session.storage:
struct UserStorageKey : ReqStorageKey {
    public typealias Value = AppUser
}

struct SelfUserStorageKey : ReqStorageKey {
    public typealias Value = AppUser
}

struct SelfUserIDStorageKey : ReqStorageKey {
    public typealias Value = String
}

struct AccessTokenStorageKey : ReqStorageKey {
    public typealias Value = MNAccessToken
}

struct SelfAccessTokenStorageKey : ReqStorageKey {
    public typealias Value = MNAccessToken
}


// Controller for managing users and their login states:
class UserController: AppRoutingController {
    
    @AppSettable(key:"UserController.accessTokenRecentlyRenewedTimeInterval", default: AppConstants.ACCESS_TOKEN_RECENT_TIMEINTERVAL_THRESHOLD) static var accessTokenRecentlyRenewedTimeInterval : TimeInterval
    @AppSettable(key:"UserController.accessTokenExpirationDuration", default: AppConstants.ACCESS_TOKEN_EXPIRATION_DURATION) static var accessTokenExpirationDuration : TimeInterval
    
    // let basePath = RoutingKit.PathComponent(stringLiteral: "user")
    
    // Semantically should be IsUserLoggedInResponse, but for order purposed (all user funcs start with User..)
    struct UserIsLoggedInResponse : AppEncodableVaporResponse {
        let status : HTTPStatus
        let notes : String
        
        // Any params you wish about the user
        let userInfo : [String:String]?
        
        var httpStatusOverride: HTTPStatus {
            return status
        }
    }
    
    struct UserLogoutResponse : AppEncodableVaporResponse {
        let user :AppUser
        let sessionStarted : Date?
    }
    
    struct UserCreateResponse : AppEncodableVaporResponse {
        let user : AppUser
    }
    
    // MARK: private
    func application(routes: RoutesBuilder)->Vapor.Application? {
        return (routes as? Application) ?? AppServer.shared.vaporApplication
    }
    
    // MARK: Public Static
    static func exctractUID(urlStr:String)->UUID? {
        // https://www.hackingwithswift.com/swift/5.7/regexes
        /* ...In comparison, using regex literals allows Swift to check your regex at compile time: it can validate the regex contains no errors, and also understand exactly what matches it will contain.
         print(message.ranges(of: /[a-z]at/))
         print(message.replacing(/[a-m]at/, with: "dog"))
         print(message.trimmingPrefix(/The/.ignoresCase()))
         */
        
        // Sample: http:/ /www.mysite/user/123e4567-e89b-12d3-a456-426614174000/xx?eq=111222333&vc=23423-23423
        // let regex = /\/user\/([\dA-Fa-f-_.]{0,64}+)\/
        let matches = urlStr.matches(for: "\\/user\\/([\\dA-Fa-f-_.]{0,64}+)\\/", options: .caseInsensitive)
        if matches.count > 0 {
            dlog?.todo("check if selfuserid: \(matches.description)")
            if let uuidStr = matches.first?.trimmingPrefix("/user/").trimming(string: "/"), let auid = UUID(uuidString: uuidStr) {
                return auid
            }
        }
        
        return nil
    }
    
    // MARK: MNRoutingController overrides
    // REQUIRED OVERRIDE for MNRoutingController
    override var basePaths : [[RoutingKit.PathComponent]] {
        // NOTE: var basePath is derived from basePaths.first
        
        // Each string should descrive a full path
        return RoutingKit.PathComponent.arrays(fromPathStrings: ["user"])
    }
    
    // MARK: Controller API:
    // Controller methods should always accept a Request and return something ResponseEncodable
    override func boot(routes: RoutesBuilder) throws {
        let noProtGroupInfo = AppRouteInfo()
        
        // Listed below are all the routing groups:
        let groupName = basePath.string
        
        //  = = = = Login routing group  = = = =
        // See file: UserController+Login
        routes.group(UserPasswordAuthenticator(allowedRoles:[]),
                     AppUser.guardMiddleware() // guards against unautorized users: assuming User implements Vapor.Authenticatable
        ) { rprotected in
            // "Create" does not require id because the user being crated has no id (YET):
            rprotected.on(.POST, basePath.appending(strComp: "login"), use: login).setting(
                productType: .apiResponse,
                title: "login user",
                description: "Login a user. Requires user login credentials and permissions.",
                requiredAuth:.userPassword,
                group: groupName)
        }
        
        // = = = = User/s protected root commands = = = =
        routes.group(UserTokenAuthenticator(),
                     AppUser.guardMiddleware() // guards against unautorized users: assuming User implements Vapor.Authenticatable
        ) { rprotected in
            // "Create" does not require id because the user being crated has no id (YET):
            rprotected.on([.POST], basePath.appending(strComp: "create"), use: createUser)?.setting(
                productType: .apiResponse,
                title: "create user",
                description: "Create a new user of the client app. Requires user creation credentials and permissions. New user should not have an existing username. A uuid passed for the new user is ignored and the uuid is created by the server only.",
                requiredAuth:.bearerToken,
                group: groupName)
        }
        
        // = = = = User/s protected routing group = = = =
        // Requires calling client to supplie a valid accessToken / bearerToken (?)
        routes.group(basePath.appending(strComp: ":id")) { usersRoutes in
            
            // === No protetions / accesstoken not needed:
            usersRoutes.on([.GET], "isLoggedIn".pathComps, dict:noProtGroupInfo.asDict(), use: isLoggedInCheck)?.setting(
                productType: .apiResponse,
                title: "is logged in test",
                description: "Check if the user is logged in. either use /user/{uuid}/isLoggedIn or /user/me/isLoggedIn (for the user id in the bearer token / current session user) to get the login state. Requests about other users may be blocked / limited according to user roles and permissions.",
                requiredAuth:.none,
                group: groupName)
            
            // === Protections / accesstoken IS needed:
            // Registers all routes in this controller that are protected (require acces toekn and permissions)
            usersRoutes.group(UserTokenAuthenticator(),
                              AppUser.guardMiddleware() // guards against unautorized users
            ) { protected in
                
                // User CRUD:
                let getEndpointDesc = "returns user details. use /user/me to get the info of the currently logged-in user."
                protected.on([.GET], "".pathComps, use: getUser)?.setting(
                    productType: .apiResponse,
                    title: "get user info (inferred)",
                    description: getEndpointDesc,
                    requiredAuth:.bearerToken,
                    group: groupName)
                
                protected.on([.GET], "get".pathComps, use: getUser)?.setting(
                    productType: .apiResponse,
                    title: "get user info",
                    description: getEndpointDesc,
                    requiredAuth:.bearerToken,
                    group: groupName)
                
                // Patch / Update user by id:
                protected.on([.PATCH], "update".pathComps, use: updateUser)?.setting(
                    productType: .apiResponse,
                    title: "update user info",
                    description: "Update the user with new info - note properties not appearing in the PATCH body will not be zeroed or nilled but persis their current value/s.",
                    requiredAuth:.bearerToken,
                    group: groupName)
                
                // Logout user by id:
                protected.on([.POST, .GET], "logout".pathComps, use: logout)?.setting(
                    productType: .apiResponse,
                    title: "logout user",
                    description: "logout the currently logged in user.",
                    requiredAuth:.bearerToken,
                    group: groupName)
            }
        }
        
        // ==== REDIRECTS =======
        // see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#redirection_messages
        // 301 - Moved Permanently. The URL of the requested resource has been changed permanently. The new URL is given in the response.
        // 302 - Found. This response code means that the URI of requested resource has been changed temporarily. Further changes in the URI might be made in the future. Therefore, this same URI should be used by the client in future requests.
        // 308 - Permanent Redirect. This means that the resource is now permanently located at another URI, specified by the Location: HTTP Response header. This has the same semantics as the 301 Moved Permanently HTTP response code, with the exception that the user agent must not change the HTTP method used: if a POST was used in the first request, a POST must be used in the second request.
        
        // map "/me/" path (/user/me)
        // We need to redirect to a user/{id}/bla:
        routes.group(basePath.appending(strComp: "me").appending(.catchall)) { userRoutes in
            let routes = userRoutes.redirects(methods: [.GET, .POST, .PATCH, .DELETE, .PUT, .OPTIONS]) { method, req in
                var err : AppError? = nil
                var uidStr : String? = req.selfUserUUIDString
                let pathRemainder = req.url.path.components(separatedBy: "/me/").last ?? ""
                
                if pathRemainder.trimmingSuffixCharacters(in: .punctuationCharacters) == "isLoggedIn" {
                    uidStr = "00000"
                }
                
                if let uidStr = uidStr, uidStr.count > 4 && uidStr.count < 48 {
                    let newPath = "/\(self.basePath.string)/\(uidStr)/\(pathRemainder)".replacingOccurrences(ofFromTo: ["|":"_"])
                    return req.wrappedRedirect(to: newPath,
                                               type: .permanent, // redirect is cached
                                               params: [:],
                                               isShoudlForwardAllParams:true,
                                               contextStr: "UserController.boot redirecting /me/ as /self_UID/")
                } else {
                    err = AppError(code: .http_stt_unauthorized,
                                   reason: "\(self.basePath.string)/me/ redirect failed. unauthorized access denied.")
                }
                
                // JIC
                if err == nil {
                    err = AppError(code: .http_stt_notFound,
                                   reason: "\(self.basePath.string)/me/ redirect faild. not found.")
                }
                
                // Return error response if not found the redirection
                return AppErrorMiddleware.convert(request: req,
                                                  error: err!)
            }
            
            // Set route info for each route:
            for route in routes {
                let reqAuth : MNRouteAuth = route.fullPath.hasAnyOfSuffixes(["isLoggedIn", "login"]) ? .none : .bearerToken
                dlog?.verbose("boot(routes:) /me/ alias route:\(route.fullPath) method: [\(route.method.string.uppercased())]")
                route.setting(productType: .apiResponse,
                              title: "/me/ alias for: .." + route.path.fullPath.lastPathComponents(count: 2),
                              description: "UserController /me/ alias for \(route.method) \(route.path.fullPath.asNormalizedPathOnly())",
                              requiredAuth: reqAuth,
                              group:groupName)
            }
        }
        
        // = = = = X routing group ?  = = = =
    }
    
    static func exctractUIDStr(urlStr:String)->String? {
        return self.exctractUID(urlStr: urlStr)?.uuidString
    }
    
    
    // MARK: public route functions
    func logout(req: Request) async throws -> UserLogoutResponse {
        // 401 Unauthorized - use when access token is missing or wrong
        // 403 Forbidden - use when access token exists and is valid, but the permissions / role does not allow this operation

        let accessToken = try await req.getAccessToken(context: "UserController.logout(req:)")
        // logout User
        let selfUser : AppUser? = req.selfUser ?? accessToken?.$user.wrappedValue
        
        guard let selfUser = selfUser else {
            throw Abort(.badRequest, reason: "logout failed - user not found")
        }
        
        // Clear access token and
        var loginInfo = accessToken?.loginInfo
        if loginInfo == nil {
            try await accessToken?.forceLoadAllPropsIfNeeded(vaporRequest: req)
            loginInfo = accessToken?.loginInfo
        }
        
        if Debug.IS_DEBUG {
            if loginInfo == nil {
                dlog?.note("loginInfo was not found for logout!")
            }
            if accessToken == nil {
                dlog?.note("accessToken was not found for logout!")
            }
        }
        
        
        let now = Date.now
        loginInfo?.isLoggedIn = false
        accessToken?.setWasUsedNow(now: now)
        try await loginInfo?.save(on: req.db)
        try await accessToken?.save(on: req.db)
        
        // Save to req store
        req.saveToReqStore(key: ReqStorageKeys.accessToken, value: nil, alsoSaveToSession: true)
        req.saveToReqStore(key: ReqStorageKeys.selfUser, value: nil, alsoSaveToSession: true)
        req.saveToReqStore(key: ReqStorageKeys.selfUserID, value: nil, alsoSaveToSession: true)
        req.saveToReqStore(key: ReqStorageKeys.loginInfos, value: nil, alsoSaveToSession: true)
        req.saveToReqStore(key: ReqStorageKeys.selfLoginInfoID, value: nil, alsoSaveToSession: true)
        
        let sessionStartDate : Date? = req.routeContext?.sessionStartDate ?? accessToken?.loginInfo?.latestLoginDate
        return UserLogoutResponse(user:selfUser, sessionStarted: sessionStartDate)
    }
    
    func isLoggedInCheck(req: Request) async throws -> UserIsLoggedInResponse {
        var result : HTTPStatus = .unauthorized
        var notes = "User is not logged in / missing credentials / user unauthorized."
        
        var params : [String:String] = [:]
        let userController = req.application.appServer?.users
        var selfUser = req.selfUser
        if selfUser == nil {
            do {
                selfUser = try await userController?.getUser(request: req)
            } catch let error {
                dlog?.verbose(log:.note, "userController.getUser for: \(req.url.string) failed! error: \(error)")
            }
        }
        
        if let selfUser = selfUser, let selfUserUUIDStr = req.selfUserUUIDString {
            try await selfUser.forceLoadAllPropsIfNeeded(db: req.db) // JIC
            
            // Params to return even when not logged in
            params["display_name"] = selfUser.displayName
            if Debug.IS_DEBUG {
                params["debug_user_uid"] = selfUserUUIDStr
            }
            
            var loginInfo : MNUserLoginInfo? = req.getFromReqStore(key: ReqStorageKeys.loginInfos, getFromSessionIfNotFound: true)
            var accessToken : MNAccessToken? = req.getFromReqStore(key: ReqStorageKeys.accessToken, getFromSessionIfNotFound: true)
            
            // Fallbacks:
            if accessToken == nil && loginInfo != nil {
                accessToken = loginInfo?.accessToken
            } else if accessToken != nil && loginInfo == nil {
                loginInfo = accessToken?.loginInfo
            }
            if loginInfo == nil {
                loginInfo = selfUser.bestLoggedInInfo
                accessToken = loginInfo?.accessToken
            }
            
            if let info = loginInfo, let accessToken = accessToken {
                params["debug_username"] = info.userPII?.piiString ?? "?"
                params["debug_username_type"] = info.userPII?.piiType.displayName ?? "?"
                params["debug_user_domain"] = info.userPII?.piiDomain ?? "?"
                
                if Debug.IS_DEBUG {
                    params["access_token_id"] = accessToken.id?.uuidString ?? "?"
                    params["login_info_id"] = loginInfo?.id?.uuidString ?? "?"
                }
                if accessToken.isExpired {
                    notes = "access token has expired"
                    result = .unauthorized
                } else if !accessToken.isValid {
                    notes = "access token is not valid"
                    result = .unauthorized
                } else if info.isLoggedIn {
                    notes = "logged in"
                    result = .ok
                }
            }
            
            if MNModelStatus.allLoginAlowingCases.contains(selfUser.status) {
                notes = "User status does not allow logging in: authorization / status - forbidden"
                result = .unauthorized
            }
            
            // Result params
            if result != .ok && !Debug.IS_DEBUG {
                // Does not return params when not logged in or debug mode
                params = [:]
            }
        }

        return UserIsLoggedInResponse(status: result, notes: notes, userInfo:params.count > 0 ? params : nil)
    }
    
    // GET /users/:id
    func getUser(request: Request) async throws -> AppUser {
        dlog?.note("UserController.getUser(request:) REIMPLEMENT!")
//        let selfUser : AppUser? = request.selfUser // self.getSelfUser(isTryDeepQuery:false)
        var result : AppUser? = nil
//        
//        var id : UUID? = request.selfUserUUID ?? REQUES
//        if let idVal : String = request.anyParameters(forKeys: ["id", "userid", "user_id"]).first?.value {
//            id = UUID(String(stringLiteral: idVal))
//        }
//        
//        var username : String? = request.anyParameters(forKeys: ["username", "user", "user name", "name", "user_name"]).first?.value
        
//        // This allows sending "username" instead of id in the GET requests
//        if request.method == .GET &&
//
//            // We do not allow username length to be exactly ACCESS_TOKEN_UUID_STRING_LENGTH for safety, sanity and ease of testing.
//            (id?.count ?? 0 != AppConstants.ACCESS_TOKEN_UUID_STRING_LENGTH) ||
//
//            //  Check if name
//            (id?.replacingOccurrences(of: .uuidStringCharacters, with: "").count ?? 0 > 0)
//        {
//            // After testing all conditions:
//            // NOTE: Only in GET methods do we try referencing
//            username = id
//        }
//
//        guard id != nil || username != nil else {
//            return try await request.eventLoop.makeFailedFuture(Abort(.notFound, reason: "user not found. userid or username not found in request parameters.")).get()
//        }
//
//        if let id = id,  id.count == 36, let idToFind = UserUID(uuidString: id) {
//            if let selfUser = selfUser, idToFind == selfUser.buid {
//                return try await request.eventLoop.makeSucceededFuture(selfUser).get()
//            }  else {
//                result = try await UserMgr.shared.get(db: request.db, userid: idToFind, selfUser: selfUser)
//            }
//        } else if let username = username {
//            dlog?.info("id is a username [\(username)]?")
//            result = try await UserMgr.shared.get(db: request.db, username: username, selfUser: selfUser)
//        } else {
//            return try await request.eventLoop.makeFailedFuture(Abort(.notFound, reason: "user not found. userid or username not found in request parameters.")).get()
//        }
//
        guard let result = result else {
            // http status .204 noContent
            throw Abort(.dataNotFound, reason: "user nor found")
        }
        
        dlog?.note("\(self.name) getUser(request: Request) \(request.url.string)")
        return result
    }
    
    // POST /users/create
    func createUser(request: Request) async throws -> UserCreateResponse {
        throw Abort(.forbidden, reason: "some user property not allowed")
        // TODO: Reimplement!
//        guard let selfUser = request.getSelfUser(isTryDeepQuery:false) else {
//            return try await request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "no permissions")).get()
//        }
//
//        let errorJsonBody = request.isValidJSONBodyRequest()
//        guard errorJsonBody == nil else {
//            return try await request.eventLoop.makeFailedFuture(errorJsonBody ?? Abort(.unauthorized, reason: "request body unknown problem")).get()
//        }
//
//        // Assuming small json
//        let userToUpdate : User = try request.content.decode(User.self)
//        guard userToUpdate.username != selfUser.username else {
//            return try await request.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "user already exists")).get()
//        }
//
//        // Validate properties:
//        var err : Error? = userToUpdate.propertiesValidation()
//        guard err == nil else {
//            return try await request.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "some user property not allowed: [\(err?.localizedDescription ?? "unknown")]")).get()
//        }
//
//        // Add id if needed
//        if userToUpdate.id == nil {
//            userToUpdate.id = UUID()
//            //userToUpdate.userId = UserUID()
//        } else {
//            err = Abort(.forbidden, reason: "some user property not allowed")
//        }
//
//        // Create the user (save to db)
//        if err == nil {
//            let result = try await UserMgr.shared.create(db: request.db, selfUser: selfUser, users: [userToUpdate], during:request)
//            if result.isEmpty {
//                err = Abort(.internalServerError, reason: "failed creating user!")
//            } else {
//                if let userBuid : UserUID = result.valuesArray.first {
//                    if let usr = try await UserMgr.shared.get(db: request.db, userids: [userBuid]).first {
//                        // Return the created usr response:
//                        return UserCreateResponse(user:usr)
//                    } else {
//                        err = Abort(.notFound, reason: "[\(userBuid.uuidString)] was not found")
//                    }
//                } else {
//                    err = Abort(.notFound, reason: "[\(result.count)] creation result was empty.")
//                }
//            }
//        }
//
//        return try await request.eventLoop.makeFailedFuture(err!).get()
    }
    
    // PATCH /users/:id
    func updateUser(request: Request) async throws -> String {
        throw Abort(.internalServerError, reason: "Unknown error has occured")
        // TODO: Reimplement!
//        guard let selfUser = request.selfUser else { // getSelfUser(isTryDeepQuery:false)
//            throw try await request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "no permissions")).get()
//        }
//
//        var user : User? = nil
//        do {
//            user = try await self.getUser(request: request)
//        } catch let error {
//            throw try await request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "user not found. underlying error:\(error.description)")).get()
//        }
//
//        if let user = user {
//            switch UserMgr.shared.isAllowed(for: selfUser, to: .updateUser, on: user, during: request) {
//            case .success(let auser):
//                // TODO: Update user with req body / [arams...
//                dlog?.todo("implement func updateUser(request: Request).. \(auser.description)")
//                return "{ 'success' : true }"
//            case .failure(let error):
//                let eDesc = (error as Error).description
//                throw try await request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "no permissions. underlying error:\(eDesc)")).get()
//            }
//        } else {
//            throw try await request.eventLoop.makeFailedFuture(Abort(.notFound, reason: "user not found")).get()
//        }
    }
    
}
