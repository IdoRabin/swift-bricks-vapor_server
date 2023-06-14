//
//
//  RoutesBuilderEx.swift
//  
//
//  Created by Ido on 16/07/2022.
//

import Vapor
import DSLogger
import MNUtils
import MNVaporUtils

fileprivate let dlog : DSLogger? = DLog.forClass("RoutesBuilderEx")

fileprivate let R_DESCRIPTION_KEY = RouteInfoCodingKeys.ri_desc.rawValue


extension Vapor.RoutesBuilder {
    
    static var appRoutes : MNRoutes {
        return Vapor.Route.mnRouteManager
    }
    
    var appRoutes : MNRoutes {
        return Self.appRoutes
    }
    
    // MARK: Generalized calls for AsyncResponseEncodable
    @discardableResult
    public func on<Response>(
        _ methods: [HTTPMethod],
        _ path: RoutingKit.PathComponent...,
        body: HTTPBodyStreamStrategy = .collect,
        dict:[AnyHashable: Any]? = [:],
        use closure: @escaping (Request) async throws -> Response
    ) -> Route? where Response: AsyncResponseEncodable
    {
        return self.on(methods, path, body: body, dict:dict, use:closure)
    }
    
    @discardableResult
    public func on<Response>(
        _ methods: [HTTPMethod],
        _ path: [RoutingKit.PathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        dict:[AnyHashable: Any]? = nil,
        use closure: @escaping (Request) async throws -> Response
    ) -> Route? where Response: AsyncResponseEncodable
    {
        let fpath = path.fullPath.asNormalizedPathOnly()
        guard methods.count > 0 && !methods.isEmpty else {
            dlog?.warning("Failed creating Vapor route \"\(fpath)\": no HTTP methods supplied")
            return nil
        }
        
        // Build the responder:
        let responder = AsyncBasicResponder { request in
            if case .collect(let max) = body, request.body.data == nil {
                _ = try await request.body.collect(max: max?.value ?? request.application.routes.defaultMaxBodySize.value).get()

            }

            let response = try await closure(request).encodeResponse(for: request)
            
            // Debug log full respone status, body and headers
            if Debug.IS_DEBUG && false {
                dlog?.info("response stts:: \(response.status)")
                dlog?.info("response hedr:: \(response.headers)")
                dlog?.info("response body:: \(response.body)")
            }
            return response
        }

        // Build for multiple methods:
        var lastRoute : Route!
        for method in methods.uniqueElements() {
            // We create multiple routes for each http method type...
            let route = Route(
                method: method,
                path: path,
                responder: responder,
                requestType: Request.self,
                responseType: Response.self
            )
            self.add(route)
            
            let appRoute = route.appRoute
            if let dict = dict, dict.count > 0 {
                let appRoute = route.appRoute
                appRoute.update(with: dict) // add to the appRoute
                route.setting(routeInfoable: appRoute) // add to the vapor.route.userInfo
            }
            
            appRoutes.registerRouteIfNeeded(appRoute: appRoute)
            lastRoute = route
        }
//
        lastRoute.debugValidateAppRoute(context: ".on(methods:path:body:info:\(dict?.count.description ?? "<nil>"):use:)")
        
        return lastRoute
    }
    
    /// Allow multiple redirects from multiple HTTPMetods using one request->response closure to perform the redirect
    /// NOTE: caller is expected to use request.redirect(...) to build the resulting Response value
    /// - Parameters:
    ///   - methods: HTTPMetods that aill apply the redirec
    ///   - to: a closure whre the returned value is the redirect Response
    /// - Returns: Aray of all created routes, as
    @discardableResult
    func redirects(methods:[HTTPMethod], to:@escaping ( _ method:HTTPMethod, _ request:Request)->Response)->[Route] {
        
        var result : [Route] = []
        
        for method in methods {
            let route = self.on(method) { req->Response in
                dlog?.warning("TODO: Handle redirection [\(method)] in terms of context and routeInfo.. \(req)")
                dlog?.raisePreconditionFailure("TODO: Handle redirection [\(method)] in terms of context and routeInfo.. \(req)")
//                    .setting(dictionary: [
//                        .ri_redirectedFrom: fromPath
//                    ])
//
                return to(method, req)
            }
            
            appRoutes.registerRouteIfNeeded(appRoute: route.appRoute)
            route.debugValidateAppRoute(context: ".redirects(methods:to:)")
            result.append(route)
        }

        return result
    }
}

