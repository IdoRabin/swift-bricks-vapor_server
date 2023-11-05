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
    static let FREE_PAGE_ROUTES      = ["about", "login", "register"] // excluded: main and errorpage
    static let PROTECTED_PAGE_ROUTES = ["logout", "logs", "roles" , "stats" , "terms"]
    
    static let BASE_PATH = RoutingKit.PathComponent(stringLiteral: "dashboard")
    let basePath = DashboardController.BASE_PATH
    
    // MARK: Private
    @discardableResult
    private func dboardRedirectToErrorPage(_ req: Request, error:Error) async throws ->Response  {
        return try await Self.dboardRedirectToErrorPage(req, error:error)
    }

    private func isLoggedIn(req:Request)->Bool {
        return false
//        guard let user = req.getSelfUser(isTryDeepQuery: true) else {
//            return false
//        }
//        guard let uid = user.id else {
//            return false
//        }
//        guard let accessToken = req.getAccessToken(context:"DashboardController.isLoggedIn") else {
//            return false
//        }
//
//        return uid.uuidString != UID_EMPTY_STRING && accessToken.isValid
    }

    // MARK: Public static methods
    static func dboardRedirectToErrorPage(_ req: Request, error:Error) async throws ->Response {
        let params = ["req":req.requestUUIDString]
        if req.hasSession {
            // Reedirect
            //   case .permanent 301  A cacheable redirect.
            //   case .normal    303  "see other" Forces the redirect to come with a GET, regardless of req method.
            //   case .temporary 307  Maintains original request method, ie: PUT will call PUT on redirect.
            
            // Save error and redirect to session history:
            req.routeHistory?.update(req: req, error: error)
            
            // String+PathComponents.swift OR RoutinKit.PathComponent
            return req.wrappedRedirect(to: "/\(Self.BASE_PATH)/\(Self.ERROR_PAGE_COMP)",
                                       type: .normal,
                                       params: params,
                                       isShoudlForwardAllParams: false,
                                       contextStr: "redirected to error page from \(req.url.string)")
        } else {
            let origRoute = req.url.path
            let code = AppError.bestErrorCode(error)
            let reason = AppError.bestErrorReason(error)
            let appError = AppError(AppErrorCode(rawValue: code)!, reason: reason)
            return req.wrappedRedirect(to: "\(Self.ERROR_PAGE_COMP)?\(params.toURLQueryString())",
                                       type: .normal,
                                       encoding: .base64,
                                       params: params,
                                       isShoudlForwardAllParams: false,
                                       errorToForward: appError,
                                       contextStr: "Redirected from [\(origRoute)] To /dashboard/\(Self.ERROR_PAGE_COMP)? code:\(code)")
        }
    }
    
    // MARK: Public Controller methods should always accept a Request and return something ResponseEncodable
    // BOOT -
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
        routes.group([basePath]) { dashboardRoute in
            
            // All pages except the catchall:
            
            // Error page:
            dashboardRoute.on(.GET, pathComp(Self.ERROR_PAGE_COMP), use: self.dboardErrorPage).setting(
                productType: .webPage,
                title: "\(Self.PAGE_TITLE_PREFIX): Error",
                description: "An error page, either of an http status code or other error code",
                requiredAuth: .none,
                group: groupName)
            
            // Pages and protected pages:
            for page in Self.FREE_PAGE_ROUTES {
                dashboardRoute.on(.GET, pathComp(page), use: self.dboardPage).setting(
                    productType: .webPage,
                    title: "\(Self.PAGE_TITLE_PREFIX): \(page.capitalizedFirstWord())",
                    description: "A content webpage page of \(page.lowercased()) for the dashboard",
                    requiredAuth: .webPageAgent,
                    group: groupName)
            }
            
            // = = = = Dashboard protected paths = = = =
            // guards against unautorized users
            dashboardRoute.group(UserTokenAuthenticator(), AppUser.guardMiddleware()) { protectedRoutes in
                for page in Self.PROTECTED_PAGE_ROUTES {
                    protectedRoutes.on(.GET, pathComp(page), use: self.dboardPage).setting(
                        productType: .webPage,
                        title: "\(Self.PAGE_TITLE_PREFIX): \(page.capitalizedFirstWord())",
                        description: "A content webpage page of \(page.lowercased()) for the dashboard (protected access).",
                        requiredAuth: [.webPageAgent, .backendAccess, .bearerToken],
                        group: groupName)
                }
            }

            // == API: "POST" === calls to dashboard route (wraps other api calls)
            // All pages with webform / "POST" method:
            dashboardRoute.on(.POST, pathComp("login"), body:.stream, use: self.dboardPOSTLogin).setting(
                productType: .webPage,
                title: "Dashboard login POST API call",
                description: "an api POST call wrapping a /user/me/login call",
                requiredAuth: .webPageAgent,
                group: groupName)
                
            dashboardRoute.on(.POST, pathComp("logout"), use: self.dboardPOSTLogout).setting(
                productType: .webPage,
                title: "Dashboard logout POST API call",
                description: "an api POST call wrapping a /user/me/logout call",
                requiredAuth: [.webPageAgent, .bearerToken, .webPageAgent],
                group: groupName)

            dashboardRoute.on(.POST, pathComp("register"), use: self.dboardPOSTRegister).setting(
                productType: .webPage,
                title: "Dashboard register POST API call",
                description: "an api POST call wrapping a /user/me/register call",
                requiredAuth: .webPageAgent,
                group: groupName)
            
            // Fallback catchall:
            dashboardRoute.get(.catchall) { req in
                dlog?.info("Dashboard catchall will throw http status 404!")
                return try await self.dboardRedirectToErrorPage(req, error: Abort(.notFound, reason:"Path not found!"))
            }.setting(
                productType: .webPage,
                title: "Dashboard catchall",
                description: "Dashboard catch all - re-routing to dashboard home page",
                requiredAuth: .webPageAgent,
                group: groupName)
        }
    }
    
    private func prepContext(_ req:Request)->AppRouteContext {
        return req.routeContext ?? AppRouteContext.setupRouteContext(for: req)
    }
    
    func dboardLoginPage(_ req: Request, context:AppRouteContext) {
        var contextPageParams : [String:String] = [:]
        let errCode = Int(context.errorCode ?? "0") ?? 0
        if errCode != 0 {
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
                invalidUsernameText = context.errorReason ?? "Bad or missing user name"
                
            case .user_login_failed_password:
                isPasswordInvalid = true
                invalidPasswordText = context.errorReason ?? "Bad or missing password or user was not found."
                
            case .user_login_failed_name_and_password:
                isUsernameAndPwdInvalid = true
                isUsernameInvalid = true
                isPasswordInvalid = true
                invalidUsernameText = "Username is missing or wrong"
                invalidPasswordText = "Password is missing or wrong"
                invalidUsernameAndPwdText = context.errorReason ?? "Bad or missing password or user name or user was not found."
                
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
            context.pageParams.merge(dict: contextPageParams)
        }
    }
    
    func dboardPage(_ req: Request) -> EventLoopFuture<View> {
        let context = prepContext(req)
        
        let allParams : [String:String] = [:] // req.collatedAllParams()
        if Debug.IS_DEBUG {
            if (allParams.count > 0) {
                dlog?.info("dboardErrorPage collatedAllParams: \(allParams.descriptionLines)")
            }
        }
        
        let errReqId = allParams["req"]?.removingPercentEncodingEx ?? ""
        if let truple = req.getError(byReqId: errReqId) {
            context.setError(req:req, errorTruple: truple)
        }
        
        switch req.url.path.asNormalizedPathOnly().lastPathComponent().trimming(string: "/") {
        case "login":
            dboardLoginPage(req, context: context)
        default:
            break
        }
        
        let futureView = req.view.render(req.url.path, context)
        futureView.whenComplete { result in
            // req.routeHistory?.update(req: req, result: result)
        }
        
        return futureView
    }
    
    func dboardHome(_ req: Request) -> EventLoopFuture<View> {
        
        // Context
        let context = prepContext(req)
        let futureView = req.view.render("/\(basePath.description)/main", context)
        futureView.whenComplete { result in
            req.routeHistory?.update(req: req, result: result)
        }
        return futureView
    }
    
    func dboardErrorPage(_ req: Request) -> EventLoopFuture<View> {
        // dlog?.info("dboardErrorPage query: \(req.url.query.descOrNil)")
        
        let allParams : [String:String] = [:] // = req.collatedAllParams()
        if Debug.IS_DEBUG {
            if (allParams.count > 0) {
                dlog?.info("dboardErrorPage collatedAllParams: \(allParams.descriptionLines)")
            }
        }
        
        let errReqId = allParams["req"]?.removingPercentEncodingEx ?? ""
        
        // Get latest context:
        let context = prepContext(req)
        if let truple = req.getError(byReqId: errReqId) {
            context.setError(req:req, errorTruple: truple)
        }
        
        let futureView = req.view.render("/\(basePath.description)/\(Self.ERROR_PAGE_COMP)", context)
        futureView.whenComplete { result in
            switch result {
            case .success(let success):
                dlog?.info("\(Self.ERROR_PAGE_COMP) whenComplete success: \(String(describing:success))")
            case .failure(let err):
                dlog?.info("\(Self.ERROR_PAGE_COMP) whenComplete error: \(String(describing:err))")
            }
            
            // req.routeHistory?.update(req: req, result: result)
        }
        return futureView
    }
    
    // MARK: Web form [POST] - dashboard wraps API calls from the web pages only -
    // See: https://developer.mozilla.org/en-US/docs/Learn/Forms/Sending_and_retrieving_form_data
    // The POST PARAMETERS are encoded as queryParams, but is sent in the body
    /* Example for a BODY:
        name=testname&password=testpwd
    */
    
    // NOTE: We wrap the native UserConbtroller api to allow modularity and separation of responsibility between web forms requests and login/logout
    func dboardPOSTLogin(_ req: Request) async throws -> Response {
        // Redictect codes: force redirect:
        //   case .permanent 301  A cacheable redirect.
        //   case .normal    303  "see other" Forces the redirect to come with a GET, regardless of req method.
        //   case .temporary 307  Maintains original request method, ie: PUT will call PUT on redirect.
        let _ /*context*/ = self.prepContext(req)
        do {
            // TODO: should UserController be inited? should this be accessed via AppServer.user
            let response : UserController.UserLoginResponse
            if let userController = AppServer.shared.users {
                response = try await userController.login(req: req)
            } else {
                response = try await UserController(app:req.application).login(req: req)
            }
            
            req.routeHistory?.update(req: req, status: HTTPStatus.ok)
            dlog?.success("dboardPOSTLogin success: \(response.serializeToJsonString(prettyPrint: true).descOrNil)")
            return req.wrappedRedirect(to: "/\(basePath)/",
                                       type: .normal,
                                       params: [:],
                                       isShoudlForwardAllParams: false,
                                       contextStr: "DashboardController.dboardPOSTLogin login success redirects to dashboard main page")
        } catch let error {
            let code = AppError.bestErrorCode(error)
            let reason = AppError.bestErrorReason(error)
            let appError = AppError(AppErrorCode(rawValue: code)!, reason: reason)
            dlog?.fail("dboardPOSTLogin failed: error: \(code) \(reason)")
            throw appError // returns the error
            
//            switch code {
//            case _ where AppErrorCode.allUserLogin.intCodes.contains(code):
//                fallthrough
//            case _ where AppErrorCode.allUsername.intCodes.contains(code):
//                fallthrough
//            case 400..<499:
//                // Validation error in login page.
//                return req.wrappedRedirect(to: "/\(basePath)/login",
//                                           type:.normal,
//                                           toBase64: false,
//                                           params: ["req":req.requestUUIDString],
//                                           errorToForward: appError,
//                                           isShoudlForwardAllParams: false,
//                                           contextStr: "Validation error in login page.")
//            default:
//                // Major error in login page
//                return try await self.dboardRedirectToErrorPage(req, error: error)
//            }
            
        }
    }
    
    func dboardPOSTLogout(_ req: Request) async throws -> Response {
        // Redictect codes: force redirect:
        //   case .permanent 301  A cacheable redirect.
        //   case .normal    303  "see other" Forces the redirect to come with a GET, regardless of req method.
        //   case .temporary 307  Maintains original request method, ie: PUT will call PUT on redirect.
        
        dlog?.info("dboardPOSTLogout call logout for user id: \(req.selfUserUUIDString.descOrNil)")
        do {
            // var response : UserController.UserLogoutResponse
            if let userController = AppServer.shared.users {
                _ = try await userController.logout(req: req)
            } else {
                _ = try await UserController(app:req.application).logout(req: req)
            }
            return req.wrappedRedirect(to: "/\(basePath)/",
                                       type: .normal,
                                       params: [:],
                                       isShoudlForwardAllParams: false,
                                       contextStr:"DashboardController.dboardPOSTLogout")
        } catch let error {
            return try await self.dboardRedirectToErrorPage(req, error: error)
        }
    }
    
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
                _ = try await UserController(app:req.application).createUser(request: req)
            }

            return req.wrappedRedirect(to: "/\(basePath)/",
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
