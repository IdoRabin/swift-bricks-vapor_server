//
//  UserControllerUtils.swift
//
//
//  Created by Ido on 20/01/2024.
//

import Foundation
import Vapor
import RoutingKit
import MNUtils
import MNVaporUtils
import Fluent
import Logging

fileprivate let dlog : Logger? = Logger(label:"AppEncodableVaporResponse")

fileprivate class HeaderCORSEnricher {
    @discardableResult
    public static func enrichHeadersForCORS(request req:Request, response:Response)->Response {
        let enrichedHeaderKeys = Vapor.Response.appEnrichedHeaderKeys(with: req)

        // ?? strict-origin-when-cross-origin ??
        
        // MARK: CORS
        
        // Add more headers:
        // see: https://resourcepolicy.fyi/
        let crossOriginPolicy = "cross-origin" // Possible values: same-origin | same-site | cross-origin
        
        // Allowed methods for route:
        // see: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#preflighted_requests
        // TODO: Fetch expected methods PER request and set as response for the OPTIONS requests:
        let crossOriginAllowMethods = Set<HTTPMethod>([HTTPMethod.OPTIONS, .GET, .POST])
        
        // see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin
        // Attempting to use the wildcard with credentials results in an error.
        var crossOriginAllowOrigin = "*"; // * | null | all |
        if let origin = req.headers.first(name: "Origin") ?? req.headers.first(name: "origin") {
            crossOriginAllowOrigin = origin
        }
        
        var allowedHeaders = ["Origin", "X-Requested-With", "Content-Type", "Accept"]
        if enrichedHeaderKeys.count > 0  { allowedHeaders.append(contentsOf: enrichedHeaderKeys) }
        
        response.headers.replaceOrAdd(tuples: [
            (name:"Cross-Origin-Resource-Policy" , value:"cross-origin"), // Possible values: same-origin | same-site | cross-origin
            (name:"Access-Control-Allow-Methods" , value: crossOriginAllowMethods.descriptions().joined(separator: ", ")),
            (name:"Access-Control-Allow-Origin" , value: crossOriginAllowOrigin),
            (name:"Access-Control-Allow-Headers" , value: allowedHeaders.joined(separator: ", ")),
        ])
        
        if crossOriginAllowOrigin != "*" {
            response.headers.replaceOrAdd(name: "Vary", value: "Origin")
        }
        
        return response
    }
}

protocol AppEncodableVaporResponse : Sendable, Content, JSONSerializable {
    var httpStatusOverride : HTTPStatus { get }
}

extension AppEncodableVaporResponse /* default implementation */ {
    
    var httpStatusOverride : HTTPStatus {
        return .ok
    }
    
    func encodeResponse(for request: Request) async throws -> Response {
        return try await encodeResponse(for: request).get()
    }
    
    func encodeResponse(for req: Request) -> EventLoopFuture<Response> {
        let response = Response()
        response.headers.contentType = .json
        
        // Add CORS headers
        HeaderCORSEnricher.enrichHeadersForCORS(request: req, response: response)
        
        if self.httpStatusOverride.code > 299 {
            dlog?.note("httpStatusOverride for:\(req.url.string) has httpStatusOverride of a 'failure' status: \(self.httpStatusOverride.code)")
            // TODO: Determine when this should be checked: return req.eventLoop.makeFailedFuture(Abort(self.httpStatusOverride, reason: "Unknown http status issue"))
        }
        
        do {
            let encoder = AppJSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(self)
            response.body = .init(data: data)
            response.status = self.httpStatusOverride
            
            if (AppConstants.IS_LOG_RESPONSE_DATA) {
                let str = String(data:data, encoding: .utf8) ?? "?";
                dlog?.success("encoded \(req.method.rawValue) \(req.url.path.lastPathComponent()) response : \(Self.self) \(response.status) BODY: \(str)")
            }
        } catch let error {
            dlog?.note("failed encoding \(self) error: \(error.localizedDescription)?")
            return req.eventLoop.makeFailedFuture(Abort(.failedDependency, reason: "user login response faiure"))
        }
        
        return req.eventLoop.makeSucceededFuture(response)
    }
}

public extension Vapor.Response /* enrich as if it was AppEncodableVaporResponse */ {
    func enrichAsAppEncodableVaporResponse(request req:Request)->Response {
        return HeaderCORSEnricher.enrichHeadersForCORS(request: req, response: self)
    }
}

extension String : AppEncodableVaporResponse {}
extension Bool : AppEncodableVaporResponse {}

struct UserSignup: AppEncodableVaporResponse {
    let username: String
    let password: String
    let avatarURL: String?
}

extension UserSignup: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
