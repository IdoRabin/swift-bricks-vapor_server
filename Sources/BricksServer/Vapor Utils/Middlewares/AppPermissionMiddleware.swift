//
//  AppPermissionMiddleware.swift
//  
//
//  Created by Ido on 02/12/2022.
//

import Foundation
import Vapor
import Fluent // For DB
import FluentKit
import NIOCore
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppPermissionMiddleware")
/*
enum PermissionSubject : JSONSerializable, Hashable {
    case users([MNUser])
    case files([String])
    case routes([String])
    case webpages([String])
    case models([String])
    case underermined
}

typealias AppPermissionID = String
typealias AppPermission = MNPermission<AppPermissionID, AppError>

extension AppPermission where Forbidden : AppError {
    static func forbidden(code:AppErrorCode, reason:String)->AppPermission {
        return .forbidden(AppError(code:code, reason: reason)    )
    }
    
    static func forbidden(mnError:MNError)->AppPermission {
        let code = AppErrorCode(rawValue: mnError.code)
        let appError : AppError = AppError(code: code ?? .misc_unknown,
                                           reasons: mnError.reasons)
        return .forbidden(appError)
    }
}

extension AppPermission {
    
//    static func fromRabacPermission(_ rbac:RabacPermission)->AppPermission {
//        switch rbac {
//        case .allowed(let authId):  return .allowed("|" + authId.value)
//        case .forbidden(let error): return .forbidden(AppError(rabacError:error))
//        }
//    }
//
//    static func forbidden(rabacErrorCode:RabacErrCode, reason:String)->AppPermission {
//        return .forbidden(AppError(rabacErrorCode: rabacErrorCode, reason: reason))
//    }
//
//    static func forbidden(code:AppErrorCode, reason:String)->AppPermission {
//        return .forbidden(AppError(code, reason:reason))
//    }
//
//    static func unknownForbidden(reason:String)->AppPermission {
//        return AppPermission.forbidden(rabacErrorCode: .forbidden, reason: reason)
//    }
}

//extension AppError /* RABAC */{
//
//    convenience init(rabacError:RabacError) {
//        self.init(AppErrorCode(rawValue: rabacError.code)!, reason: rabacError.reason)
//    }
//
//    convenience init(rabacErrorCode:RabacErrCode, reason:String) {
//        self.init(AppErrorCode(rawValue: rabacErrorCode)!, reason: reason)
//    }
//}

protocol PermissionGiver {
    /*
    func isAllowed(for selfUser:User?,
                   to action:Any,
                   on subject:PermissionSubject?,
                   during req:Request?,
                   params:[String:Any]?)->AppPermission
     */
}

// NOTE: See also implementation in : AppPermissionMiddleware + Routes
final class AppPermissionMiddleware: Middleware, LifecycleBootableHandler {
    
    // Settings -
    typealias UserUUID = UUID
    var webpagePathsPrefixes : [String] = []
    private static var errorWebpagePaths = Set<String>()
    
    // MARK: Static
    static func saveFolder()->String {
        guard var path = FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory,
                                                  in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            return ""
        }
        
        // App Name:
        let appName = Bundle.main.bundleName?.capitalized.replacingOccurrences(of: .whitespaces, with: "_") ?? "Bundle.main.bundleName == nil !"
        path = path.appendingPathComponent(appName)
        
        // Create folder if needed
        if !FileManager.default.fileExists(atPath: path.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
            } catch let error {
                dlog?.warning("pathToSettingsFile failed crating /\(appName)/ folder. error: " + error.localizedDescription)
                return ""
            }
        }
        
        return path.absoluteString
    }
    
    // MARK: Properties
    // @SkipEncode var roles = MNCache<UserUUID, AppRole>(name: "AppPermissionsMid", maxSize: 8192, attemptLoad: true, saveFolder: AppPermissionMiddleware.saveFolder())
    var db: (any Database)? = nil {
        didSet {
//             TODO: Setup permissions system?
//            }
        }
    }
    
    // MARK: Lifecycle
    private init() {
        if Debug.IS_DEBUG && AppServer.shared.permissions != nil {
            DLog.warning("AppPermissionMiddleware another instance is already registered!")
        }
        AppServer.shared.permissions = self
        Task {
//            Rabac.shared.saveIfNeeded()
        }
    }
    
    // MARK: Private
    
    // MARK: Static "init"
    /// Create a default `AppPermissionMiddleware`
    /// - parameters:
    ///     - environment: The environment to respect when presenting errors.
    public static func `default`(environment: Environment) -> AppPermissionMiddleware {
        return AppPermissionMiddleware()
    }
    
//    private func response(for request:Request, error:RabacError) async throws ->Vapor.Response {
//
//        // Reute history:
//        request.routeHistory?.update(req: request, error: error)
//
//        // webPageRoutePrefixes
//        if request.productType == .webPage {
//            // Returns error webpage
//            let result = try await DashboardController.dboardRedirectToErrorPage(request, error: error)
//            if Self.errorWebpagePaths.count < 1, let path = result.headers.first(name: HTTPHeaders.Name.location)?.asNormalizedPathOnly() {
//                Self.errorWebpagePaths.update(with: path)
//            }
//            return result
//        } else {
//            // Return error body
//            // returns Vapor.ResponseDashboardController
//            return AppErrorMiddleware.convert(request: request, error: error)
//        }
//    }
    
    // MARK: Middleware handles a request
    func respond(to request: Vapor.Request, chainingTo next: Vapor.Responder) -> NIOCore.EventLoopFuture<Vapor.Response> {
        
        // 401 Unauthorized - use when access token is missing or wrong
        // 403 Forbidden - use when access token exists and is valid, but the permissions / role does not allow this operation
        dlog?.info(".respond(to:req..).. START \(request.url.path)")
        _ = request.routeContext /*?? AppRouteContext.setupRouteContext(for: request)*/
        // Error pages: do not need checking ?
        if request.url.path.asNormalizedPathOnly() == Self.errorWebpagePaths.first ?? "" {
            return next.respond(to: request)
        }
        
        // Needs checking
//        let context = request.toRabacContext() // from route context to rabac context
        let promise = request.eventLoop.makePromise(of: Vapor.Response.self)
//        promise.completeWithTask {
//             // collect currect user, access token and roles
//            let result = await Rabac.shared.check(context: context)
//            switch result {
//            case .allowed(let allowed):
//                // Pass to next middleware
//                dlog?.info(".respond(to:req..).. ALLOWED \(request.url.path) \(allowed)")
//                return try await next.respond(to: request).get()
//            case .forbidden(let forbidden):
//                let errorResponse = try await self.response(for: request, error: forbidden)
//                dlog?.info(".respond(to:req..).. FORBIDDEN! \(forbidden) errorResponse: \(errorResponse)")
//                return errorResponse
//            }
//        }
        
        return promise.futureResult
    }
    
    // MARK: Hahsable
    func hash(into hasher: inout Hasher) {
        hasher.combine(AppServer.shared.dbName)
    }

    // MARK: Setup and loading:
    // MARK: LifecycleBootableHandler:
    func willBoot(_ application: Application) throws {
        dlog?.info("willBoot \(application)")
    }
    
    func boot(_ application: Vapor.Application) throws {
        dlog?.info("boot \(application)")
    }
    
    public func didBoot(_ application: Application) throws {
        dlog?.info("didBoot \(application)")
    }
    
    public func shutdown(_ application: Application) {
        dlog?.info("shutdown \(application)")
    }
}

extension AppPermissionMiddleware : PermissionGiver {
    /*
    func isAllowed(for selfUser: User?,
                   to action: Any,
                   on subject: PermissionSubject?,
                   during req: Vapor.Request?,
                   params: [String : Any]?) -> AppPermission {
        
        dlog?.info("isAllowed for user:\(selfUser.descOrNil) action:\(action) on:\(subject.descOrNil) during req:\(req.descOrNil) params:\(params.descOrNil)")
        
        var permissionId = "Unknown_\(Date.now.formatted(.iso8601))".camelCaseToSnakeCase()
        if let subject = subject {
            switch subject {
            case .users: // (let array):
                break
            case .files: //(let array):
                break
            case .routes: //(let array):
                break
            case .webpages:
                break
            case .models:
                break
            case .underermined:
                permissionId += "_undetermined"
                return .forbidden(code:AppErrorCode.http_stt_forbidden, reason:"Permission not granted" + Debug.StringOrEmpty("AppPermissionMiddleware isAllowed(for:to:on:during:params) subject was not determined."))
            }
        }
        return .allowed(permissionId)
    }
    */
}
*/
