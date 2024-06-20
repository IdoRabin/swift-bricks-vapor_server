//
//  DashboardController.swift
//
//
//  Created by Ido Rabin for Bricks on 17/1/2024.
//
import Fluent
import Vapor
import MNUtils
import MNVaporUtils
import Logging

fileprivate let dlog : Logger? = Logger(label:"DashboardController")

struct DashboardController: RouteCollection, RouteCollectionPathable {
    // MARK: Consts
    static let PAGE_TITLE_PREFIX = "\(AppConstants.APP_DISPLAY_NAME.capitalized) dashboard"
    static let ERROR_PAGE_COMP = "error"
    static let FREE_PAGE_ROUTES      = ["about", "register", "login", "terms"] // excluded: main and erro. Note: login is the login page, not the login request
    static let PROTECTED_PAGE_ROUTES = ["logs", "roles" , "stats" , "terms", "users"]
    
    // MARK: AppRouteCollection
    var basePaths: [RoutingKit.PathComponent] = ["dashboard"]
    
    // MARK: Private
    // MARK: Lifecycle
    
    // MARK: Public Views
    func dboardHome(_ req: Request) async throws -> View {
        // let usr = req.auth.get(User.self)
        try await req.view.render("dashboard/main", DashboardContext(req: req))
    }
    
    func dboardTablePage(_ req: Request) async throws -> View {
        let relPath = req.url.url.relativePath.lowercased().trimmingPrefix("/")
        guard relPath.hasPrefix("dashboard") else {
            throw MNError(code: .http_stt_notFound, reason: "Dashboard path not found")
        }
        
        let tableView : FluentLeafTableview? = FluentLeafTableview.debugMock()
        
        do {
            return try await req.view.render(relPath, DashboardContext(req: req, tableView: tableView))
        } catch let error {
            dlog?.warning("Error while rendering tableView: \(String(describing: error))")
            throw MNError(code: .http_stt_internalServerError, reason: "Error rendering table".mnDebug(add: " for \(relPath)"), underlyingError: error)
        }
        
        // throw MNError(code: .http_stt_internalServerError, reason: "Unknown error rendering table / view in: \(relPath)")
    }
    
    func dboardRegularPage(_ req: Request) async throws -> View {
        let relPath = req.url.url.relativePath.lowercased().trimmingPrefix("/")
        guard relPath.hasPrefix("dashboard") else {
            throw MNError(code: .http_stt_notFound, reason: "Dashboard path not found")
        }
        
        return try await req.view.render(relPath, DashboardContext(req: req))
    }
    
    func dboardCatchallPage(_ req: Request) async throws -> View {
        if req.url.path.contains("dashboard/error") {
            // Allow "cath all" if the error page itself is not registered
        } else if req.application.routes.all.contains(where: { route in
            route.path.string == req.url.path
        }) {
            // Page route exists:
            dlog?.todo("Handle catchall for existing route?")
        } else {
            // Error 404
            throw MNError(code: .http_stt_notFound, reason: "Dashboard page not found")
        }
        
        // Should get here if route exists and no error?
        return try await req.view.render("dashboard/error", DashboardContext(req: req))
    }
    
    func dboardErrorPage(_ req: Request) async throws -> View {
        
        // We must ensure we have the error page in the history
        try req.routeHistory?.update(req: req, response: nil)
        
        return try await req.view.render("dashboard/error", DashboardContext(req: req))
    }
    
    func dboardLoginPage(_ req: Request) async throws -> View {
        return try await req.view.render("dashboard/login", DashboardContext(req: req))
    }
    
    // MARK: Public API
    func dboardLoginPost(_ req: Request) async throws -> Response {
        // TODO: Use route metadata to fetch the route not in a hard-coded way
        return req.redirect(to: "/" + AppConstants.API_PREFIX + "user/login", redirectType: .temporary)
    }
    
    func dboardLogoutPage(_ req: Request) async throws -> Response {
        return try await self.dboardLogoutPost(req)
    }
    
    func dboardLogoutPost(_ req: Request) async throws -> Response {
        let response = try await UserController().logout(req)
        dlog?.info("logout response: \(response.status)")
        
        response.status = .temporaryRedirect
        response.headers.replaceOrAdd(name: .location, value: "/dashboard/?ref=user_logged_out")
        return response
    }
    
    // MARK: Public RouteCollection
    func boot(routes: RoutesBuilder) throws {
        // Listed below are all the routing groups:
        let typeName = "\(Self.self)".padding(toLength: 20, withPad: " ", startingAt: 0)
        let groupTag = self.name // name allows to use in conincidence with the "tag" in OpenAPI to collate routes to groups
        dlog?.info("   \(typeName) boot tag/name: [\(groupTag)] base path: /\(self.basePath)")
        
        routes.groupEx(AccessToken.authenticator() /* optional, not required */,
                       path: self.basePath, configure: { dashboard in
            
            // Home page
            dashboard.get(use: dboardHome)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "Bricks dashboard",
                                      description: "Bricks dashboard home page",
                                      requiredAuth: .none))
            
            // NOTE: DO NOT Document in API!
            dashboard.get("error" ,use: dboardErrorPage)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "Bricks dashboard error",
                                      description: "Bricks dashboard error page",
                                      requiredAuth: .none))
            
            // FREE_PAGE_ROUTES "about", "register", "login"
            dashboard.get("about", use: dboardRegularPage)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "About Bricks dashboard",
                                      description: "About bricks dashboard web page",
                                      requiredAuth: .none))
            
            dashboard.get("register", use: dboardRegularPage)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "Register to Bricks dashboard",
                                      description: "Register to bricks dashboard web page as a new user",
                                      requiredAuth: .none))
            
            dashboard.get("terms", use: dboardRegularPage)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "Bricks dashboard Terms and Conditions",
                                      description: "Terms and Conditions for using the Bricks Dashboard. (contractual)",
                                      requiredAuth: .none))
            
            // Password - login
            dashboard.get("login", use: dboardLoginPage)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "Login to Bricks dashboard",
                                      description: "Login to bricks dashboard web page with an existing users credentials",
                                      requiredAuth: .none))
            
            dashboard.post("login", use: dboardLoginPost)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "Login to Bricks dashboard api",
                                      description: "Login to bricks dashboard POST api request with an existing users credentials",
                                      requiredAuth: .userPassword))
            
            // Logout
            dashboard.get("logout", use: dboardLogoutPage)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "Logout from Bricks dashboard",
                                      description: "Logout from bricks dashboard web page",
                                      requiredAuth: .userToken))
            
            dashboard.post("logout", use: dboardLogoutPost)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "Logout from Bricks dashboard api",
                                      description: "Logout from bricks dashboard POST api request for a logged in user.",
                                      requiredAuth: .userToken))
            
            // PROTECTED_PAGE_ROUTES = ["logs", "roles" , "stats" , "users"]
            dashboard.group(AccessToken.authenticator()) { protected in
                
                protected.group("profile") { profile in
                    
                    profile.get("edit", use: dboardRegularPage)
                        .metadata(MNRouteInfo(groupTag: self.name,
                                              productType: .webPage,
                                              title: "Dashboard Profile",
                                              description: "Edit the current dashboard profile",
                                              requiredAuth: .userToken))
                    
                    profile.get("settings", use: dboardRegularPage)
                        .metadata(MNRouteInfo(groupTag: self.name,
                                              productType: .webPage,
                                              title: "Dashboard Settings",
                                              description: "Dashboard settings for the current dashboard profile",
                                              requiredAuth: .userToken))
                }
                
                protected.get("logs", use: dboardTablePage)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                          productType: .webPage,
                                          title: "Dashboard Logs",
                                          description: "Logs report - view, search and export system logs",
                                          requiredAuth: .userToken))
                
                protected.get("roles", use: dboardRegularPage)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                          productType: .webPage,
                                          title: "Dashboard Roles",
                                          description: "Roles management - create, review, update and delete RBAC roles (access control)",
                                          requiredAuth: .userToken))
                
                protected.get("stats", use: dboardRegularPage)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                          productType: .webPage,
                                          title: "Dashboard Statistics",
                                          description: "Statistics management - view, search and export system statictics",
                                          requiredAuth: .userToken))
                
                protected.get("users", use: dboardTablePage)
                    .metadata(MNRouteInfo(groupTag: self.name,
                                          productType: .webPage,
                                          title: "Dashboard Users",
                                          description: "Users management - create, review, update and delete system Users.",
                                          requiredAuth: .userToken))
            }
            
            dashboard.get(.catchall, use: dboardCatchallPage)
                .metadata(MNRouteInfo(groupTag: self.name,
                                      productType: .webPage,
                                      title: "Dashboard error",
                                      description: "Dashboard Error page",
                                      requiredAuth: .none))
        })
    }
    
    
}
