//
//  AppErrorMiddleware.swift
//  
//
//  Created by Ido on 12/10/2022.
//

import Foundation
import Vapor
import NIOCore
import LeafKit
import Logging
import MNUtils
import MNVaporUtils

fileprivate let dlog : Logger? = Logger(label:"AppErrorMiddleware")

// NOTE: AppErrorStruct == MNErrorStruct - see AppAliases and MNErrorStruct
// These structures are built to represent errors (also underlying errors, even nested ones) to the user / consumer
final class AppErrorMiddleware: Middleware {
    
    /// Structure of `AppErrorMiddleware
    internal struct AppErrorResponse: Codable, JSONSerializable {
        /// The reason for the error.
        var main_error : AppErrorStruct
        var request_path: String? = nil  // For use with server requests
        var request_id: String? = nil // For use with server requests
        var request_selfuser_id: String? = nil  // For use with server requests
        
        static func errorToStruct(error:Error, isRecurseDownTree:Bool = true, depth: Int = 0)-> AppErrorStruct {
            guard depth < 32 else {
                return AppErrorStruct()
            }
            
            var result : AppErrorStruct
            if let abortError = error as? AbortError {
                result = AppErrorStruct(error_code: Int(abortError.status.code),
                                        error_domain: MNDomains.sanitizeDomain("com.Vapor.AbortError"),
                                        error_reason: abortError.reason)
                if isRecurseDownTree {
                    let errs = (abortError as NSError).underlyingErrors
                    if errs.count > 0 {
                        result.update(underlyingErrors: errs)
                    }
                }
            } else if let appError = error as? AppError {
                result = AppErrorStruct(error_code: appError.code,
                                        error_domain: MNDomains.sanitizeDomain(appError.domain),
                                        error_reason: appError.reasonsLines ?? "Unknown error")
                if isRecurseDownTree, let underlying = appError.underlyingErrorsCollated(), underlying.count > 0 {
                    result.update(underlyingMNErrors: underlying)
                }
                
            } else {
                let nsError = (error as NSError) // cast always succeeds
                result = AppErrorStruct(error_code: nsError.code,
                                        error_domain: MNDomains.sanitizeDomain(nsError.domain),
                                        error_reason: nsError.reason)
                let errs = nsError.underlyingErrors
                if errs.count > 0 {
                    result.update(underlyingErrors: errs)
                }
            } /*else {
                // Any old error...
                result = AppErrorStruct(error_code: Int(HTTPStatus.internalServerError.code),
                                        error_domain: MNDomains.DEFAULT_DOMAIN + ".AppError",
                                        error_reason: error.description)
            }*/
            return result
        }
        
        init(error:Error) {
            main_error = Self.errorToStruct(error: error)
        }
        
        mutating func update(with req:Request) {
            self.request_id = req.requestUUIDString // mutating!
            self.request_path = req.url.path.asNormalizedPathOnly() // mutating!
            // TODO: Reimplemntnt self.request_selfuser_id = req.selfUserUUIDString
        }
    }
    
    
    public static func convert(request:Request, error:any Error) ->  Response {
        
        if Debug.IS_DEBUG, let lexerError = error as? LexerError {
            let jsonString = lexerError.serializeToJsonString(prettyPrint: true) ?? ""
            dlog?.warning("Warning: HTML / Leaf lexer error. \(jsonString.descriptionLines)")
            return Response(status: .internalServerError, body: Response.Body(stringLiteral: jsonString))
        }
        
        let appError = (error as? AppError) ?? AppError(error:error)
        
        // Build and update MNErrorStruct
        let errStruct = MNErrorStruct(mnError: appError, recurseUnderlyingErrors: true)
        
        // Update new error into history
        do {
            try request.routeHistory?.update(req: request, response:nil, action: .error(errStruct))
        } catch let error {
            dlog?.note("convert(request:error:) failed updating route history: \(error)")
        }
        
        // variables to determine
        // let errComps = appError.headers(wasError:error)
        
        // Report the error to logger.
        request.logger.report(error: appError)
        
        // Create a Response with appropriate status
        let statusCode : NIOHTTP1.HTTPResponseStatus = NIOHTTP1.HTTPResponseStatus(statusCode: Int(appError.httpStatusCode ?? 500), reasonPhrase: appError.reason)
        let response = Response(status: statusCode , headers: .init()) // errComps.headers
        response.version = HTTPVersion.init(major: 1, minor: 1)
        
        // Attempt to serialize the error to json
        var errorResponse : AppErrorResponse
        do {
            errorResponse = AppErrorResponse(error: error)
            errorResponse.update(with:request) // will add data from the request data into the AppErrorResponse properties
            response.body = try Response.Body.init(data: AppJSONEncoder().encode(errorResponse), byteBufferAllocator: request.byteBufferAllocator)
            response.headers.replaceOrAdd(name: .contentType, value: "application/json; charset=utf-8")
        } catch let error {
            response.body = Response.Body.init(string: "Oops: \(error)", byteBufferAllocator: request.byteBufferAllocator)
            errorResponse = AppErrorResponse(error: error)
            response.headers.replaceOrAdd(name: .contentType, value: "text/plain; charset=utf-8")
        }
        
        
        // Enrich response using request data / info
        dlog?.todo("reimplement response.enrich")
        // response.enrich(with: request)

        // NOTE: use AppRedirectMiddleware to redirect after error using redirectRules
        // redirectMidleware should be placed earlier (before) the error middleware to catch the errors handled here
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
