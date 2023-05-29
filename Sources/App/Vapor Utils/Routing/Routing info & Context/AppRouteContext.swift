//
//  AppRouteContext.swift
//  bserver
//
//  Created by Ido on 17/11/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppRouteContext")


// Context for a live request handled by the Vapor routing system. It contains info about the route, but also the specific info for this request's session and parameters, such as the current user, accesstoken, request id and more..

extension HTTPStatus {
    // Redictect codes: force redirect:
    //   case .permanent 301  A cacheable redirect.
    //   case .normal    303  "see other" Forces the redirect to come with a GET, regardless of req method.
    //   case .temporary 307  Maintains original request method, ie: PUT will call PUT on redirect.
    static let REDIRECT_HTTP_STATUSES : [HTTPStatus] = [.permanentRedirect, .seeOther, .temporaryRedirect]
}

struct AppRouteContextStorageKey : ReqStorageKey {
    typealias Value = AppRouteContext
}

// Ia the runtime / dynamic app route info and context userinfo
class AppRouteContext  : AppRouteInfoable {

    
    // MARK: AppRouteInfoable properties
    var title: String? = nil
    var desc: String? = nil
    var fullPath: String? = nil
    var groupName: String? = nil
    var bodyStreamStrategy: Vapor.HTTPBodyStreamStrategy = .collect
    var productType: RouteProductType = .webPage
    var requiredAuth: AppRouteAuth = .none
    var httpMethods = Set<NIOHTTP1.HTTPMethod>()
    // var rulesNames : [RabacName/* for Rule*/] = [] // Uncomment:
    
    // Mark: Non-AppRouteInfoable properties
    var errorCode : String? = nil
    var errorReason : String? = nil
    var errorText : String? = nil
    var errorRequestID : String? = nil
    var errorOriginatingPath : String? = nil
    
    // MARK: Members / properties
    private (set) var selfUser : User? = nil
    private (set) var selfAccessToken : AccessToken? = nil
    var contextText : String? = nil
    var isLoggedIn : Bool = false
    var pageParams : [String:String] = [:]
    
    // MARK: Computed properties
    // Uncomment:
//    var rulesNamesOrNil : [RabacName /* for Rule */]? {
//        return self.rulesNames.count > 0 ? self.rulesNames : nil
//    }
    
    // MARK: Private
    // MARK: Public
    func updateInSession(with req:Request?) {
        guard let req = req else {
            dlog?.warning("updatedSession(with req:) req is nil!")
            return
        }
        
        // Update the AppRouteInfoable properties
        self.update(with: req.route?.appRoute)
    }
    
    private func asSomeDict(isRouteInfoCodingKeys isck:Bool = true) -> [AnyHashable : Any] {
        var result : [AnyHashable : Any] = [:]
        typealias ck = RouteInfoCodingKeys
        
        
        // Route infoable part:
        
        // Static / the route has this info for any instance of the route:
        result[isck ? ck.ri_productType : "productType"]    = self.productType
        result[isck ? ck.ri_title : "title"]                = self.title
        result[isck ? ck.ri_desc : "desc"]                  = self.desc
        result[isck ? ck.ri_required_auth : "requiredAuth"] = self.requiredAuth
        result[isck ? ck.ri_fullPath : "fullPath"]          = self.fullPath
        result[isck ? ck.ri_group_name : "groupName"]       = self.groupName
        result[isck ? ck.ri_http_methods : "httpMethods"]   = self.httpMethods.strings
        result[isck ? ck.ri_body_stream_strategy : "bodyStreamStrategy"] = self.bodyStreamStrategy
        // result[isck ? ck.ri_permissions : "rulesNames"]     = self.rulesNames  // Uncomment:
        
        // Context part: (dynamic specific requests)
        result["selfUser"] = self.selfUser
        result["selfAccessToken"] = self.selfAccessToken
        result["contextText"] = self.contextText
        result["isLoggedIn"] = self.isLoggedIn
        
        // Error part: (dynamic for specific requests)
        result["errorCode"] = self.errorCode
        result["errorReason"] = self.errorReason
        result["errorText"] = self.errorText
        result["errorRequestID"] = self.errorRequestID
        result["errorOriginatingPath"] = self.errorOriginatingPath
        
        return result
    }
    
    // MARK: As various dictionaries:
    func asDict() -> [AnyHashable : Any] {
        return self.asSomeDict(isRouteInfoCodingKeys: true)
    }
    
    func asStrHashableDict()-> [String:any CodableHashable] {
        return self.asSomeDict(isRouteInfoCodingKeys: false) as! [String:any CodableHashable]
    }
    
    // Uncomment:
    /*
    func asRabacDict()-> [RabacKey:Any] {
        var result : [RabacKey:Any] = [:]
        
        // Route infoable part:
        result[.action] = self.productType
        result[.requestedResource] = (self.fullPath != nil) ? AppRoutes.normalizedRoutePath(self.fullPath!) : nil
        
//        result["productType"] = self.productType
//        result["title"] = self.title
//        result["description"] = self.description
//        result["requiredAuth"] = self.requiredAuth
//        result["fullPath"] = self.fullPath
//        result["groupName"] = self.groupName
//        result["httpMethods"] = self.httpMethods.strings
//        result["bodyStreamStrategy"] = self.bodyStreamStrategy
//
//        // Context part:
//        result["selfUser"] = self.selfUser
//        result["selfAccessToken"] = self.selfAccessToken
//        result["contextText"] = self.contextText
//        result["isLoggedIn"] = self.isLoggedIn
//
//        // Error part:
//        result["errorCode"] = self.errorCode
//        result["errorReason"] = self.errorReason
//        result["errorText"] = self.errorText
//        result["errorRequestID"] = self.errorRequestID
//        result["errorOriginatingPath"] = self.errorOriginatingPath

        return result
    }*/
    

    // MARK: Lifecycle
    init(request req:Request) {
        self.updateInSession(with: req)
    }
    

    // MARK: Equatable
    static func ==(lhs:AppRouteContext, rhs:AppRouteContext)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    // MARK: Hahsable
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(fullPath)
        hasher.combine(groupName)
        hasher.combine(bodyStreamStrategy)
        hasher.combine(productType)
        hasher.combine(requiredAuth.rawValue)
        hasher.combine(httpMethods)
        
        hasher.combine(selfUser)
        hasher.combine(selfAccessToken)
        hasher.combine(contextText)
        hasher.combine(isLoggedIn)
        
        hasher.combine(errorCode)
        hasher.combine(errorReason)
        hasher.combine(errorText)
        hasher.combine(errorRequestID)
        hasher.combine(errorOriginatingPath)
    }
    
    func setError(req:Request, errorTruple:(err:AppError, path:String, requestId:String)) {
        self.setError(req:req, err: errorTruple.err, errorOrigPath: errorTruple.path, errReqId: errorTruple.requestId)
    }
    
    func setError(req:Request, err:AppError, errorOrigPath:String, errReqId:String) {
        // Fetch best error:
        
        // Use the given error (the req. historys' last navigation's error)
        var foundError : AppError = err
        if Redirect.allHttpStatuses.contains(err.httpStatus ?? .ok), let underlying = err.underlyingError {
            // Error was a redirection, so we use the underlying error (i.e the reason for the redirection)
            foundError = underlying
        }
        
        self.errorOriginatingPath = errorOrigPath
        dlog?.info("context: setError >> \(foundError.code) >> \(foundError.reason)")
        var code = foundError.code
        if let sttCode = foundError.httpStatus?.code {
            code = AppErrorInt(sttCode)
        }
        self.errorCode = "\(code)"
        // NOTE: Make sure to use .reasonLines and not .reason!
        self.errorReason = foundError.httpStatus?.reasonPhrase ?? foundError.reasonsLines ?? foundError.desc
        
        self.errorRequestID = errReqId.replacingOccurrences(of: "REQ|", with: "✓") // ✓ checkmark
        if foundError.reason.count < 20 {
            self.title = (self.title ?? "") + " \(foundError.reason)"
        } else {
            self.title = (self.title ?? "") + " \(code)"
        }

        // Error Text
        self.errorText = foundError.reasonsLines ?? foundError.httpStatus?.reasonPhrase ?? foundError.desc
        if self.errorText != nil, self.errorText == self.errorReason && self.errorText != foundError.desc {
            self.errorText = self.errorText! + ". " + foundError.desc
        }
    }
    
}

extension AppRouteContext {
    
    
    /// Will return a new AppRouteContext, but also save it into the requests strogate or session storage..)
    /// - Parameter req: request to create / update context for
    /// - Returns: The latest, updated AppRouteContext for the request
    static func setupRouteContext(for req: Request)->AppRouteContext {
        _ = req.session // Initializes session if needed
        if req.routeHistory == nil {
            // Init history
            req.saveToSessionStore(key: ReqStorageKeys.appRouteHistory, value: RoutingHistory())
        }
        
        var context : AppRouteContext? = nil
        context = req.getFromSessionStore(key: ReqStorageKeys.appRouteContext)
        if context == nil {
            context = AppRouteContext(request: req)
        } else {
            context?.updateInSession(with: req)
        }
        
        req.saveToSessionStore(key: ReqStorageKeys.appRouteContext, value: context)
        
        if Debug.IS_DEBUG {
            if context == nil {
                dlog?.warning("prepContext resulting context is nil!")
            }
            if req.route == nil {
                dlog?.note("prepContext(_ req:Request) req.route is nil!")
            } else if req.route?.appRoute.fullPath?.asNormalizedPathOnly() != req.url.path.asNormalizedPathOnly() {
                dlog?.note("prepContext(_ req:Request) urls normalized paths are not the equal!! \((req.route?.appRoute.fullPath).descOrNil) \(req.url.path)")
            }
            
            if let history = req.routeHistory, history.items.count > 0 {
                dlog?.info("Routing history: \(history.items.descriptionLines)")
            }
        }
        
        return context!
    }
}
