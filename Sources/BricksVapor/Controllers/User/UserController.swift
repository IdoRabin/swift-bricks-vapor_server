//
//  UserController.swift
//
//
//  Created by Ido Rabin for Bricks on 17/1/2024.
//
import Fluent
import Vapor
import MNUtils
import MNVaporUtils
import Logging

fileprivate let dlog : Logger? = Logger(label:"UserController")

struct UserController: RouteCollection, RouteCollectionPathable {
    // MARK: Types
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    
    // MARK: AppRouteCollection
    var basePaths: [RoutingKit.PathComponent] = ["user"]
    
    // MARK: Private
    
    private func checkIfUserExists(_ username: String, req: Request) async throws -> Bool {
        let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .first()
        return user?._$idExists ?? false
    }
    
    private func checkIfUserExists(_ id: UUID, req: Request) async throws -> Bool {
        let user = try await User.query(on: req.db)
            .filter(\.$id == id)
            .first()
        return user?._$idExists ?? false
    }
    
    private func hasValidBTOKCookie(req:Request)->Bool {
        guard let cookie = req.cookies[AccessToken.cookieName] else {
            // No cookie
            return false
        }
        
        guard (cookie.expires?.isInTheFuture ?? true) &&
                !cookie.string.lowercased().contains(anyOf: ["expire", "logout"])
                && cookie.string.count > 0 else {
            // An expired / empty cookie
            return false
        }
        
        return true
    }
    
    // MARK: Public
    func getSelfUser(req: Request) throws -> User.Public {
        try req.auth.require(User.self).asPublic()
    }
    
    func getUserIdFromPath(req: Request) throws -> User.IDValue? {
        guard let idStr = req.parameters.get("id"), let id = UUID(uuidString: idStr) else {
            throw MNError(code: .user_invalid_user_input, reason: "id not found in path: \(req.route?.path.description ?? "<route is nil?!>")")
        }
        
        return id
    }
    
    func getUserInfo(_ req:Request) async throws -> Response {
        return Response.NotImplemented(description: "User.logout not implemented yet").enrichAsAppEncodableVaporResponse(request: req)
    }
    
    func setUserInfo(_ req:Request) async throws -> Response {
        return Response.NotImplemented(description: "User.logout not implemented yet").enrichAsAppEncodableVaporResponse(request: req)
    }
    
    func getUserStatus(_ req:Request) async throws -> String {
        let /*accessToken*/ _  = try req.auth.require(AccessToken.self)
        let user = try self.getSelfUser(req: req)
        return user.displayName
    }
    
    func setUserStatus(_ req:Request) async throws -> Response {
        return Response.NotImplemented(description: "User.setUserStatus not implemented yet").enrichAsAppEncodableVaporResponse(request: req)
    }
    
    func getUserStats(_ req:Request) async throws -> Response {
        return Response.NotImplemented(description: "User.logout not implemented yet").enrichAsAppEncodableVaporResponse(request: req)
    }
    
    private func redirectURLForNewSession(req:Request)->URL? {
        let reqUrlComponents = req.refererURL?.relativePath.pathComponents ?? req.url.url.relativePath.pathComponents
        
        // We have a redirect url ONLY is this is a GET request for the website (i.e leaf, not API request)
        guard req.method == .GET || reqUrlComponents.strings.contains(anyOf: ["login", "signup", "register", "join"], isCaseSensitive: false) else {
            return nil
        }
        
        // Construct new path:
        let port = ":\(req.application.http.server.configuration.port)".replacingOccurrences(ofFromTo: [":80/":"/"])
        var path = "http://" + (req.url.host ?? req.application.http.server.configuration.hostname) + port + "/"
        
        // We check in which subroot / system / subdomain we are in:
        // req.route?.mnRouteInfo?.groupTag
        let subroot = reqUrlComponents.first ?? ""
        switch subroot {
        case "dashboard": path += "\(subroot)/"
        default:
            break
        }
        
        guard let result = URL(string: path) else {
            dlog?.note("redirectURLForNewSession - invalid URL \(path)")
            return nil
        }
        
        dlog?.info("login will redirect to: \(result.absoluteString)")
        return result
    }
    
    // MARK: Public API
    func signup(_ req :Request) async throws -> UserSession.Public {
        try UserSignup.validate(content:req)
        let userSignup = try req.content.decode(UserSignup.self)
        let user : User? = try User.create(from: userSignup)
        guard let user = user else {
            throw  MNError(code:.user_invalid_user_input, reason: "User was not created. Bad input.")
        }
        
        let isUserExists = try await checkIfUserExists(userSignup.username, req: req)
        guard !isUserExists else {
            throw  MNError(code:.user_invalid_username, reason: "User already exists")
        }
        
        // Save User
        try await user.save(on: req.db)
        
        guard let token: AccessToken = try? user.createToken(source: .signup) else {
            throw  MNError(code:.user_login_failed_bad_credentials, reason: "Access token failed")
        }
        
        // Save token
        let _ = try await token.save(on: req.db)
        
        let session = UserSession(token: token, req: req, source: .signup)
        req.saveToSessionStore(key: ReqStorageKeys.userSession, value: session)
        return try session.asPublic(redirect: self.redirectURLForNewSession(req: req))
    }

    func login(_ req :Request) async throws -> Response {
        
        // Expected req body:
        // {"username":"usernameOrEmailEtc", "password":"plaintextPwd", "remember_me":true}
        
        dlog?.info("LOGIN req body: \(req.body.string.descOrNil)")
        
        let user = try req.auth.require(User.self)
        
        guard let userId = user.id else {
            throw MNError(code: .user_login_failed_user_not_found, reason: "user not found".mnDebug(add: "UserController.login userId missing."))
        }
        
        var accessToken : AccessToken? = req.auth.get(AccessToken.self)
        if accessToken?.user.id == user.id && accessToken?.isValid == true {
            // Current access token is valid
        } else {
            
            // Try to fetch existing accessToken for this user:
            accessToken = try await AccessToken.query(on: req.db)
                .filter(\.$user.$id == userId).first()
            
            if accessToken?.isValid == true {
                dlog?.info("existing accessToken found and valid")
            } else {
                // Current access token has expired or no access token found
                dlog?.info("creating new accessToken")
                accessToken = try user.createToken(source: .login)
                
                // Save token
                dlog?.info("login will save access token")
                do {
                    let _ = try await accessToken?.save(on: req.db)
                } catch let error {
                    dlog?.warning("login failed saving accessToken: \(error)\n\n\(error.description)\n\n\(error.localizedDescription)")
                }
            }
        }
        
        guard let accessToken = accessToken else {
            throw MNError(code: .http_stt_unauthorized, reason: "AccessToken issuance failure")
        }
        
        // Create the session:
        dlog?.info("login will create user session")
        let userSession = UserSession(token: accessToken, req: req, source: .login)
        
        // See also: UserSessionMiddleware
        req.auth.login(accessToken)
        req.auth.login(user)
        
        // Save session to store
        req.saveToSessionStore(key: ReqStorageKeys.userSession, value: userSession)
        
        dlog?.info("login will create response for UserSession")
        _ = try await userSession.accessToken.$user.get(reload: false, on: req.db)
        
        let response = try await userSession.asPublic(redirect: self.redirectURLForNewSession(req: req)).encodeResponse(for: req)
        
        // Add cookie for the session to the response: (stateful session token)
        if hasValidBTOKCookie(req: req) {
            dlog?.note("cookie already exists")
        } else {
            let cookie = try accessToken.asCookie(for: req)
            response.cookies[AccessToken.cookieName] = cookie
            dlog?.info("login cookie: \(cookie.string.safePrefix(maxSize: 64, suffixIfClipped: "...")) expires:\(cookie.expires.descOrNil)")
        }
        
        return response
    }
    
    func logout(_ req :Request) async throws -> Response {
        
        // Pass this date to multiple function and calls to have the same exact date!
        let logoutDate = Date.now
        
        let user = req.auth.get(User.self)
        let token = req.auth.get(AccessToken.self)
        if token?.$user.$id.value != user?.id {
            throw MNError(code:.user_logout_failed, reason: "AccessToken issue".mnDebug(add: "UserController.logout token?.$user.$id.value != user.id mismatch "))
        }
        
        // Expire
        try await token?.expire(source: .logout, expirationDate: logoutDate, db: req.db)
        var session : UserSession? = req.getFromSessionStore(key: ReqStorageKeys.userSession, required: false)
        
        dlog?.info("Logout: logging out user: [\(user?.displayName ?? "<no user>")] accessToken:\(token?.value ?? "<no token>")")
        session?.terminate(terminationSource: .logout, terminatedAt: logoutDate)
        _ = try await session?.accessToken.$user.get(reload: false, on: req.db)
        
        // Logout session
        req.auth.logout(User.self)
        req.auth.logout(AccessToken.self)
        req.saveToSessionStore(key: ReqStorageKeys.userSession, value: nil)
        req.session.destroy()
        
        // Create response that erases all client cookies
        var response = Response(status: .ok, version: .http1_1, headers: HTTPHeaders(), body: Response.Body(stringLiteral: "{'logout' : 'user_unknown'}"))
        if let session = session {
            // Replace the response completely:
            response = try await session.asPublic().encodeResponse(for: req)
        }
         
        // Set cookies with expirted values:
        response.cookies[AccessToken.cookieName] = (try token?.asCookie(for: req)) ?? AccessToken.unknownExpiredCookie(for:req)
        // response.cookies[req.application.sessions.configuration.cookieName] =
        
        // Redirect:
        if req.method == .GET {
            response.headers.replaceOrAdd(name: .location, value: "/?ref=user_logged_out")
            response.status = .temporaryRedirect
        }
        
        return response
    }
    
    // MARK: Lifecycle
    // MARK: RouteCollection
    func boot(routes: RoutesBuilder) throws {
        // Listed below are all the routing groups:
        let typeName = "\(Self.self)".padding(toLength: 20, withPad: " ", startingAt: 0)
        let groupTag = self.name // name allows to use in conincidence with the "tag" in OpenAPI to collate routes to groups
        let usersRoute = routes.grouped(self.basePath)
        
        dlog?.info("   \(typeName) boot tag/name: [\(groupTag)] basepath: '\(self.basePath)'")
        
        // Register / signup a new user:
        usersRoute.post("signup", use: signup)
            .metadata(MNRouteInfo(groupTag: self.name,
                                 productType: .apiResponse,
                                 title: "Register a user",
                                 description: "Signup / Register a user to the server with the minimally required info",
                                 requiredAuth: .none))
        
        // Login / user password required input:
        usersRoute.group(User.authenticator()) { passwordProtected in
            passwordProtected.post("login", use: login)
                .metadata(MNRouteInfo(groupTag: self.name,
                                     productType: .apiResponse,
                                     title: "Login a user",
                                     description: "Login a user to the server",
                                     requiredAuth: .userPassword))
        }
        
        // Users AccessToken Protected
        usersRoute.group(AccessToken.authenticator()) { tokenProtected in
            tokenProtected.group(":id") { idPath in // TODO Validate tokenProtected.user.id to the id in the path
                idPath.get("info", use: getUserInfo)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                         productType: .apiResponse,
                                         title: "Get user info",
                                         description: "Get all user info by user id (self or requires ac permissions)",
                                         requiredAuth: .userToken))
                idPath.post("info", use: setUserInfo)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                         productType: .apiResponse,
                                         title: "Update user info",
                                         description: "Update user info by user id (self or requires ac permissions)",
                                         requiredAuth: .userToken))
                idPath.get("status", use: getUserStatus)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                         productType: .apiResponse,
                                         title: "Get user status",
                                         description: "Get user status by user id (self or requires ac permissions)",
                                         requiredAuth: .userToken))
                idPath.post("status", use: setUserStatus)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                         productType: .apiResponse,
                                         title: "Set user status",
                                         description: "Set user status by user id (self or requires ac permissions)",
                                         requiredAuth: .userToken))
                idPath.get("stats", use: getUserStats)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                         productType: .apiResponse,
                                         title: "Get user statistics",
                                         description: "Get user statistics by user id (self or requires ac permissions)",
                                         requiredAuth: .userToken))
                
                idPath.get("logout", use: logout)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                         productType: .apiResponse,
                                         title: "Logout user",
                                         description: "Logout the user from the system (self or requires ac permissions)",
                                         requiredAuth: .userToken))
            }
            
            tokenProtected.group("me") { idPath in
                // TODO: Catchall forwarding to the :id group using the token id.
            }
        }
    }
}
