//
//  VaporRouteEx.swift
//  
//
//  Created by Ido on 01/02/2023.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("VaporRouteEx")

// Convenience, Brevity
// MARK: Vapor.Route extension {
extension Vapor.Route {
    
    // MARK: extending new computed Properties
    
    
    /// Full path for the Vapor route, formatted and normalized as path only
    var fullPath : String {
        return self.path.fullPath.asNormalizedPathOnly()
    }
    
    /// Returns an AppRoute instance for the Vapor.Route. (instances are unique and kept in the AppRoutes cache as implementor of AppRouteManager)
    var appRoute  : AppRoute {
        get {
            return self.get(orMake:{AppRoute(route: self)})
        }
        // set {
            // ... registerRouteIfNeeded(route:AppRoute) {
        //    self.userInfo = newValue.asDict()
        // }
    }
    
    // MARK: AppRouteManager - Indirect access to AppServer.shared.routes
    static var appRoutes : AppRoutes {
        return AppServer.shared.routeMgr
    }
    
    var appRoutes : AppRoutes {
        return Self.appRoutes
    }
    
    // MARK: Private
    func debugValidateAppRoute(context:String) {
        guard Debug.IS_DEBUG else {
            return
        }
        
        let fpath = self.fullPath
        guard fpath.count > 0 else {
            dlog?.warning("debugValidateAppRoute [\(context)] has no path! (will set \(fpath)) context: \(context)")
            return
        }
        
        if let _ /*appRoute*/ = appRoutes.listAppRoutes(forPaths: [fpath]).first {
            // Found route...
        } else {
            dlog?.warning("debugValidateAppRoute [\(context)] failed finding AppRoute info for path: \(fpath)")
        }
    }
    
    fileprivate func get(orMake createBlock:()->AppRoute)->AppRoute {
        // Get
        //dlog?.info("get(orMake: \(self.fullPath))")
        
        var result = appRoutes.listAppRoutes(forPaths: [self.fullPath]).first
        
        // Or make:
        if result == nil {
            result = createBlock()
            appRoutes.registerRouteIfNeeded(appRoute: result!)
        }
        
        // In any case we setup the retrieved AppRoute in case it isn't fully set up:
        if let result = result {
            result.route = self
            
            var dbgFields : [String]? = Debug.IS_DEBUG ? [] : nil
            
            if (result.fullPath.isNilOrEmpty) {
                result.fullPath = self.fullPath
                dbgFields?.append("fullPath:\(self.fullPath)")
            }
            
            if result.title.isNilOrEmpty {
                result.title = self.fullPath.lastPathComponents(count: 2)
                dbgFields?.append("title:\(result.title.descOrNil)")
            }
            
            if !result.httpMethods.contains(self.method) {
                result.httpMethods.update(with: self.method)
                dbgFields?.append("method:\(self.method.string)")
            }
            
            if Debug.IS_DEBUG, let dbgFields = dbgFields, dbgFields.count > 0 {
                dlog?.note("get(orMake:\(self.fullPath) updated fieldsa: \(dbgFields.descriptionsJoined)")
            }
        }
        
        // Will crash
        return result!
    }
    
    // MARK: Public
    @discardableResult
    func setting(productType : RouteProductType = .apiResponse,
                 title:String,
                 description newDesc: String? = nil,
                 requiredAuth : AppRouteAuth = .bearerToken,
                 group:String? = nil)->Route {
       // dlog?.todo("Route[\(self.fullPath)].setting(productType:title:desc:reqAuth:group)")
        let appRoute = self.get(orMake:{AppRoute(route: self)})
        appRoute.productType = productType
        appRoute.title = title
        appRoute.desc = newDesc ?? appRoute.desc
        appRoute.requiredAuth = requiredAuth
        appRoute.groupName = appRoute.groupName ?? group
        debugValidateAppRoute(context: ".setting (productType:title:desc:reqAuth:group)")
        return self
    }
    
    @discardableResult
    func setting(routeInfoable:any AppRouteInfoable)->Route {
        return self.setting(dictionary: routeInfoable.asDict() as? [AppRouteInfo.CodingKeys:Any] ?? [:])
    }
    
    @discardableResult
    func setting(dictionary : [AppRouteInfo.CodingKeys:Any])->Route {
        guard dictionary.count > 0 else {
            return self
        }
        
        let appRoute = self.appRoute
        appRoute.update(with: dictionary)
        self.userInfo = appRoute.asDict()
        appRoutes.registerRouteIfNeeded(appRoute: appRoute)
        debugValidateAppRoute(context: ".setting (dictionary:)")
        
        return self
    }
}


extension Vapor.Route /* Rabac rules */ {
//    func setting(rules : [RabacRule]) {
//        let appRoute = self.get(orMake:{AppRoute(route: self)})
//        dlog?.todo("Route[\(self.fullPath)].setting(rules:) appRoute:\(appRoute)")
//        
////        let info = self.appRouteInfo
////        if info.isSecure ? ?? ? info.rulesNames.count > rules.count {
////            dlog?.warning("setting(rules) will reduce rules.count to: \(info.rulesNames.count)")
////        }
////        info.rulesNames =  rules.rabacNames
////        dlog?.info("\(self.fullPath).info setting(rules: \(info.rulesNames.descriptionsJoined))")
////        self.setting(routeInfo: info)
////        appRouteManager.registerRouteIfNeeded(route: self)
////        self.debugValidateAppRoute(context: "Route.setting(rules:)")
////
////        if self.fullPath.contains("/login") {
////            dlog?.info(" setting(rules) - \(rules.rabacNames.descriptionsJoined)")
////        }
//    }
}

extension Sequence where Element == Vapor.Route {
    var fullPaths : [String] {
        return self.compactMap { route in
            return route.fullPath
        }
    }
}
