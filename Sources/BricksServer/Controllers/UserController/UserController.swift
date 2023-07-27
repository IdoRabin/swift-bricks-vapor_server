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
    
    @AppSettable(name:"UserController.accessTokenRecentlyRenewedTimeInterval", default: AppConstants.ACCESS_TOKEN_RECENT_TIMEINTERVAL_THRESHOLD) static var accessTokenRecentlyRenewedTimeInterval : TimeInterval
    @AppSettable(name:"UserController.accessTokenExpirationDuration", default: AppConstants.ACCESS_TOKEN_EXPIRATION_DURATION) static var accessTokenExpirationDuration : TimeInterval
    let basePath = RoutingKit.PathComponent(stringLiteral: "user")
    
    struct BearerToken : Codable {
        let token : String
        let expirationDate : Date
        let createdDate : Date

        init(token newToken:String, expiration:Date? = nil) {
            token = newToken
            createdDate = Date()
            expirationDate = expiration ?? createdDate.addingTimeInterval(UserController.accessTokenExpirationDuration)
        }

        var isNewlyRenewed : Bool {
            return abs(createdDate.timeIntervalSinceNow) < UserController.accessTokenRecentlyRenewedTimeInterval
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
    
    // MARK: Controller methods
    
    // MARK: Controller API:
    // Controller methods should always accept a Request and return something ResponseEncodable
    override func boot(routes: RoutesBuilder) throws {
        var noProtGroupInfo = AppRouteInfo()
        
        // Listed below are all the routing groups:
        let groupName = basePath.description
        
        //  = = = = Login routing group  = = = =
        // path: /{basePath}/login
        // Requires user + password Authenticator:
        let loginGroup : RoutesBuilder = routes.grouped(UserPasswordAuthenticator())
        loginGroup.group(basePath) { loginRoutes in
            // let groupInfo = AppRouteInfo(requiredAuth: .userPassword)
            loginRoutes.on([.POST, .GET], pathComp("login"), use: login)?.setting(
                productType: .apiResponse,
                title: "login",
                description: "login as a user of the client app. The user password provided must match an existing user's credentials.",
                requiredAuth:.userPassword,
                group: groupName)
        }
        
        // = = = = User/s protected root commands = = = =
        routes.group(UserTokenAuthenticator(),
                     AppUser.guardMiddleware() // guards against unautorized users: assuming User implements Vapor.Authenticatable
        ) { rprotected in
            // "Create" does not require id because the user being crated has no id (YET):
            rprotected.on([.POST], [basePath, pathComp("create")], use: createUser)?.setting(
                productType: .apiResponse,
                title: "create",
                description: "Create a new user of the client app. Requires user creation credentials and permissions. New user should not have an existing username. A uuid passed for the new user is ignored and the uuid is created by the server only.",
                requiredAuth:.bearerToken,
                group: groupName)
        }
        
        // = = = = User/s protected routing group = = = =
        // Requires calling client to supplie a valid accessToken / bearerToken (?)
        routes.group([basePath, pathComp(":id")]) { usersRoutes in
            
            // === No protetions / accesstoken not needed:
            usersRoutes.on([.GET], pathComp("isLoggedIn"), dict:noProtGroupInfo.asDict(), use: isLoggedInCheck)?.setting(
                productType: .apiResponse,
                title: "is logged in test",
                description: "Check if the user is logged in. either use /user/{uuid}/isLoggedIn or /user/me/isLoggedIn (for the user id in the bearer token / current session user) to get the login state. Requests about other users may be blocked / limited according to user roles and permissions.",
                requiredAuth:.bearerToken,
                group: groupName)
            
            // === Protections / accesstoken IS needed:
            // Registers all routes in this controller that are protected (require acces toekn and permissions)
            usersRoutes.group(UserTokenAuthenticator(),
                              AppUser.guardMiddleware() // guards against unautorized users
            ) { protected in
                
                // User CRUD:
                let getEndpointDesc = "returns user details. use /user/me to get the info of the currently logged-in user."
                protected.on([.GET], pathComp(""), use: getUser)?.setting(
                    productType: .apiResponse,
                    title: "get user info (inferred)",
                    description: getEndpointDesc,
                    requiredAuth:.bearerToken,
                    group: groupName)
                
                protected.on([.GET], pathComp("get"), use: getUser)?.setting(
                    productType: .apiResponse,
                    title: "get user info",
                    description: getEndpointDesc,
                    requiredAuth:.bearerToken,
                    group: groupName)
                
                // Patch / Update user by id:
                protected.on([.PATCH], pathComp("update"), use: updateUser)?.setting(
                    productType: .apiResponse,
                    title: "update user info",
                    description: "Update the user with new info - note properties not appearing in the PATCH body will not be zeroed or nilled but persis their current value/s.",
                    requiredAuth:.bearerToken,
                    group: groupName)
                
                // Logout user by id:
                protected.on([.POST, .GET], pathComp("logout"), use: logout)?.setting(
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
        routes.group(basePath, pathComp("me"), .catchall) { userRoutes in
            let routes = userRoutes.redirects(methods: [.GET, .POST, .PATCH, .DELETE, .PUT, .OPTIONS]) { method, req in
                if let uidStr : String = req.selfUserUUIDString, uidStr.count > 4 && uidStr.count < 48 {
                    let pathRemainder = req.url.path.components(separatedBy: "/me/").last ?? ""
                    let newPath = "/\(self.basePath)/\(uidStr)/\(pathRemainder)/".replacingOccurrences(ofFromTo: ["|":"_"])
                    return req.wrappedRedirect(to: newPath,
                                               type: .permanent,
                                               params: [:],
                                               isShoudlForwardAllParams:true,
                                               contextStr: "UserController.boot redirecting /me/ as /self_UID/")
                } else {
                    dlog?.note("redirects for /me/ failed: selfUserId returned nil!")
                }
                
                // Return error response if not found the redirection
                let errMdle = AppErrorMiddleware.convert(request: req,
                                                         error: Abort(.internalServerError,
                                                                      reason: "\(self.basePath)/me/ redirect faild for an unknown reason"))
                return errMdle
            }
            
            // Set route info for each route:
            for route in routes {
                dlog?.verbose("boot(routes:) /me/ alias route:\(route.fullPath) method: [\(route.method.string.uppercased())] route: \(route.mnRoute)")
                route.setting(productType: .apiResponse,
                              title: route.path.fullPath.asNormalizedPathOnly(),
                              description: "UserController /me/ alias \(route.method)",
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
        throw Abort(.internalServerError, reason: "Unknown error has occured")
        
//        // 401 Unauthorized - use when access token is missing or wrong
//        // 403 Forbidden - use when access token exists and is valid, but the permissions / role does not allow this operation
//
//        // logout User
//        let selfUser : User? = req.selfUser // (isTryDeepQuery:true)
//        guard let selfUser = selfUser else {
//            throw Abort(.badRequest, reason: "logout failed - user not found")
//        }
//
//        let permission = UserMgr.shared.isAllowed(for: selfUser, to: .logoutUser, on: selfUser, during: req)
//        if permission.isSuccess {
//            // try await UserMgr.getAccessToken(request: req, user: selfUser)
//            // let accessToken = try await UserMgr.getAccessToken(request: req, user: selfUser)
//
//        } else {
//            throw permission.errorValue ?? Abort(.forbidden, reason: "logout failed - user is not allowed to logout");
//        }
////        guard permission.isSuccess else {
//        /// .... ??? ?? ? ?? TODO: What was here
////        return UserLogoutResponse{
////        user:
////        }
//        throw Abort(.internalServerError, reason: "logout failed for an unknown reason")
    }
    
    func isLoggedInCheck(req: Request) throws -> String {
        throw Abort(.internalServerError, reason: "Unknown error has occured")
        
//        let IS_RETURNS_USERID = Debug.IS_DEBUG
//        let accessToken = req.accessToken // getAccessToken(context:"UserController.isLoggedInCheck")
//        var userUUIDStr : String? = accessToken?.userUIDString
//
//        var params : [String:String] = [
//            "user_is_logged_in" : "false",
//        ]
//
//        if let selfUser = req.selfUser, let selfUserUUIDStr = req.selfUserUUIDString { // getSelfUser(isTryDeepQuery:false) {
//            if userUUIDStr == nil {
//                userUUIDStr = selfUser.buid?.uuidString
//            } else if userUUIDStr != selfUserUUIDStr {
//                dlog?.warning("accessToken USER UUID != selfUser.UUID")
//            }
//            params["username"] = selfUser.username
//            params["username_type"] = selfUser.username
//            params["user_domain"] = selfUser.userDomain
//            params["user_is_logged_in"] = "true"
//        }
//
//        if IS_RETURNS_USERID && userUUIDStr != nil {
//            // Optional return value
//            params["debug_found_userid"] = userUUIDStr
//        }
//
//        if let result = params.serializeToJsonString(isForRemote: true, prettyPrint: Debug.IS_DEBUG), result.count > 0 {
//            return result
//        } else {
//            throw Abort(.internalServerError, reason: "isLoggedInCheck failed for unknown reason")
//        }
    }
    
    // GET /users/:id
    func getUser(request: Request) async throws -> AppUser {
        throw Abort(.internalServerError, reason: "Unknown error has occured")
        
//        let selfUser : User? = request.getSelfUser(isTryDeepQuery:false)
//        var result : User? = nil
//
//        let id = request.anyParameters(forKeys: ["id", "userid"]).first?.value
//        var username = request.anyParameters(forKeys: ["username", "user", "user name", "name"]).first?.value
//
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
//        guard let result = result else {
//            // http status .204
//            throw Abort(.dataNotFound, reason:"user nor found")
//        }
//        return result
    }
    
    // POST /users/create
    func createUser(request: Request) async throws -> UserCreateResponse {
        throw Abort(.forbidden, reason: "some user property not allowed")
        
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
