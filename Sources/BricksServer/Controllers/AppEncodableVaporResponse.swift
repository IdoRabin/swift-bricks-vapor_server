//
//  AppEncodableVaporResponse.swift
//  
//
//  Created by Ido on 21/07/2022.
//

import Foundation
import Vapor
import Fluent
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppEncodableVaporResponse")

protocol AppEncodableVaporResponse : ResponseEncodable, AsyncResponseEncodable, JSONSerializable, Codable {
    var httpStatusOverride : HTTPStatus { get }
}

fileprivate let IS_LOG_RESPONSE_DATA : Bool = Debug.IS_DEBUG && true;

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
        let enrichedHeaderKeys = response.enrich(with: req)

        // Add more headers:
        // MARK: CORP
        // see: https://resourcepolicy.fyi/
        let crossOriginPolicy = "cross-origin" // Possible values: same-origin | same-site | cross-origin
        response.headers.replaceOrAdd(name: "Cross-Origin-Resource-Policy", value: crossOriginPolicy)
        
        // MARK: CORS
        // see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin
        var crossOriginAllowOrigin = "*"; // * | null | all |
        
        // Allowed methods for route:
        // see: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#preflighted_requests
        // TODO: Fetch expected methods PER request and set as response for the OPTIONS requests:
        let crossOriginAllowMethods = Set<HTTPMethod>([.OPTIONS, .GET, .POST])
        
        // dlog?.info("req.headers for id: \(req.requestUUIDString ?? "<?>") is:\n\(req.headers.descriptions().joined(separator: "\n"))")
        if let origin = req.headers.first(name: "Origin") ?? req.headers.first(name: "origin") {
            crossOriginAllowOrigin = origin
        }
        // Attempting to use the wildcard with credentials results in an error.
        response.headers.replaceOrAdd(name: "Access-Control-Allow-Origin", value: crossOriginAllowOrigin)
        if crossOriginAllowOrigin != "*" {
            response.headers.replaceOrAdd(name: "Vary", value: "Origin")
        }
        
        var allowedHeaders = ["Origin", "X-Requested-With", "Content-Type", "Accept"]
        allowedHeaders.append(contentsOf: enrichedHeaderKeys)
        response.headers.replaceOrAdd(name: "Access-Control-Allow-Headers", value: allowedHeaders.joined(separator: ", "))
        
        // Allowed methods:
        response.headers.replaceOrAdd(name: "Access-Control-Allow-Methods", value: crossOriginAllowMethods.descriptions().joined(separator: ", "))
        
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
            
            if (IS_LOG_RESPONSE_DATA) {
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

extension String : AppEncodableVaporResponse {}
extension Bool : AppEncodableVaporResponse {}
