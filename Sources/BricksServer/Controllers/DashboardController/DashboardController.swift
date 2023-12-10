//
//  DashboardController.swift
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
import RoutingKit

fileprivate let dlog : DSLogger? = DLog.forClass("DashboardController")

// Convenience, Brevity
private typealias CKey = AppRouteInfo.CodingKeys

/// Serves HTML pages using leaf for dashboard control of the server
class DashboardController : AppRoutingController {
    static let PAGE_TITLE_PREFIX = "\(AppConstants.APP_DISPLAY_NAME.capitalized) dashboard"
    static let ERROR_PAGE_COMP = "errorpage"
    static let FREE_PAGE_ROUTES      = ["about", "register", "login"] // excluded: main and errorpage. Note: login is the login page, not the login request
    static let LOGIN_REQUEST_ROUTES     = ["requestLogin"] // requestLogin is a post or GET request, not the login webpage get request
    static let PROTECTED_PAGE_ROUTES = ["logout", "logs", "roles" , "stats" , "terms"]
    
    static let BASE_PATH = RoutingKit.PathComponent(stringLiteral: "dashboard")
    
    // MARK: Private
    @discardableResult
    private func dboardRedirectToErrorPage(_ req: Request, error:Error) async throws -> Response  {
        return try await Self.dboardRedirectToErrorPage(req, error:error)
    }

    // MARK: Public static methods
    static func dboardRedirectToErrorPage(_ req: Request, error:Error) async throws -> Response {
        let params = ["req":req.requestUUIDString]
        let origRoute = req.url.path
        let code = AppError.bestErrorCode(error)
        let reason = AppError.bestErrorReason(error)
        let appError = (error as? AppError) ??  AppError(code: AppErrorCode(rawValue: code)!, reason: reason)
        let routeContext : MNRouteContext? = nil // XX try await MNRoutingBase.getOrCreateRouteContext(for: req)
        routeContext?.setError(req: req, err: appError, errorOrigPath: origRoute, errReqId: req.id)
        
        if req.hasSession {
            // Reedirect
            //   case .permanent 301  A cacheable redirect.
            //   case .normal    303  "see other" Forces the redirect to come with a GET, regardless of req method.
            //   case .temporary 307  Maintains original request method, ie: PUT will call PUT on redirect.
            
            // Save error and redirect to session history:
            req.routeHistory.update(req: req, error: appError)
            
            // String+PathComponents.swift OR RoutinKit.PathComponent
            return req.wrappedRedirect(to: "/\(Self.BASE_PATH)/\(Self.ERROR_PAGE_COMP)",
                                       type: .normal,
                                       params: params,
                                       isShoudlForwardAllParams: false,
                                       errorToForward: appError,
                                       contextStr: "redirected to error page from \(req.url.string)")
        } else {
            return req.wrappedRedirect(to: "\(Self.ERROR_PAGE_COMP)?\(params.toURLQueryString())",
                                       type: .normal,
                                       encoding: .base64,
                                       params: params,
                                       isShoudlForwardAllParams: false,
                                       errorToForward: appError,
                                       contextStr: "Redirected from [\(origRoute)] To /dashboard/\(Self.ERROR_PAGE_COMP)? code:\(code)")
        }
    }
    
    // MARK: MNRoutingController overrides
    // REQUIRED OVERRIDE for MNRoutingController
    override var basePaths : [[RoutingKit.PathComponent]] {
        // NOTE: var basePath is derived from basePaths.first
        
        // Each string should descrive a full path
        return RoutingKit.PathComponent.arrays(fromPathStrings: ["dashboard"])
    }
    
    // MARK: Controller API:
    override func boot(routes: RoutesBuilder) throws {
        //Register all routes in this controller
        let groupName = "dashboard"
        
        // Main "dashboard" landing page: (root path)
        let homeEndpointDesc = "returns user Dashboard homepage."
        routes.get(basePath, use: dboardHome).setting(
            productType: .webPage,
            title: "\(Self.PAGE_TITLE_PREFIX): Home",
            description: "Dashboard home page, allowing login / signup or presenting the most important stats when logged in",
            requiredAuth: .webPageAgent,
            group: groupName)
        .setting(
            productType: .webPage,
            title: "Dashboard homepage",
            description: homeEndpointDesc,
            requiredAuth:.bearerToken,
            group: groupName)
        
        // Sub routes of "dashboard"
        routes.group(basePath) { dashboardRoute in
            
            // All pages except the catchall:
            
            // Error page:
            dashboardRoute.on(.GET, Self.ERROR_PAGE_COMP.pathComps, use: self.dboardErrorPage).setting(
                productType: .webPage,
                title: "\(Self.PAGE_TITLE_PREFIX): Error",
                description: "An error page, either of an http status code or other error code",
                requiredAuth: .none,
                group: groupName)
            .setting(
                productType: .webPage,
                title: "Dashboard error page",
                description: "Dashboard error page for handled errors.",
                requiredAuth:.bearerToken,
                group: groupName)
            
            // Pages and protected pages:
            dashboardRoute.group(UserTokenAuthenticator()/* detect logged-in but not guard */) { protectedRoutes in
                for page in Self.FREE_PAGE_ROUTES {
                    dashboardRoute.on(.GET, page.pathComps, use: self.dboardPage)
                        .setting(
                            productType: .webPage,
                            title: "\(Self.PAGE_TITLE_PREFIX): \(page.capitalizedFirstWord())",
                            description: "A content webpage page of \(page.lowercased()) for the dashboard",
                            requiredAuth: .webPageAgent,
                            group: groupName)
                }
            }
            
            // = = = = Dashboard protected paths = = = =
            // guards against unautorized users
            dashboardRoute.group(UserTokenAuthenticator(), AppUser.guardMiddleware()) { protectedRoutes in
                for page in Self.PROTECTED_PAGE_ROUTES {
                    protectedRoutes.on(.GET, page.pathComps, use: self.dboardPage)
                        .setting(
                            productType: .webPage,
                            title: "\(Self.PAGE_TITLE_PREFIX): \(page.capitalizedFirstWord())",
                            description: "A content webpage page of \(page.lowercased()) for the dashboard (protected access).",
                            requiredAuth: [.webPageAgent, .backendAccess, .bearerToken],
                            group: groupName)
                }
            }

            // == API: "POST" === calls to dashboard route (wraps other api calls)
            // All pages with webform / "POST" method:
            dashboardRoute.group(UserPasswordAuthenticator(allowedRoles: ["TODO:Dasboard access"]), AppUser.guardMiddleware()) { loginRoutes in
                loginRoutes.on(.POST, "login".pathComps, body:.stream, use: self.dboardPOSTLogin)
                    .setting(
                        productType: .webPage,
                        title: "Dashboard login POST API call",
                        description: "an api POST call wrapping a /user/me/login call",
                        requiredAuth: .userPassword,
                        group: groupName)
            }
                
            dashboardRoute.on(.GET, "logout".pathComps, use: self.logout)
                .setting(
                    productType: .webPage,
                    title: "Dashboard logout POST API call",
                    description: "an api POST call wrapping a /user/me/logout call",
                    requiredAuth: [.webPageAgent, .bearerToken, .webPageAgent],
                    group: groupName)
                .setting(
                    productType: .webPage,
                    title: "Dashboard logout",
                    description: "a GET call to logout from dashboard. will redirect to dashboard home page",
                    requiredAuth: .webPageAgent,
                    group: groupName)

            dashboardRoute.on(.POST, "register".pathComps, use: self.dboardPOSTRegister)
                .setting(
                    productType: .webPage,
                    title: "Dashboard register POST API call",
                    description: "an api POST call wrapping a /user/me/register call",
                    requiredAuth: .webPageAgent,
                    group: groupName)
            
            // Fallback catchall:
            dashboardRoute.get(.catchall) { req in
                dlog?.info("Dashboard catchall will throw http status 404!")
                _ = req.route?.routeInfo // init if does not exist
                _ = req.routeContext // init if does not exist
                return try await self.dboardRedirectToErrorPage(req, error: Abort(.notFound, reason:"Path not found!"))
            }.setting(
                productType: .webPage,
                title: "Dashboard catchall",
                description: "Dashboard catch all - re-routing to dashboard home page",
                requiredAuth: .webPageAgent,
                group: groupName)
        }
    }
    
    func logout(_ req: Request) async throws -> Response {
        guard let users = req.application.appServer?.users else {
            throw AppError(code: .http_stt_internalServerError, reason: "server error: login .users not found")
        }
        
        let logoutResult = try await users.logout(req: req)
        return req.redirect(to: basePath.fullPath, redirectType: .temporary)
    }
    
    func dboardLoginPage(_ req: Request) async throws {
        
        // Try to authenticate (without throwing) - see if any user is already logged in
        await self.authenticateIfPossible(unknownReq: req)
        
        var contextPageParams : [String:String] = [:]
        // TODO: Reimplement error code evaluation
        let errCode = 0 // Int(context.errorCode ?? "0") ?? 0
        if errCode != 0 { // when reloaded w / error
            // TODO: Use this only is we assume a "GET" login and not a urlRequset to: .POST /dboardPOSTLogin...
            let aeCode = AppErrorCode(rawValue: errCode) ?? .http_stt_unauthorized
            
            // Page params:
            var isUsernameAndPwdInvalid : Bool = false
            var isUsernameInvalid : Bool = false
            var isPasswordInvalid : Bool = false
            
            var invalidUsernameAndPwdText : String = ""
            var invalidUsernameText : String = ""
            var invalidPasswordText : String = ""
            
            
            switch aeCode {
            case .user_login_failed:
                isUsernameAndPwdInvalid = true
                invalidUsernameAndPwdText = "Login has failed."
                
            case .user_login_failed_no_permission:
                isUsernameAndPwdInvalid = true
                invalidUsernameAndPwdText = "User not found or no permissions."
                
            case .user_login_failed_bad_credentials:
                isUsernameAndPwdInvalid = true
                invalidUsernameAndPwdText = "User not found or failed permissions."
                
            case .user_login_failed_permissions_revoked:
                isUsernameAndPwdInvalid = true
                invalidUsernameAndPwdText = "User not found or revoked permissions."
                
            case .user_login_failed_user_name:
                isUsernameInvalid = true
                // TODO: REimplement invalidUsernameText = context.errorReason ?? "Bad or missing user name"
                
            case .user_login_failed_password:
                isPasswordInvalid = true
                // TODO: REimplement invalidPasswordText = context.errorReason ?? "Bad or missing password or user was not found."
                
            case .user_login_failed_name_and_password:
                isUsernameAndPwdInvalid = true
                isUsernameInvalid = true
                isPasswordInvalid = true
                invalidUsernameText = "Username is missing or wrong"
                invalidPasswordText = "Password is missing or wrong"
                // TODO: REimplement invalidUsernameAndPwdText = context.errorReason ?? "Bad or missing password or user name or user was not found."
                
            case .user_login_failed_user_not_found:
                isUsernameAndPwdInvalid = true
                invalidUsernameAndPwdText = "User not found"
                
            default:
                dlog?.warning("dboardLoginPage error code:\(errCode) \(aeCode) was not handled!")
                isUsernameAndPwdInvalid = true
                invalidUsernameAndPwdText = "Unknown login error"
            }
            
            // Params:
            // "is-valid" / "is-invalid"
            contextPageParams["usernameAndPwdValidationClass"] = isUsernameAndPwdInvalid ? "is-invalid" : ""
            contextPageParams["usernameValidationClass"] = isUsernameInvalid ? "is-invalid" : ""
            contextPageParams["passwordValidationClass"] = isPasswordInvalid ? "is-invalid" : ""
            contextPageParams["invalidUsernameAndPwdText"] = invalidUsernameAndPwdText
            contextPageParams["invalidUsernameText"] = invalidUsernameText
            contextPageParams["invalidPasswordText"] = invalidPasswordText
            
            // dlog?.info("Login context page params: \(contextPageParams.descriptionLines)")
            contextPageParams["invalidFieldsAreAlwaysIncluded"] = "true"
            
            // Finally:
            dlog?.todo("Reimplement  context.pageParams.merge(dict: with infoable / contextPageParams")
            // context.pageParams.merge(dict: contextPageParams)
        }
    }
    
    func dboardPage(_ req: Request) async throws -> View {
        // req.routeContext.
        
        let allParams : [String:String] = [:] // req.collatedAllParams()
        if Debug.IS_DEBUG {
            if (allParams.count > 0) {
                dlog?.info("dboardPage collatedAllParams: \(allParams.descriptionLines)")
            }
        }
        
        let errReqId = allParams["req"]?.removingPercentEncodingEx ?? ""
        if let truple = req.routeHistory.getError(byReqId: errReqId) {
            req.routeContext.setError(req:req, errorTruple: truple)
        }
        
        // Other cases
        switch req.url.path.asNormalizedPathOnly().lastPathComponent().trimming(string: "/") {
        case "login":
            try await dboardLoginPage(req) // webpage
        case "loginRequest":
            if [.POST, .GET].contains(req.method) {
                try await dboardLoginPage(req) // API requset
            }
        default:
            break
        }
        
        let futureView = req.view.render(req.url.path, req.routeContext)
        futureView.whenComplete { result in
            req.routeHistory.update(req: req, result: result)
        }
        return try await futureView.get()
    }
    
    func dboardHome(_ req: Request) async throws -> View {
        
        // Try to authenticate (without throwing)
        await self.authenticateIfPossible(unknownReq: req)
        
        // Context
        let routeContext = req.routeContext
        let futureView = req.view.render("/\(basePath.string)/main", routeContext)
        futureView.whenComplete { result in
            req.routeHistory.update(req: req, result: result)
        }
        return try await futureView.get()
    }
    
    func dboardErrorPage(_ req: Request) async throws -> View {
        // dlog?.info("dboardErrorPage query: \(req.url.query.descOrNil)")
        await self.authenticateIfPossible(unknownReq: req)
        
        let allParams : [String:String] = req.collatedAllParams()
        if Debug.IS_DEBUG {
            if (allParams.count > 0) {
                dlog?.info("dboardErrorPage collatedAllParams: \(allParams.descriptionLines)")
            }
        }
        
        let errReqId = allParams["req"]?.removingPercentEncodingEx ?? ""
        
        // Get latest context for the error page:
        let routeContext = req.routeContext
        if let truple = req.routeHistory.getError(byReqId: errReqId) {
            routeContext.setError(req:req, errorTruple: truple)
        }
        
        let futureView = req.view.render("/\(basePath.string)/\(Self.ERROR_PAGE_COMP)", routeContext)
        futureView.whenComplete { result in
            req.routeHistory.update(req: req, result: result)
        }
        return try await futureView.get()
    }
    
    // MARK: Web form [POST] - dashboard wraps API calls from the web pages only -
    // See: https://developer.mozilla.org/en-US/docs/Learn/Forms/Sending_and_retrieving_form_data
    // The POST PARAMETERS are encoded as queryParams, but is sent in the body
    /* Example for a BODY:
        name=testname&password=testpwd
    */
    
    // NOTE: We wrap the native UserConbtroller api to allow modularity and separation of responsibility between web forms requests and login/logout
    // TODO: Consider adding a CSRF token to view pages
    func dboardPOSTLogin(_ req: Request) async throws -> Response {
        
        guard let users = req.application.appServer?.users else {
            throw AppError(code: .http_stt_internalServerError, reason: "server error: login .users not found")
        }
        
        // We are getting a Response and not UserLoginResponse because we needed to set a cookie in users.login(req:...)
        let result = try await users.login(req: req)
//        return req.wrappedRedirect(to: "/\(basePath.string)/",
//                                   type: .normal,
//                                   params: result.asDict,
//                                   isShoudlForwardAllParams: true,
//                                   contextStr:"DashboardController.dboardPOSTLogin")
         return result
    }
    
//    func dboardPOSTLogout(_ req: Request) async throws -> Response {
//        // Redictect codes: force redirect:
//        //   case .permanent 301  A cacheable redirect.
//        //   case .normal    303  "see other" Forces the redirect to come with a GET, regardless of req method.
//        //   case .temporary 307  Maintains original request method, ie: PUT will call PUT on redirect.
//        
//        dlog?.info("dboardPOSTLogout call logoutlogout for user id: \(req.selfUserUUIDString.descOrNil)")
//        do {
//            // var response : UserController.UserLogoutResponse
//            if let userController = AppServer.shared.users {
//                _ = try await userController.logout(req: req)
//            } else {
//                _ = try await UserController(app:req.application, manager: AppServer.shared.routes).logout(req: req)
//            }
//            return req.wrappedRedirect(to: "/\(basePath.string)/",
//                                       type: .normal,
//                                       params: [:],
//                                       isShoudlForwardAllParams: false,
//                                       contextStr:"DashboardController.dboardPOSTLogout")
//        } catch let error {
//            return try await self.dboardRedirectToErrorPage(req, error: error)
//        }
//    }
    
    func dboardPOSTRegister(_ req: Request) async throws -> Response {
        // Redictect codes: force redirect:
        //   case .permanent 301  A cacheable redirect.
        //   case .normal    303  "see other" Forces the redirect to come with a GET, regardless of req method.
        //   case .temporary 307  Maintains original request method, ie: PUT will call PUT on redirect.
        
        dlog?.info("dboardPOSTRegister call register for req: \(req.body.string.descOrNil)")
        do {
            // var response : UserController.UserCreateResponse
            if let userController = AppServer.shared.users {
                _ = try await userController.createUser(request: req)
            } else {
                _ = try await UserController(app:req.application, manager: AppServer.shared.routes).createUser(request: req)
            }

            return req.wrappedRedirect(to: "/\(basePath.string)/",
                                       type: .normal,
                                       params: [:],
                                       isShoudlForwardAllParams: false,
                                       contextStr: "DashboardController.dboardPOSTRegister")
        } catch let error {
            return try await self.dboardRedirectToErrorPage(req, error: error)
        }
    }
}

// TODO: SHUTDOWN::: ==================
/*
app.get("shutdown") { req -> HTTPStatus in
    guard let running = req.application.running else {
        throw Abort(.internalServerError)
    }
    running.stop()
    return .ok
}
*/
