//
//  AppRedirectRule.swift
//
//
//  Created by Ido on 07/02/2024.
//

import Foundation
import Vapor
import NIOCore
import LeafKit
import Logging
import MNUtils
import MNVaporUtils

fileprivate let dlog : Logger? = Logger(label:"AppRedirectRule")

public struct AppRedirectMatch {
    let redirectURL : URL
    let headers : HTTPHeaders?
    let matchedRule : AppRedirectRule
}

public struct AppRedirectRule {
    
    struct RedirectDirectives: OptionSet, Hashable, Equatable, JSONSerializable, CustomStringConvertible {
        
        let rawValue: Int
        
        static let previousRequestId = RedirectDirectives(rawValue: 1 << 0)
        static let sessionUserId = RedirectDirectives(rawValue: 1 << 1)
        static let sessionId = RedirectDirectives(rawValue: 1 << 2)
        
        static let all: RedirectDirectives = [.previousRequestId, .sessionUserId, .sessionId]
        
        private func descriptionForElem(rawValue:RawValue)->String {
            switch rawValue {
            case Self.previousRequestId.rawValue: return "prevReqId"
            case Self.sessionUserId.rawValue: return "sessionUserId"
            case Self.sessionId.rawValue: return "sessionId"
            default:
                return "UnknownRedirectDirective! (\(rawValue)"
            }
        }
        
        var description: String {
            let elems = self.elements.map { element in
                "." + self.descriptionForElem(rawValue: element.rawValue)
            }
            switch elems.count {
            case 1: return elems.first!
            default: break
            }
            
            return elems.descriptionJoined
        }
        
        var asQueryParameterName: String {
            switch rawValue {
            case Self.previousRequestId.rawValue: return "req_id"
            case Self.sessionUserId.rawValue: return "session_user_id"
            case Self.sessionId.rawValue: return "session_id"
            default:
                return "UnknownRedirectDirective! (\(rawValue)"
            }
        }
    }

    public enum HTTPStatii : CustomDebugStringConvertible, JSONSerializable {
        case any
        case range(Range<Int>)
        case cases(Set<MNErrorCode>)
        case allSuccesses // 200..299
        case nonSuccesses // lt <200 or gt>299
        case range200s // equals allSuccesses 200...299
        case range300s // equals allSuccesses 300...399
        case range400s // equals allSuccesses 400...499
        case range500s // equals allSuccesses 500...599
        
        func matches(httpStatus:HTTPStatus)->Bool {
            return matches(code:Int(httpStatus.code))
        }
        
        func matches(code:Int)->Bool {
            switch self {
            case .any:
                return true
                
            case .range(let range):
                return range.contains(code)
                
            case .cases(let set):
                return set.map { $0.code }.contains(code)
                
            case .allSuccesses:
                return (200...299).contains(code) // Success
                
            case .nonSuccesses:
                return !(200...299).contains(code) // Anything NOT a Success
                
            case .range200s: // equals allSuccesses 200...299
                return (200...299).contains(code) // Success
                
            case .range300s: // equals allSuccesses 300...399
                return (300...399).contains(code) // Redirect
                
            case .range400s: // equals allSuccesses 400...499
                return (400...499).contains(code) // Client / Not found / routing
                
            case .range500s: // equals allSuccesses 500...599
                return (500...599).contains(code) // server
                
            }
        }
        
        // MARK: CustomDebugStringConvertible
        public var debugDescription: String {
            switch self {
            case .any: return ".any"
            case .range(let range):  return ".range[\(range.lowerBound)...\(range.upperBound)]"
            case .cases(let set):  return ".cases[\(set.descriptionsJoined)]"
            case .allSuccesses:  return ".allSuccesses"
            case .nonSuccesses:  return ".nonSuccesses"
            case .range200s:  return ".range200s"
            case .range300s:  return ".range300s"
            case .range400s:  return ".range400s"
            case .range500s:  return ".range500s"
            }
        }
    }
    
    let sourceGroupTag : MNRouteGroup.MNRouteGroupTag?
    let sourcePath : URL?
    let sourceMethod: HTTPMethod?
    let responseStatii : [HTTPStatii]?
    
    // redirect to this new path:
    let redirectToPath : URL?
    let redirectDirectives : RedirectDirectives
    let redirectType : Redirect
    
    init(sourceGroupTag: MNRouteGroup.MNRouteGroupTag?, sourcePath: [RoutingKit.PathComponent]?, sourceMethod: HTTPMethod?,
         responseStatii: HTTPStatii...,
         redirectToPath: RoutingKit.PathComponent...,
         redirectType:Redirect,
         redirectDirectives:RedirectDirectives
    ) throws {
        let source = (sourcePath != nil) ?  URL(string:sourcePath!.string.asNormalizedPathOnly()) : nil
        // Redirecting is NOT relative!
        guard let redirect = URL(string:redirectToPath.string.asNormalizedPathOnly().adddingPrefixIfNotAlready("/")) else {
            throw MNError(code:.misc_bad_input, reason: "AppRedirectRule cannot create redirectPath from: \(redirectToPath.string)")
        }
        self.init(sourceGroupTag: sourceGroupTag,
                  sourcePath: source,
                  sourceMethod: sourceMethod,
                  responseStatii: responseStatii,
                  redirectToPath: redirect,
                  redirectType: redirectType, redirectDirectives: redirectDirectives)
    }
    
    init(sourceGroupTag: MNRouteGroup.MNRouteGroupTag?, sourcePath: URL?, sourceMethod: HTTPMethod?,
         responseStatii: HTTPStatii...,
         redirectToPath: URL,
         redirectType:Redirect,
         redirectDirectives:RedirectDirectives
    ) {
        self.init(sourceGroupTag: sourceGroupTag,
                  sourcePath: sourcePath,
                  sourceMethod: sourceMethod,
                  responseStatii: responseStatii,
                  redirectToPath: redirectToPath,
                  redirectType: redirectType, redirectDirectives: redirectDirectives)
    }
    
    init(sourceGroupTag: MNRouteGroup.MNRouteGroupTag?, sourcePath: URL?, sourceMethod: HTTPMethod?,
         responseStatii: [HTTPStatii],
         redirectToPath: URL,
         redirectType:Redirect,
         redirectDirectives:RedirectDirectives
    ) {
        
        // Matching criteria:
        self.sourceGroupTag = sourceGroupTag
        self.sourcePath = sourcePath
        self.sourceMethod = sourceMethod
        self.responseStatii = responseStatii
        
        // To do when redirecting:
        self.redirectToPath = redirectToPath
        self.redirectType = redirectType
        self.redirectDirectives = redirectDirectives
    }
    
    private func constructRedirectMatch(req : Request, response:Response?) throws ->AppRedirectMatch {
        guard var url =  self.redirectToPath else {
            throw MNError(code: .http_stt_internalServerError, reason: "Redirect issue".mnDebug(add: "AppRedirectMiddleware.constructRedirectURL failed URL init"))
        }
        
        // Url Query or root key / value
        var params : [String:String] = [:]
        var headers : HTTPHeaders? = nil
        
        for directive in self.redirectDirectives.elements {
            let paramName = directive.asQueryParameterName
            switch directive {
            case .previousRequestId:
                params[paramName] = req.id
            case .sessionId:
                if req.hasSession {
                    params[paramName] = req.id
                }
            case .sessionUserId:
                var userId : UUID? = req.getFromReqStore(key: ReqStorageKeys.selfUserID, getFromSessionIfNotFound: true)
                if userId == nil, let userSession : UserSession = req.getFromReqStore(key: ReqStorageKeys.userSession, getFromSessionIfNotFound: true) {
                    userId = userSession.accessToken.$user.id
                }
                if let userId = userId {
                    params[paramName] = userId.uuidString
                }
            default:
                break
            }
        }
        
        // Add url params
        if req.method == .GET {
            url.append(queryItems: params.compactMap({ elem in
                guard elem.key.count > 0 && elem.value.count > 0 else {
                    return nil
                }
                
                return URLQueryItem(name: elem.key, value: elem.value)
            }))
            headers = HTTPHeaders()
        } else {
            headers = (headers ?? HTTPHeaders(dictionaryLiteral: ("X-Redirected-Params", params.serializeToJsonString()!)))
        }
        headers?.replaceOrAdd(name: "X-Redirected-Source", value: req.refererURL?.relativeString ?? req.url.url.relativeString)
        
        return AppRedirectMatch(redirectURL: url, headers: headers, matchedRule: self)
    }
    
    public func matches(req : Request, response:Response?, isLog:Bool = false, isShouldThrow:Bool = false) throws ->AppRedirectMatch? {
        let tab = "   "
        
        @discardableResult
        func handle(_ code:MNErrorCode, dbgReason:String) throws -> Bool {
            let msg = "redirection failed: ".mnDebug(add: dbgReason)
            if isShouldThrow {
                throw MNError(code: code, reason: msg)
                // Pseudo return true - did throw / handle
            } else if isLog {
                dlog?.warning("\(tab) AppRedirectRule.matches(req:...) failed: \(dbgReason)")
            }
            return false  // did not throw
        }
        
        // Guard for reposne parameter is nil
        if response == nil, try handle(.http_stt_internalServerError, dbgReason: "response param is nil") {
            return nil // if try did not throw
        }
        
        // Guard for redirect to same url as source:
        if req.url.asNormalizedPathOnly() == self.redirectToPath?.absoluteString.asNormalizedPathOnly() {
            // Prevent recursion! (I.E page A redirecting to page A over and over again..)
            // dlog?.note("\(tab) RedirectRule.matches(req:...) ")
            try handle(.http_stt_internalServerError, dbgReason: "target path and source path equal: preventing recursion \(req.url.asNormalizedPathOnly())")
            return nil // if try did not throw
        }
        
        // Route of the calling request
        let route = req.refererRoute ?? req.route
        
        // 1. Match sourceGroupTag if specified:
        if let srcTag = sourceGroupTag?.lowercased(), let targetTag = route?.mnRouteInfo?.groupTag.lowercased(), srcTag != targetTag {
            try handle(.http_stt_internalServerError, dbgReason: "groupTag mismatch \(srcTag)!=\(targetTag)")
            return nil // if try did not throw
        }
        
        // 2. Match responseStatus and response.status
        if let responseStatii = self.responseStatii, responseStatii.first(where: { statii in
            statii.matches(httpStatus: response?.status ?? .notImplemented)
        }) == nil {
            // Not even one ResponseStatii filter matched the actural response.status
            try handle(.http_stt_internalServerError, dbgReason: "Not even one ResponseStatii filter matched the actual response.status")
            return nil // if try did not throw
        }
        
        // 3. Match sourcePath and sourceMethod if specified:
        if let sourceURL = sourcePath {
            if let route = route, route.mnRouteInfo?.canonicalRoute?.matches(url: sourceURL, method:self.sourceMethod) ?? false {
                try handle(.http_stt_internalServerError, dbgReason: "route canonicalRoute mismatch")
                return nil
            }
        } else if let srcMethod = self.sourceMethod, let route = route, route.method != srcMethod {
            try handle(.http_stt_internalServerError, dbgReason: "req methods mismatch \(srcMethod) != \(route.method)")
            return nil
        }
        
        // Return result
        let match = try self.constructRedirectMatch(req: req, response: response)
        return match
    }
}

extension AppRedirectRule : CustomDebugStringConvertible {
    
    // MARK: CustomDebugStringConvertible
    public var debugDescription: String {
        let tab = "  "
        var strings : [String] = []
        if let sourceGroupTag = sourceGroupTag {
            strings.append("\(tab)tag : \(sourceGroupTag)")
        }
        if let sourcePath = sourcePath {
            strings.append("\(tab)path : \(sourcePath)")
        }
        if let sourceMethod = sourceMethod {
            strings.append("\(tab)method : \(sourceMethod)")
        }
        if let responseStatii = responseStatii {
            strings.append("\(tab)statuses : \(responseStatii.descriptionJoined)")
        }
        
        return "AppRedirectRule : [\n" + strings.joined(separator: "\n") + "\n]"
    }
    
    
}
