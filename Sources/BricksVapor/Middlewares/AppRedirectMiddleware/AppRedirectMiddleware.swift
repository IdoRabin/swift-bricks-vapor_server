//
//  AppRedirectMiddleware.swift
//
//
//  Created by Ido on 05/02/2024.
//

import Foundation
import Vapor
import NIOCore
import LeafKit
import Logging
import MNUtils
import MNVaporUtils

fileprivate let dlog : Logger? = Logger(label:"AppRedirectMiddleware")
fileprivate let dlogVerbose : Logger? = nil // Logger(label:"AppRedirectMiddlewareVe")

// NOTE: AppErrorStruct == MNErrorStruct - see AppAliases and MNErrorStruct
// These structures are built to represent errors (also underlying errors, even nested ones) to the user / consumer

// NOTE: use AppRedirectMiddleware to redirect after error using redirectRules
// AppRedirectMiddleware should be placed EARLIER (before) the error handling middleware to catch the errors handled there
final class AppRedirectMiddleware: Middleware {
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    private let redirectRules:[AppRedirectRule]?
    private let extensionsToIgnore : [String] = ["xml", "css", "js", "mjs", "jpg", "ico", "jpeg", "png", "tiff", "svg", "pdf", "html", "wav", "mpg", "mpeg", "aud", "mkv", ""]
    
    // MARK: Middleware
    func respond(to request: Vapor.Request, chainingTo next: Vapor.Responder) -> NIOCore.EventLoopFuture<Vapor.Response> {
        let result : NIOCore.EventLoopFuture<Vapor.Response> = next.respond(to: request)
        let reqExtension = request.url.url.pathExtension.lowercased()
        
        // We optimize by NOT checking on these URLs:
        guard reqExtension.count == 0 || !extensionsToIgnore.contains(reqExtension) else {
            // Extensions to ignore making a redirect check on:
            return result
        }
            
        // Prevent recusrion loops consider page A redirecting to B: A>B>C>A>B>A etc.. creating a recursion loop because of a logic failure
        /*if request.hasSession, let prevRedirect : RedirectRecord = request.getFromSessionStore(key: ReqStorageKeys.redirectedFrom) {
            if abs(prevRedirect.date.timeIntervalSinceNow) < 10 /* seconds */ {
                // Prevent redirect recursion
                dlog?.note("AppRedirectMiddleware suspected redirection loop: \(request.method) \(request.url)")
                return result
                // NOTE: !! Return !!
            }
        }*/
        
        let _ /*newResult*/ : NIOCore.EventLoopFuture<Vapor.Response> = result.flatMapThrowing { response in
            // dlog?.info("AppRedirectMiddleware checking req: \(request.id) \(request.method) \(request.url)")
            let result = response
            
            if let rules = self.redirectRules, rules.count > 0, !response.status.isRedirect {
                let match : AppRedirectMatch?  = try self.redirectRules?.firstNonNil({ redirectRule in
                    // Check if the redirect rule matches the current situation:
                    return try redirectRule.matches(req: request, response: response)
                })
                
                // A redirect rule was matched:
                if let match = match {
                    dlogVerbose?.success("AppRedirectMiddleware matched a rule: \(match.matchedRule)")
                    
                    let matchedRule = match.matchedRule
                    dlogVerbose?.success("AppRedirectMiddleware redirecting to: (\(matchedRule.redirectType.status.description)) \"\(matchedRule.redirectToPath?.absoluteString ?? "<nil>" )\"")
                    
                    // Add / Update headers
                    if let headers = match.headers {
                        for (name, value) in headers {
                            response.headers.replaceOrAdd(name: name, value: value)
                        }
                    }
                    
                    // Redirecting:
                    // DO NOT: let _ = request.redirect(to: matchedRule.redirectToPath.string, redirectType: matchedRule.redirectType)
                    response.status = matchedRule.redirectType.status
                    
                    // NOTE: Redirect is NOT relative!
                    let str = match.redirectURL.absoluteString.adddingPrefixIfNotAlready("/")
                    response.headers.replaceOrAdd(name: .location, value: str)
                    
                    // Save redirect to history / session:
                    let srcURL = request.refererURL ?? request.url.url
                    if srcURL.relativePath != match.redirectURL.relativePath {
                        // Save the redirect-To info into history:
                        let record = MNRoutingHistoryItem.Redirection(url: match.redirectURL, reqId: request.id, status: response.status)
                        try request.routeHistory?.update(req: request, response: response, action: .redirectedTo(record))
                        dlogVerbose?.info(">>  >> Save the redirect-To: \(record.shortDescription)")
                    } else {
                        dlogVerbose?.note(">>  >> Save the redirect-To failed: srcURL != match.redirectURL \(srcURL.relativePath) != \(match.redirectURL.relativePath)")
                    }
                }
                
                return response
            }
            
            // dlog?.info("AppRedirectMiddleware. returning result: \(response.status) \(response.headers.debugDescription)")
            return result
        }
        
        return result
    }
    
    // MARK: Private
    // MARK: Lifecycle
    init(redirectRules: [AppRedirectRule]? = nil) {
        self.redirectRules = redirectRules
    }
    // MARK: Public
    
}
