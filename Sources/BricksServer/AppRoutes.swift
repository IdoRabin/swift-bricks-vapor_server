// AppRouteManager.swift

import Fluent
import Vapor
import NIO
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("Routes")?.setting(verbose: false)

protocol AppRouteManager {
    // Get Info:
    func listAllVaporRoutes()->[Vapor.Route]
    func listAllAppRoutes(isDoLogging:Bool)->[AppRoute]
    func listAppRoutes(forPaths:[String])->[AppRoute]
    func listAppRoutes(forVaporRoutes:[Vapor.Route])->[AppRoute]
    func isRouteRegistered(appRoute:AppRoute, context:String?)->Bool
    
    // Take action:
    func clearAllRoutes()
    func registerRouteIfNeeded(appRoute:AppRoute)
    func bootRoutes(_ app: Application) throws
    func secureRoutes(_ app: Application)
    func secureRoutesAfterBoot(_ app: Application)
}


// Configure the server main routes using "Controllers" : AppRoutingController (s)
class AppRoutes : AppRouteManager, LifecycleBootableHandler {
    
    
    // Files with extensions -
    @AppSettable(name: "AppRoutes.allowedByPathComponents", default: [
        "/images"           : ["ico", "jpg", "png", "gif", "tiff", "jpeg", "mpg", "mpeg"],
        "/web_scripts"      : ["js"],
        "/css"              : ["css"],
        "/bricks_templates" : ["brick"],
        "/"                 : [""],
    ])
    
    static var APP_ROUTES_ALLOWED_PATH_COMPONENTS : [String/* folder, path */:[/* allowed file extensions*/ String]]
    static let APP_ROUTES_LOG_WHEN_SECURING = Debug.IS_DEBUG && false
    
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    // private var all_routes : [String:AppRoute] = [:]
    private let appRoutes = MNCache</* full path */ String, AppRoute>(name: "AppRoutes", maxSize: 12000, flushToSize: 8000, attemptLoad: .immediate)
    private var routingControllers : [AppRoutingController] = []
    private (set) var isBooting = true
    static private (set) var isInitializing = true
    init() {
        Self.isInitializing = true
    }
    
    static func normalizedRoutePath(_ str:String)->String {
        return str // UNCOMMENT .trimmingPrefix("\(RabacResource.self).").asNormalizedPathOnly()
    }
    
    // MARK: AppRouteManager - Indirect access to AppServer.shared.routeMgr
    fileprivate static var appRouteManager : AppRouteManager {
        return  AppServer.shared.routeMgr
    }
    
    fileprivate var appRouteManager : AppRouteManager {
        return Self.appRouteManager
    }
    
    // MARK: Private
    @discardableResult
    private func validateRoutesSecurityCounts(controller:AppRoutingController, context:String)->AppResult<Int> {
        // UNCOMMENT
        return .failure(code: .misc_security,  reason: "Security check failed. RE-IMPLEMENT  validateRoutesSecurityCounts(controller:context")
        /*
        let unsecure:[String] = controller.unsecureRoutePaths
        let secure:[String] = controller.secureRoutePaths

        if secure.count == controller.allRoutePaths.count && unsecure.count == 0 {
            // Totally secured
            dlog?.verbose(log: .success, "validateRoutesAreSecure: [\(controller.className)] all routes are secure! ctx: \(context)")
            return .success(secure.count)
        } else {
            // Partially / not secured
            let routes : [AppRoute] = self.appRoutes.listAppRoutes(forPaths: unsecure)
            dlog?.warning("   validateRoutesAreSecure \(controller.className): ONLY \(secure.count)/\(unsecure.count + secure.count) routes are secure! ctx: \(context).\n\(unsecure.count) remain to be secured: \(routes.descriptionLines)")
            
            for route in routes {
                let isInCache = self.appRoutes[route.fullPath ?? ""]  === route
                dlog?.info("\(route.fullPath.descOrNil)\t\tisInCache: \(isInCache)")
            }
            
            return .failure(code: .misc_security,  reason: "Security check failed. " + Debug.StringOrEmpty("validateRoutesAreSecure for [\(controller.className)] failed w/ \(unsecure.count) unsecure routes! ctx: \(context)"))
        } */
    }
    
    private func validateRoutesSecurity(_ app: Application, isAfterBoot:Bool = false)->SecuredResCounts {
        
        let stt = isAfterBoot ? "after boot" : "during boot"
        let vaporRoutesCount = AppServer.shared.vaporApplication?.routes.all.count ?? 0
        dlog?.verbose("  secureRoutesValidations \(stt) for \(vaporRoutesCount) vapor routes")
        
        // Validate / Log / find unsecured routes / infos
        var isFailure = false
        var totalSecuredCount = 0
        var totalRoutesCount = 0
        var totalRoutesCountWMethods = 0 // will count additional HTTP methods as more routes..
        for controller in routingControllers {
            totalSecuredCount += self.validateRoutesSecurityCounts(controller: controller, context:"secureRoutes").successValue ?? 0
            let allAppRoutes = controller.allAppRoutes
            totalRoutesCount += allAppRoutes.count
            totalRoutesCountWMethods += allAppRoutes.count
            for appRoute in allAppRoutes {
                if appRoute.httpMethods.count > 1 {
                    totalRoutesCountWMethods += Swift.max(appRoute.httpMethods.count - 1, 0)
                }
            }
        }
        
        isFailure = totalSecuredCount < totalRoutesCount
        if Debug.IS_DEBUG && vaporRoutesCount > totalRoutesCount {
            // We add for each HTTP call method:
            if totalRoutesCountWMethods == vaporRoutesCount {
                if Self.APP_ROUTES_LOG_WHEN_SECURING {
                    dlog?.info("  \(String.CRLF_KEYBOARD_SYMBOL) some routes have multiple HTTP methods: (\(totalRoutesCountWMethods)/\(vaporRoutesCount)) are secure")
                }
                isFailure = false
            } else {
                dlog?.warning("  * some routes have multiple HTTP methods: (\(totalRoutesCountWMethods)/\(vaporRoutesCount)) MISMATCHED COUNTS!")
                isFailure = true
            }
        }
        
        return SecuredResCounts(totalSecuredCount: totalSecuredCount,
                                totalRoutesCount: totalRoutesCount,
                                error: isFailure ? AppError(code:.misc_security, reason: "Failed securing routes" + Debug.StringOrEmpty(" .secureRoutesValidationsד test failed.")) : nil)
    }
    
    // MARK: Lifecycle
    private struct SecuredResCounts : Error {
        let totalSecuredCount : Int
        let totalRoutesCount : Int
        let error : AppError?
        
        var isSuccess : Bool {
            return (error == nil) && (totalSecuredCount == totalRoutesCount)
        }
    }
    
    func secureRoutes(_ app: Application) {
        let vaporRoutesCount = AppServer.shared.vaporApplication?.routes.all.count ?? 0
        let slog : DSLogger? = Self.APP_ROUTES_LOG_WHEN_SECURING ? dlog : nil
        slog?.todo("> Securing routes during boot START")
        /* uncomment:
        slog?.info("> Securing routes during boot START (securing \(Rabac.shared.elements.count) elements to \(vaporRoutesCount) vapor routes loaded.)")
        do {
            for controller in routingControllers {
                // Register all permissions for each controller:
                slog?.verbose("> Securing routes during boot for [\(controller.className)] ")
                let paths = controller.allRoutePaths.map { Self.normalizedRoutePath($0) }
                if paths.count > 0 {
                    let permsStartCount = Debug.IS_DEBUG ? controller.appRouteRabacRules().sumValuesCounts : 0
                    // Will set permissions at the controller level using setPermissions(paths:)
                    try controller.setPermissions(paths:paths)
                    
                    // Post secure checks: - will list the set rules for each route:
                    if slog != nil && Debug.IS_DEBUG {
                        let perms = controller.appRouteRabacRules()
                        let permsEndCount = Debug.IS_DEBUG ? perms.sumValuesCounts : 0
                        if permsStartCount != permsEndCount {
                            slog?.verbose(log:.success, "> Securing routes during boot. ontroller \(type(of:controller)) did secure \(permsEndCount - permsStartCount) new routes (total: \(permsEndCount))")
                        } else if permsEndCount == 0 && permsStartCount == 0 {
                            dlog?.note("> Securing routes during boot. Controller \(type(of:controller)) did not secure ANY routes AND contains / loaded \(permsEndCount) rules")
                        } else {
                            slog?.verbose(log:.success, "> Securing routes during boot .Controller \(type(of:controller)) did not secure any NEW routes! (existing: \(permsEndCount) secured)") //  \n\(perms.descriptionLines)"..
                        }
                    }
                } else {
                    dlog?.note("> Securing routes during boot. Controller \(type(of:controller)) did not register any routes!")
                }
            }
            
            appRoutes.saveIfNeeded()
            Rabac.shared.saveIfNeeded()
            
            // Stats and validations
            let validation = self.validateRoutesSecurity(app, isAfterBoot: false)
            if Self.APP_ROUTES_LOG_WHEN_SECURING {
                dlog?.successOrFail(condition: validation.isSuccess, "Securing routes during boot END. error: \(validation.error.descOrNil) counts: \(validation.totalSecuredCount)/\(validation.totalRoutesCount)")
            }
        } catch let error {
            dlog?.warning("secureRoutes threw error:\(error.description)")
        }
         */
    }
    
    func secureRoutesAfterBoot(_ app: Application) {
        if Self.APP_ROUTES_LOG_WHEN_SECURING {
            dlog?.info("> Securing routes after boot START")
        }
        
        // Stats and validations
        let validation = self.validateRoutesSecurity(app, isAfterBoot: true)
        
        // JIC
        self.isBooting = false
        Self.isInitializing = false
        
        
        // UNCOMMENT: Rabac.shared.updateMaps()
        
        appRoutes.saveIfNeeded()
        // UNCOMMENT: Rabac.shared.saveIfNeeded() // Will save only if not booting...
        /* UNCOMMENT:
        if Debug.IS_DEBUG {
            if Rabac.shared.elements.count == 0 {
                dlog?.warning("Securing routes after boot END. error: Rabac.shared.elements is empty!!")
            } else if Self.APP_ROUTES_LOG_WHEN_SECURING {
                dlog?.successOrFail(condition: validation.isSuccess, "Securing routes after boot END. error: \(validation.error.descOrNil) validation counts: \(validation.totalSecuredCount)/\(validation.totalRoutesCount)")
            }
        }*/
    }
    
    // LifecycleBootableHandler
    func boot(_ app: Vapor.Application) throws {
        try self.bootRoutes(app)
    }
    
    func bootRoutes(_ app: Vapor.Application) throws {
//        DispatchQueue.main.performOncePerInstance(self) {
//            dlog?.info("> Booting all veapor / app routes")
//
//            // UNCOMMENT: Rabac.shared.setupIfNeeded() // this will call in turn .setupAppExIfNeeded for Rabac. (Should set "global" rules there)
//
//            // : [AppRoutingController]
//            self.routingControllers  = [
//    //            DashboardController(),
//    //            UserController(),
//    //            UtilController(),
//            ]
//
//            // Register all routingControllers:
//            // Register all controllers:
//            for controller in routingControllers {
//                controller.willBoot(app)
//                try app.register(collection: controller)
//                controller.didBoot(app)
//            }
//
//            // Finally, server is initialized now:
//            NSLog("\nFinished AppRoutes.boot\n")
//        }
    }
    
    func shutdown(_ app: Application) {
        dlog?.info("> Booting all veapor / app routes")
        
        // UNCOMMENT: Rabac.shared.setupIfNeeded() // this will call in turn .setupAppExIfNeeded for Rabac. (Should set "global" rules there)
        
        // : [AppRoutingController]
        
        
        // Register all routingControllers:
        // Register all controllers:
        for controller in routingControllers {
            controller.shutdown(app)
        }
        
        // Finally, server is initialized now:
        self.routingControllers  = []
    }
    // MARK: Public RoutesInfos
    func listAllVaporRoutes()->[Route] {
        return AppServer.shared.vaporApplication?.routes.all ?? []
    }
    
    func listAllAppRoutes(isDoLogging:Bool = false)->[AppRoute] {
        var appRInfoByPath : [String:AppRoute] = [:]
        
        func biggerString(s1:String,s2:String)->String {
            return s1.count > s2.count ? s1 : s2
        }
        
        // We keep only one route info for each exact full path,
        // and collate all the HTTPMethods it allows:
        typealias CKey = RouteInfoCodingKeys
        let vaporRoutes : [Vapor.Route] = self.listAllVaporRoutes()
        for vaporRoute : Vapor.Route in vaporRoutes {
            
            let vdesc = vaporRoute.description
            var fullpath = biggerString(s1:vdesc.components(separatedBy: " /").last!, s2: vaporRoute.path.fullPath)
            fullpath = AppRoutes.normalizedRoutePath(fullpath)
            
            var appRoute = appRoutes.value(forKey: fullpath)
            if appRoute == nil {
                appRoute = vaporRoute.appRoute
                dlog?.warning(".getAppRoutesList() Route \(fullpath) was not registered in time!")
            }
            
            dlog?.warning("UNCOMMENT and re-implemnt RABAC in listAllAppRoutes")
            /* UNCOMMENT:
            let elemName = RabacResource.compoundName(fullpath)
            let elem = RabacElement.getExistingElement(elemName)
            if (appRoute !== vaporRoute.appRoute) {
                dlog?.warning("multiple instances routes for: \(fullpath)")
                dlog?.warning("      vaporRoute.appRoute : \(vaporRoute.appRoute)")
                dlog?.warning("           RabacElement[] : \(elem.descOrNil)")
            }
             */
            
            if let appRoute = appRoute, appRInfoByPath[fullpath] == nil {
                appRInfoByPath[fullpath] = appRoute
            }
            
            /*
             UNcomment
             if Debug.IS_DEBUG && isDoLogging {
                 if let appRoute = appRoute {
                     let hasPerm = appRoute.rulesNamesOrNil != nil ? "✅" : "❌" // or user the less distracting: "✓" : "✘"
                     dlog?.info(".getAppRoutesList() route: \(vaporRoute) | appInfo:\(appRoute.groupName.descOrNil) | \(appRoute.title.descOrNil) Permissions: \(hasPerm) methods: \(appRoute.httpMethods.descriptions().descriptionsJoined)")
                 } else {
                     dlog?.warning(".getAppRoutesList() Route \(fullpath) was not registered in time!")
                 }
             }
             */
        }
        
        // NOTE: For various reasons appRInfoByPath.count may be smaller than vaporRoutes.count, that may be a valid state.
        return appRInfoByPath.valuesArray
    }
    
    func listAppRoutes(forVaporRoutes vroutes:[Vapor.Route])->[AppRoute] {
        guard vroutes.count > 0 else {
            dlog?.note("listAppRoutes(forVaporRoutes:) parameter is empty (0 items to find)")
            return  []
        }
        let allVPaths = vroutes.fullPaths
        let allAPaths = self.listAllAppRoutes().fullPaths
        
        let foundPaths = allVPaths.intersection(with: allAPaths)
        if foundPaths.count > 0 {
            return self.listAppRoutes(forPaths: foundPaths)
        } else {
            dlog?.note("listAppRoutes(forVaporRoutes:) found 0 elements for: \(vroutes.descriptionLines)")
        }
        
        return []
    }
    
    func listAppRoutes(forPaths ipaths:[String])->[AppRoute] {
        guard ipaths.count > 0 else {
            dlog?.note("listAppRoutes(forPaths:[]) recieved 0 paths to list!")
            return []
        }
        
        // Revert from rabac name:
        var paths = ipaths.map { str in
            return AppRoutes.normalizedRoutePath(str)
        }.uniqueElements()
        
        if Debug.IS_DEBUG && paths.count == 0 {
            dlog?.note("listAppRoutes(forPaths:[]) recieved \(ipaths.count) paths, but normalized to 0 paths to list!")
            return []
        }
        
        var result : [AppRoute] = appRoutes.values(forKeys: paths).valuesArray
        if result.count <= paths.count {
            // We will check only the missing paths:
            paths = paths.removing(objects: result.fullPaths)
        }
        
        // Iterate for the remaining missing paths
        // UNCOMMENT:
        /*
        if /* remaining */ paths.count > 0  {
            dlog?.info("listAppRoutes(forPaths:[]) Adding all missed - listing and adding appRoutes to the cache")
            let allAppRoutes = self.listAllAppRoutes()
            
            // Add to cache if needed
            self.appRoutes.add(dictionary: allAppRoutes.toDictionary(keyForItem: { element in
                element.fullPath
            }))
            
            for path in paths {
                // See also: RabacElement.find(forPathExpression:isCaseSensitive)
                if path.trimming(string: "/").hasSuffix(RabacResource.Catchall.any.rawValue) {
                    
                    // This path is the catchall *** All routes path:
                    dlog?.info("listAppRoutes(forPaths:[])      *** (Catchall)")
                    result = allAppRoutes
                    // no need to continue.. all routes are added...
                    break
                    
                } else if path.hasSuffix(RabacResource.Catchall.subs.rawValue) {
                    
                    // This path is a catchall ** for subroutes of a given route. Typically the root path of a controller / area:
                    dlog?.info("listAppRoutes(forPaths:[])      \(path)")
                    let catcher = path.trimming(string: RabacResource.Catchall.subs.rawValue)
                    let routes = allAppRoutes.compactMap { aroute in
                        if aroute.fullPath?.hasPrefix(catcher) ?? false {
                            return aroute
                        }
                        return nil
                    }
                    result.append(contentsOf: routes)
                    
                } else if path.contains(anyOf: [
                    RabacResource.Catchall.manyChars, RabacResource.Catchall.oneChar]
                    .rawValues) {
                    
                    // All routes for regexes matching [*, ?]
                    dlog?.info("listAppRoutes(forPaths:[])      \(path)")
                    let resourceNames = RabacResource.find(forPathExpression: path)
                    let appRoutes = self.listAppRoutes(forPaths: resourceNames)
                    if (Debug.IS_DEBUG && !self.isBooting) && (appRoutes.count < resourceNames.count || resourceNames.count == 0) {
                        dlog?.warning("AppRoute \(path) does NOT have an equivalent RabacResource or resource name!")
                    }
                    result.append(contentsOf: appRoutes)
                    
                } else {
                    
                    // Find routes by containing any of given paths
                    // DO NOT: let rname = RabacResource.find(anyOfNameFragments: [path]) - because it creates
                    dlog?.info("listAppRoutes(forPaths:[])      path: \(path)")
                    let rname = RabacResource.compoundName(path)
                    let appRoutes = allAppRoutes.filter({ appRoute in
                        if appRoute.fullPath?.contains(path) ?? false {
                            if Debug.IS_DEBUG && !self.isBooting && RabacResource.getExistingElement(rname) == nil {
                                dlog?.warning("AppRoute \(appRoute.fullPath.descOrNil) does NOT have an equivalent RabacResource!")
                            }
                            return true
                        }
                        return false
                        
                    })
                    
                    result.append(contentsOf: appRoutes)
                }
            }
        } // End of loop */

        result = result.uniqueElements()

        if Debug.IS_DEBUG && result.count < paths.count {
            if paths.uniqueElements().count < paths.count {
                dlog?.warning(".getAppRoutesFor(paths: \(ipaths.descriptionsJoined)) Some input paths are duplicate: \(paths.sorted().descriptionLines)")
            }
            
            let requiringInfo = paths.removing(objects: result.compactMap{ $0.fullPath }).sorted()
            if requiringInfo.count > 0 && !self.isBooting {
                dlog?.warning(".getAppRoutesFor(paths: \(ipaths.descriptionsJoined)) Some paths do not have route infos! (AppRoute) requiringInfo: \(requiringInfo.debugDescriptions().descriptionLines)\n for paths:\(paths.descriptionLines)")
            }
        }
        
        return result
    }

    // MARK: Public Routes management
    func clearAllRoutes() {
        self.appRoutes.clear()
    }
    
    func registerRouteIfNeeded(appRoute:AppRoute) {
        guard let fpath = appRoute.fullPath?.asNormalizedPathOnly(), fpath.count > 0 else {
            dlog?.warning("registerRouteIfNeeded(appRoute:) faield for path is empty or nil!")
            return
        }
        self.appRoutes[fpath] = appRoute
        if Debug.IS_DEBUG {
            // ?
        }
    }
    
    func isRouteRegistered(appRoute:AppRoute, context:String? = nil)->Bool {
        guard let fpath = appRoute.fullPath?.asNormalizedPathOnly(), fpath.count > 0 else {
            dlog?.warning("isRouteRegistered(appRoute: \(context ?? "") failed for path is empty or nil!")
            return false
        }
        var result = false
        let lroute = self.appRoutes[fpath]
        if let lroute = lroute {
            result = (lroute == appRoute)
        }
        
        if Debug.IS_DEBUG && !result {
            // ↳ arrow down and right
            // ↳ return
            if let lroute = lroute {
                let cr = String.CRLF_KEYBOARD_SYMBOL
                dlog?.warning("""
isRouteRegistered(appRoute: \(context ?? "")) failed for:
    \(cr) \(String(memoryAddressOf:appRoute)) \(appRoute.description)
    \(cr) \(String(memoryAddressOf:lroute)) \(lroute.description)
""")
            } else {
                // case when  lroute == nil
                dlog?.warning("isRouteRegistered(appRoute: \(context ?? "")) failed: no route for: \(fpath)")
            }
        }
        return result
    }
}
