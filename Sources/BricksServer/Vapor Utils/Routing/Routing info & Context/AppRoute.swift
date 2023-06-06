//
//  AppRoute.swift
//  
//
//  Created by Ido on 16/01/2023.
//

import Foundation

import DSLogger
import MNUtils

#if VAPOR
import Vapor
#endif

fileprivate let dlog : DSLogger? = DLog.forClass("AppRoute")

class AppRoute : AppRouteInfo {
    
    #if VAPOR
    weak var route : Vapor.Route? = nil
    #else
    weak var route : Any? = nils
    #endif
    
    #if VAPOR
    private init(empty:Any? = nil) {
        super.init()
    }
    
    convenience init(route:Vapor.Route) {
        self.init(empty:nil)
        self.fullPath = route.fullPath
        self.httpMethods.update(with: route.method)
        self.route = route
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    #endif
    
    private var isVaporAvailable : Bool {
        #if VAPOR
        return true
        #else
        return false
        #endif
    }
    
    func debugLogFindAndAssignVaporRoute (depth:Int) {
        if Debug.IS_DEBUG {
            let msg = ".findAndAssignVaporRoute(\(depth)/\(Self.MAX_FIND_VROUTE_RECURSIONS)). Still loading for \(self.fullPath.descOrNil)!"
            var flags : [String] = []
            if AppRoutes.isInitializing { flags.append("AppRoutes.isInitializing") }
            if AppServer.isInitializing { flags.append("AppServer.isInitializing") }
            if !AppServer.isInitializing {
                if AppServer.shared.isBooting { flags.append("AppServer.shared.isBooting") }
                if AppServer.shared.vaporApplication == nil { flags.append("AppServer.shared.vaporApplication == nil") }
            }
            if flags.count > 0 {
                dlog?.info(msg + "\n    failed test for \(self.fullPath.descOrNil): " + flags.descriptionsJoined)
            } else {
                dlog?.info(msg + " for \(self.fullPath.descOrNil) for unknown reasons!")
            }
            
        }
    }
    
    private static let MAX_FIND_VROUTE_RECURSIONS = 16
    func findAndAssignVaporRoute(depth:Int = 0) {
        guard self.isVaporAvailable else {
            return
        }
        
        guard depth < Self.MAX_FIND_VROUTE_RECURSIONS else {
            dlog?.info("AppRoutes recursion too deep!")
            return
        }
        
        guard !AppRoutes.isInitializing && !AppServer.isInitializing && !AppServer.shared.isBooting && AppServer.shared.vaporApplication != nil else {
            
            if Debug.IS_DEBUG {
                debugLogFindAndAssignVaporRoute(depth: depth)
            }
            
            AppServer.scheduleTask(delayFromNow: 0.05) {[self] in
                self.findAndAssignVaporRoute(depth: depth + 1)
            }
            return
        }
        
        #if VAPOR
        if let fpath = self.fullPath, fpath.count > 0 && self.route == nil {
            // Fill route from path
            if let route = AppServer.shared.vaporApplication?.routes.all.first(where: { route in
                route.fullPath.asNormalizedPathOnly() == fpath
            }) {
                self.route = route
                dlog?.success("findAndAssignVaporRoute assigned vapor route for path \(fpath)")
            } else if !AppServer.shared.isBooting {
                dlog?.note("findAndAssignVaporRoute failed to find vapor route for path \(fpath)")
            }
        } else if let route = self.route, self.fullPath?.count ?? 0 == 0 {
            // Fill path from route
            self.fullPath = self.route?.path.fullPath.asNormalizedPathOnly()
            dlog?.note("findAndAssignVaporRoute assigned full path \(self.fullPath.descOrNil) frmo route: \(route.description)")
        }
        #endif
    }
    
    @discardableResult
    func setting(routeInfo:AppRouteInfo)->AppRoute {
        dlog?.todo("AppRoute[\(self.fullPath.descOrNil)].setting(routeInfo:)")
        return self
    }
    
    @discardableResult
    func setting(dictionary : [AppRouteInfo.CodingKeys:Any])->AppRoute {
        dlog?.todo("AppRoute[\(self.fullPath.descOrNil)].setting(dictionary:)")
        return self
    }
}
