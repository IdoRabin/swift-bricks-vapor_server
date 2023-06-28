//
//  File.swift
//  
//
//  Created by Ido on 28/05/2023.
//

import Foundation
import Vapor
import Fluent
import FluentKit
import Leaf
import DSLogger
import MNUtils
import MNVaporUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppRoutingController")


protocol AppRouterable {
    var allRoutePaths : [String] { get }
    
    
    func setPermissions(paths:[String])
    func pathComp(_ sub: String)-> RoutingKit.PathComponent
    
    // Same paradism as LifecycleHandler
    func willBoot(_ application: Application)
    func boot(_ application: Application, routes: Vapor.RoutesBuilder) throws // Alos required by: ...
    func didBoot(_ application: Application)
    func shutdown(_ application: Application)
}

extension AppRouterable /* default implementations */  {
    func setPermissions(paths:[String]) {
        dlog?.note("\(Self.self) needs to override func setPermissions(paths:[String]) for its specific permissions")
    }
}

/// A subclassable route collection with app-specific util and convenience functions:
class AppRoutingController : NSObject/* to allow override of base class funcs in extensions */, RouteCollection, AppRouterable {
    
    // MARK: Const
    // MARK: Static
    
    // MARK: AppRouteManager - Indirect access to AppServer.shared.routes
    static var appRoutes : MNRoutes {
        return Vapor.Route.mnRouteManager
    }
    
    var appRoutes : MNRoutes {
        return Self.appRoutes
    }
    
    // MARK: Properties / members
    private var _prevRoutes : [String] = []
    private var _newRoutes : [String] = []
    
    // MARK: Computed Properties
    var allRoutePaths : [String] {
        return _newRoutes.removing(objects: _prevRoutes).uniqueElements()
    }
    
    var allAppRoutes : [MNRoute] {
        return appRoutes.listMNRoutes(forPaths: self.allRoutePaths)
    }
    
    var secureAppRoutes : [MNRoute] {
        return allAppRoutes.filter { route in
            route.isSecure
        }
    }
    
    /// Returns all the route paths that are NOT secured (route has no Rabac rules)
    var unsecureAppRoutes : [MNRoute] {
        return allAppRoutes.filter { route in
            !route.isSecure
        }
    }
    
    var allVaporRoutes : [Vapor.Route] {
        return appRoutes.listMNRoutes(forPaths: self.allRoutePaths).compactMap { appRoute in
            return appRoute.route
        }
    }
    
    var secureVaporRoutes : [Vapor.Route] {
        return allAppRoutes.filter { route in
            route.isSecure
        }.compactMap { appRoute in
            return appRoute.route
        }
    }
    
    /// Returns all the route paths that are NOT secured (route has no Rabac rules)
    var unsecureVaporRoutes :  [Vapor.Route] {
        return allAppRoutes.filter { route in
            !route.isSecure
        }.compactMap { appRoute in
            return appRoute.route
        }
    }
    
    /// Returns all the route paths that are secured (route has at least one Rabac rule)
    var secureRoutePaths : [String] {
        return [] // TODO: secureAppRoutes.fullPaths
    }
    
    /// Returns all the route paths that are NOT secured (route has no Rabac rules)
    var unsecureRoutePaths : [String] {
        return [] // TODO: unsecureAppRoutes.fullPaths
    }
    
    // MARK: Private
    
    // MARK: Lifecycle
    
    // MARK: AppRoutingControllable
    func willBoot(_ application: Application) {
        // TODO:
//        self._prevRoutes = AppServer.shared.vaporApplication?.routes.all.map { route in
//            return route.path.fullPath
//        }.uniqueElements() ?? []
    }
    
    func didBoot(_ application: Application) {
        // TODO:
//        self._newRoutes = AppServer.shared.vaporApplication?.routes.all.map { route in
//            return route.path.fullPath
//        }.uniqueElements() ?? []
    }
    
    // MARK: RouteCollection
    func boot(_ application: Application, routes: Vapor.RoutesBuilder) throws {
        // TODO: dispatch once per instance
        dlog?.info("\(Self.self) should implement boot(routes: Vapor.RoutesBuilder), no need to call super!")
    }

    func boot(routes: Vapor.RoutesBuilder) throws {
        guard let app = AppServer.shared.vaporApplication else {
            let msg = "boot(routes:) failed: AppServer vaporApplication is nil."
            dlog?.warning(msg)
            throw AppError(code: .misc_failed_loading, reason: msg)
        }
        try boot(app ,routes: routes)
    }
    
    func shutdown(_ application: Application) {
        dlog?.note("IMPLEMENT shutdown for AppRoutingController")
    }
    
    // MARK: Public
//    func vaporRoutes(forPaths paths:[String])->[Vapor.Route] {
//        let result : [Vapor.Route] = AppServer.shared.vaporApplication?.routes.all.filter({ route in
//            paths.contains(route.path.fullPath)
//        }) ?? []
//        return result
//    }
//
//    func vaporRoutes()->[Vapor.Route] {
//        let result : [Vapor.Route] =  AppServer.shared.vaporApplication?.routes.all ?? []
//        return result
//    }
    
//    func appRouteInfos()->[String:[AppRouteInfo]] {
//        let result = AppServer.shared.routes.listAppRoutes(forPaths: self.allRoutePaths.uniqueElements()).groupBy { element in
//            element.fullPath
//        }
//        return result
//    }
    
    fileprivate static let STR_OPTL = "Optional("
    
    /// returns a dictionary of all rabacRules applicable for each route path
    /// - Returns: dictionary of route path as key, and array of ranacRules as value
    // * Uncomment
    // Uncomment:
    /*
    func appRouteRabacRules()->[String /* route path */ :[RabacRule]] {
        var result : [String:[RabacRule]] = [:]
        for appRoute in AppServer.shared.routes.listAppRoutes(forPaths: self.allRoutePaths.uniqueElements()) {
            // let fpath = appRoute.fullPath?.asNormalizedPathOnly()
            let rules = Rabac.shared.rules(byNames: appRoute.rulesNames)
            let resourcePrefix = RabacResource.className() + "."
            for rule in rules {
                if let paths = rule.resourcesWanted?.map({ str in
                    return str.replacingOccurrences(of: resourcePrefix, with: "")
                }) {
                    for path in paths {
                        var arr : [RabacRule] = result[path] ?? []
                        if !arr.contains(rule) {
                            arr.append(rule)
                            result[path] = arr
                        }
                    }
                }
            }
        }
        return result
    }
    */
    
    
    @objc
    open dynamic func setPermissions(paths:[String]) throws {
        let msg = "AppRoutingController \(Self.self) needs to implement setPermissions(paths:)"
        dlog?.note(msg)
        throw AppError(code:.misc_failed_crypto, reason: msg)
    }
    
    /// Convenience metod - returns a Vapor.PathComponent initilaized to the given string
    /// - Parameter string: string for the path component
    /// - Returns: a Vapor.PathComponents pointing to the given string
    func pathComp(_ sub: String)->RoutingKit.PathComponent {
        return PathComponent(stringLiteral: sub)
    }
    
    
    // TODO: Check and remove this func because it duplicates StringEx.asQueryParams() with less ability. mimics
    /*
    static /* protected */ func urlQueryToDict(quesryString queryStr:String)->[String:String] {
        var queryStrings : [String: String] = [:]
        let str = queryStr.removingPercentEncodingEx
        for pair in (str ?? queryStr).components(separatedBy: "&") {
            if pair.count >= 1 {
                let tuple = pair.components(separatedBy: "=")
                let key   = tuple[0]
                let value = tuple[1].replacingOccurrences(
                    // Un-Percent Esacpe:
                    ofFromTo: ["+" : " ",
                               "%20" : " ",
                               "%7c" : "|",
                               "%3d" : "=",
                               "%03d" : "="], caseSensitive: false)
                    .removingPercentEncodingEx ?? ""
                queryStrings[key] = value
            }
        }
        return queryStrings
    }
    */
}
