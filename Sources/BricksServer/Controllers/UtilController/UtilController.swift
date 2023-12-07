//
//  UtilController.swift
//  
//
//  Created by Ido on 30/06/2022.
//

import Foundation
import Vapor
import Fluent
import FluentKit
import DSLogger
import MNUtils
import MNVaporUtils

fileprivate let dlog : DSLogger? = DLog.forClass("UtilController")

//extension Dictionary where Key == String, Value == AnyCodable {
//
//}

class UtilController : AppRoutingController {
    
    // MARK: MNRoutingController overrides
    // REQUIRED OVERRIDE for MNRoutingController
    override var basePaths : [[RoutingKit.PathComponent]] {
        // NOTE: var basePath is derived from basePaths.first
        
        // Each string should descrive a full path
        return RoutingKit.PathComponent.arrays(fromPathStrings: ["util"])
    }
    
    // MARK: Controller API:
    override func boot(routes: RoutesBuilder) throws {
        
        routes.group("util") { util in
            let groupName = "util"
            
            // let groupInfo = AppRouteInfo.requiresBearerToken
            util.on([.GET], "listAllRoutes".pathComps, use: listAllRoutes)?.setting(
                productType: .apiResponse,
                title: "listAllRoutes",
                description: "list all routes that this server may handle for a swagger-like summary.",
                requiredAuth:.none,
                group: groupName)
            
            // Will not require credentials:
            // HTTPStatus - 429 Too Many Requests (rate limiting)
            util.on([.OPTIONS, .GET], "optionsCheck".pathComps, dict:nil, use: optionsCheck)?.setting(
                productType: .apiResponse,
                title: "optionsCheck",
                description: "a specific endpoint for sending an empty OPTIONS check, to validate the server is alive. (may be used as a 'heart-beat' for clients, but there are harsh rate limits.",
                requiredAuth:.none,
                group: groupName)
        }
    }
    
    // MARK: Options check route
    struct OptionsCheckResponse : AppEncodableVaporResponse {
        var result : String
        
        // Override to allow .no-content
        private var stt : HTTPStatus = .ok
        var httpStatusOverride: HTTPStatus {
            get {
                return stt
            }
        }
        
        init(request:Request) {
            self.result = "OK|\(Date.now.ISO8601Format(.iso8601))"
            if request.method == .OPTIONS {
                stt = .noContent // 204
            }
        }
    }
    
    func optionsCheck(req: Request) throws -> OptionsCheckResponse {
        return OptionsCheckResponse(request: req)
    }
    
    
    // MARK: List all routes route
    struct ListAllRoutesResponse : AppEncodableVaporResponse, AsyncResponseEncodable {
        
        var ri_routes : [String:[MNRouteInfo]]
        var ri_login_details = "username must exist in the system + password should not be crypted on client side."
        var ri_auth_method = "Some routes require no auth. Login route requires basic auth or oAuth, and returns an acccess token. After login, some routes require the returned bearer token or oAuth tokens etc. Use in other requests as a bearer token. Note that backendAccess requires user to have back end (dashboard) privileges. If you do not have those, turn to your admin, cusrtomer support. webPageAgent means the route requries a user-agent of a browser in the headers."
        
        init(request:Request) {
            
            // Consts:
            let fragmentsToFilterOut : [String] = [
                "/me/"
            ]
            
            // Mutation for the warning :(
            ri_login_details += ""
            ri_auth_method += ""
            
            // Routes:
            self.ri_routes = AppServer.shared.routes.allInfos.values.compactMap({ infoable in
                return infoable as? MNRouteInfo
            }).filter { info in
                if Debug.IS_DEBUG && info.groupName?.count ?? 0 == 0 {
                    dlog?.warning("info has no groupName! \(info.asDict().descriptionLines)")
                }
                return !(info.fullPath?.contains(anyOf: fragmentsToFilterOut) ?? false)
            }.groupBy { info in
                info.groupName
            }
        }
    }
    
    func listAllRoutes(req: Request) throws -> ListAllRoutesResponse {
        return ListAllRoutesResponse(request: req)
    }
    
}
