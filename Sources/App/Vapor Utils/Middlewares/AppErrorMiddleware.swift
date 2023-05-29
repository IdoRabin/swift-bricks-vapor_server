//
//  AppErrorMiddleware.swift
//  
//
//  Created by Ido on 12/10/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppErrorMiddleware")

final class AppErrorMiddleware: Middleware {
    
    /// Structure of `AppErrorMiddleware
    internal struct AppErrorResponse: Codable {
        /// The reason for the error.
        var error_code : Int? = nil
        var error_domain : String? = nil
        var error_reason: String = "Unknown error"
        
        var request_path: String? = nil
        var request_id: String? = nil
        var request_selfuser_id: String? = nil

        init(error:Error) {
            if let abortError = error as? AbortError {
                self.error_reason = abortError.reason
                self.error_code = Int(abortError.status.code)
                self.error_domain = "com.vapor.AbortError"
                
            } else if let appError = error as? AppError {
                self.error_reason = appError.reasonsLines ?? "Unknown error"
                self.error_code = appError.code
                self.error_domain = appError.domain
                
            } else {
                // Any old error...
                self.error_reason = error.description
                self.error_code = Int(HTTPStatus.internalServerError.code)
                self.error_domain = AppError.DEFAULT_DOMAIN + "com.\(AppConstants.APP_NAME).AppError.err"
            }
        }
        
        mutating func update(with req:Request) {
            self.request_id = req.requestUUIDString // mutating!
            self.request_path = req.url.path.asNormalizedPathOnly() // mutating!
            self.request_selfuser_id = req.selfUserUUIDString
        }
    }
    
    public static func convert(request:Request, error:any Error) -> Response {
        let appError = AppError(error:error)
        
        // variables to determine
        let errComps = appError.headers(wasError:error)
        
        // Report the error to logger.
        request.logger.report(error: appError)
        
        // create a Response with appropriate status
        let response = Response(status: errComps.status, headers: errComps.headers)
        response.version = .init(major: 1, minor: 1)
        
        // attempt to serialize the error to json
        do {
            var errorResponse = AppErrorResponse(error: error)
            errorResponse.update(with:request) // will add data from the request data into the AppErrorResponse properties
            response.body = try Response.Body.init(data: AppJSONEncoder().encode(errorResponse), byteBufferAllocator: request.byteBufferAllocator)
            response.headers.replaceOrAdd(name: .contentType, value: "application/json; charset=utf-8")
        } catch {
            response.body = Response.Body.init(string: "Oops: \(error)", byteBufferAllocator: request.byteBufferAllocator)
            response.headers.replaceOrAdd(name: .contentType, value: "text/plain; charset=utf-8")
        }
        
        // Enrich response using request data / info
        response.enrich(with: request)
        
        return response
    }
    
    /// Create a default `AppErrorMiddleware`. Logs errors to a `Logger` based on `Environment`
    /// and converts `Error` to `Response` based on conformance to `AbortError` and `Debuggable`.
    ///
    /// - parameters:
    ///     - environment: The environment to respect when presenting errors.
    public static func `default`(environment: Environment) -> AppErrorMiddleware {
        return AppErrorMiddleware(AppErrorMiddleware.convert)
    }

    /// Error-handling closure.
    private let closure: (Request, Error) -> (Response)

    /// Create a new `ErrorMiddleware`.
    ///
    /// - parameters:
    ///     - closure: Error-handling closure. Converts `Error` to `Response`.
    public init(_ closure: @escaping (Request, Error) -> (Response)) {
        self.closure = closure
    }
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).flatMapErrorThrowing { error in
            return self.closure(request, error)
        }
    }
}
