//
//  UtilController.swift
//
//
//  Created by Ido Rabin for Bricks on 17/1/2024.
//
import Fluent
import Vapor
import MNVaporUtils
import Logging

fileprivate let dlog : Logger? = Logger(label:"UtilController")

struct UtilController: RouteCollection, RouteCollectionPathable {
    // MARK: AppRouteCollection
    var basePaths: [RoutingKit.PathComponent] = ["util"]
    
    // MARK: API funcs
    func listAllRoutes(_ req:Request) async throws -> Response {
        let result = Response.NotImplemented(description: "Utils.listAllRoutes not implemented yet").enrichAsAppEncodableVaporResponse(request: req)
        return result
    }
    
    func optionsCheck(_ req:Request) async throws -> Response {
        return Response(status: .ok, version: .http1_1, headers: HTTPHeaders([]), body: "")
//        let result = Response.NotImplemented(description: "Utils.optionsCheck not implemented yet").enrichAsAppEncodableVaporResponse(request: req)
//        return result
    }
    
    // MARK: RouteCollection
    func boot(routes: RoutesBuilder) throws {
        // Listed below are all the routing groups:
        let typeName = "\(Self.self)".padding(toLength: 20, withPad: " ", startingAt: 0)
        let groupTag = self.name // name allows to use in conincidence with the "tag" in OpenAPI to collate routes to groups
        dlog?.info("   \(typeName) boot tag/name: [\(groupTag)] basepath: '\(self.basePath)'")
        
        routes.groupEx(AccessToken.authenticator(), path: self.basePath, configure: { util in
            util.get("all_routes", use: listAllRoutes)
                .metadata(MNRouteInfo(groupTag: self.name,
                                     productType: .apiResponse,
                                     title: "List all server routes",
                                     description: "List all server routes / endpoints",
                                      requiredAuth: .userToken))
            
            util.on(.OPTIONS, "options_check", use: optionsCheck)
                .metadata(MNRouteInfo(groupTag: self.name,
                                     productType: .apiResponse,
                                     title: "Options check",
                                     description: "Perform an options check for the Dashboard site.",
                                     requiredAuth: .userToken))
        })
    }
}
