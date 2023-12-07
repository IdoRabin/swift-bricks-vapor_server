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
import MNVaporUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppErrorMiddleware")

final class AppErrorMiddleware: Middleware {
    
    struct AppErrorStruct : Codable {
        var error_code : Int? = nil
        var error_domain : String? = nil
        var error_reason: String = "Unknown error"
        var underlying_errors : [AppErrorStruct]?
    }
    
    /// Structure of `AppErrorMiddleware
    internal struct AppErrorResponse: Codable, JSONSerializable {
        /// The reason for the error.
        var main_error : AppErrorStruct
        
        var request_path: String? = nil
        var request_id: String? = nil
        var request_selfuser_id: String? = nil
        
        static func errorToStruct(error:Error, isRecurseDownTree:Bool = true, depth: Int = 0)-> AppErrorStruct {
            guard depth < 32 else {
                return AppErrorStruct()
            }
            
            var result : AppErrorStruct
            if let abortError = error as? AbortError {
                result = AppErrorStruct(error_code: Int(abortError.status.code),
                                        error_domain: MNDomains.sanitizeDomain("com.Vapor.AbortError"),
                                        error_reason: abortError.reason)
            } else if let appError = error as? AppError {
                result = AppErrorStruct(error_code: appError.code,
                                        error_domain: MNDomains.sanitizeDomain(appError.domain),
                                        error_reason: appError.reasonsLines ?? "Unknown error")
                if isRecurseDownTree {
                    let errs = appError.underlyingErrorsCollated()?.map({ mnError in
                        return errorToStruct(error: mnError, isRecurseDownTree: /* NOTE:*/ false, depth : 0)
                    })
                    result.underlying_errors = (errs?.count ?? 0 > 0) ? errs : nil
                }
                
            } else if let nsError = (error as? NSError) {
                result = AppErrorStruct(error_code: nsError.code,
                                        error_domain: MNDomains.sanitizeDomain(nsError.domain),
                                        error_reason: nsError.reason)
                let errs = nsError.underlyingErrors.map({ mnError in
                    return errorToStruct(error: mnError, isRecurseDownTree: /* NOTE:*/ false, depth : 0)
                })
                
                result.underlying_errors = (errs.count > 0) ? errs : nil
            } else {
                // Any old error...
                result = AppErrorStruct(error_code: Int(HTTPStatus.internalServerError.code),
                                        error_domain: MNDomains.DEFAULT_DOMAIN + ".AppError",
                                        error_reason: error.description)
            }
            return result
        }
        
        init(error:Error) {
            main_error = Self.errorToStruct(error: error)
        }
        
        mutating func update(with req:Request) {
            self.request_id = req.requestUUIDString // mutating!
            self.request_path = req.url.path.asNormalizedPathOnly() // mutating!
            self.request_selfuser_id = req.selfUserUUIDString
        }
    }
    
    static func isShouldRedirect(from req:Vapor.Request, errorResponse:AppErrorResponse)->(url:URL, type:Redirect)? {
        var resultUrl : URL? = nil
        var resultRedirect : Redirect = .temporary
        let routeInfo = req.routeInfo
        let infoPathComps : [RoutingKit.PathComponent] = routeInfo?.fullPath?.pathComponents ?? []
        
        // Determine according to path root and other parameters:
        let mnErrorCode : MNErrorCode = MNErrorCode(rawValue: errorResponse.main_error.error_code ?? 0) ?? .misc_unknown
        let basePath = infoPathComps.first?.description ?? ""
        switch (basePath, mnErrorCode) {
        case ("dashboard", .http_stt_unauthorized),
             ("dashboard", .http_stt_forbidden):
            resultUrl = URL(string: "/dashboard/login")
        default:
            if req.method == .GET && req.routeInfo?.productType == .webPage {
                for lastPathComponent in ["errorpage"] {
                    if let url = URL(string: "/\(basePath)/\(lastPathComponent)"),
                       let errorPageInfo = req.application.appServer?.routes.routeInfo(for: .GET, fullPath: url.absoluteString),
                       errorPageInfo.productType == .webPage {
                        // Set prev req id as param
                        resultUrl = url.appending(queryItems: [URLQueryItem(name: "req", value: req.requestUUIDString)])
                    }
                }
            }
        }
        
        // Finally:
        if let url = resultUrl {
            return (url:url, type:resultRedirect)
        }
        return nil
    }
    
    public static func convert(request:Request, error:any Error) -> Response {
        let appError = (error as? AppError) ?? AppError(error:error)
        if let truple = request.getError(byReqId: request.id), let routeContext = request.routeContext {
            routeContext.setError(req:request, errorTruple: truple)
            request.routeHistory?.update(req: request, error: error)
        } else {
            dlog?.note("convert(request:error:) failed: \(request.method) \(request.url.string) has no route context / error !")
        }
        
        // variables to determine
        let errComps = appError.headers(wasError:error)
        
        // Report the error to logger.
        request.logger.report(error: appError)
        
        // create a Response with appropriate status
        let response = Response(status: errComps.status, headers: errComps.headers)
        response.version = .init(major: 1, minor: 1)
        
        // attempt to serialize the error to json
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
        
        if MNUtils.debug.IS_DEBUG, let errorStr = errorResponse.serializeToJsonString(prettyPrint: true) ?? response.body.string {
            dlog?.info("error for: \(request.method) \(request.url.path) response:\n\(errorStr)")
        }
        
        // Enrich response using request data / info
        response.enrich(with: request)
        
        if let redirect = isShouldRedirect(from: request, errorResponse: errorResponse), redirect.url.absoluteString != request.url.string {
            // Will redirect
            dlog?.note("error: \(error.description) redirecting to => \(redirect.url.absoluteString)")
            request.routeHistory?.update(req: request, error: error)
            
            response.status = redirect.type.status
            // a Location header holding the URL to redirect to.
            let location = redirect.url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
            response.headers.replaceOrAdd(name: .location, value: location)
        }
        
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
