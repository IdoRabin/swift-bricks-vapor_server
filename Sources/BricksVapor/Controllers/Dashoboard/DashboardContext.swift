//
//  DashboardContext.swift
//
//
//  Created by Ido on 17/02/2024.
//

import Foundation
import Vapor
import MNUtils
import MNVaporUtils
import Logging

fileprivate let dlog : Logger? = nil //Logger(label:"DashboardContext")

/// Context for rendering Dashboard leaf views
class DashboardContext : Codable {
    let title: String?
    let user : User.Public?
    let accessToken : AccessToken.Public?
    let is_logged_in : Bool
    let error : MNErrorStruct?
    var table : FluentLeafTableview?
    
    fileprivate static func extractErrorTuple(for req: Request, withReqId reqId: String)->(MNRoutingHistoryItem, MNErrorStruct)? {
        
        // NOTE: RouteHistory related to the whole session, not just the current request.
        guard let item = req.routeHistory?.findItem(reqId: reqId), var errorStruct = item.lastErrorStruct else {
            return nil
        }
        
        // In redirect cases, the causing error in the underlyingError
        if errorStruct.error_http_status?.isRedirect == true &&
            errorStruct.hasUnderlyingError == true {
            let prev = errorStruct
            errorStruct = errorStruct.underlying_errors!.first!
            if let path = prev.error_originating_path {
                errorStruct.update(originatingPath: path)
            }
            if let reqId = prev.error_request_id {
                errorStruct.update(reqId: reqId)
            }
        }

        return (item, errorStruct)
    }
    
    fileprivate static func extractErrorStruct(for req: Request)->MNErrorStruct? {
        var errorStruct : MNErrorStruct? = nil

        // 1. user req_id in the url params to find the error:
        var reqId : String? = nil
        var item : MNRoutingHistoryItem? = nil
        
        if errorStruct == nil, let areqId = req.parameters.get("req_id") ?? req.url.query?.asQueryParams()?["req_id"] {
            if let tuple = self.extractErrorTuple(for: req, withReqId: areqId) {
                dlog?.info("Context found an error by req_id params! tuple: \(tuple)")
                item = tuple.0
                errorStruct = tuple.1
                reqId = areqId
            }
        }
        
        // 2. Or Get the last redirect error, validate the redirect from/to pair, and use the eror:
        if errorStruct == nil, let from = req.routeHistory?.last?.lastRedirectedFrom, let to = req.routeHistory?.oneBeforeLast?.lastRedirectedTo {
            if from.reqId == to.reqId &&
                req.url.url == to.url {
                if let tuple = self.extractErrorTuple(for: req, withReqId: from.reqId) {
                    dlog?.info("Context found an error by lastRedirect! \(tuple)")
                    item = tuple.0
                    errorStruct = tuple.1
                    reqId = from.reqId
                }
            }
        }

        // 3. Or use cur or last history item's error:
        if errorStruct == nil {
            // var item : MNRoutingHistoryItem? = nil
            if let aitem = req.routeHistory?.last, let aerr = aitem.lastErrorStruct {
                item = aitem
                errorStruct = aerr
                reqId = aitem.requestId
            } else if let aitem = req.routeHistory?.oneBeforeLast, let aerr = aitem.lastErrorStruct {
                item = aitem
                errorStruct = aerr
                reqId = aitem.requestId
            }
        }
           
        if let astruct = errorStruct {
            if astruct.error_request_id == nil, let reqId = reqId {
                errorStruct?.update(reqId: reqId)
            }
            
            if astruct.error_originating_path == nil, let path = item?.url.relativePath {
                errorStruct?.update(originatingPath: path)
            }
        }
        
        return errorStruct
    }
    
    fileprivate static func extractTitle(for req: Request, error inputError: MNErrorStruct? = nil) throws ->String? {
        var result = req.route?.mnRouteInfo?.title ?? ""
        
        // If this an error page, we extranct the error code or error reason / title
        if req.route?.mnRouteInfo?.canonicalRoute?.urlStr == "dashboard/error" {
            if var errorStruct = inputError ?? req.routeHistory?.last?.lastErrorStruct {
                
                // In redirect cases, the causing error in the underlyingError
                if errorStruct.error_http_status?.isRedirect == true && errorStruct.hasUnderlyingError {
                    errorStruct = errorStruct.underlying_errors!.first!
                }
                
                if result.count == 0 {
                    result = errorStruct.error_reason
                }
                
                if result.count == 0 {
                    result = "Error"
                }
                
                if let code = errorStruct.error_code {
                    result += " \(code)"
                }
                
                for item in req.routeHistory?.debugDescLines() ?? [] {
                    dlog?.info("|> \(item)")
                }
                dlog?.info("Error page found errorStruct: \(errorStruct.serializeToJsonString(prettyPrint: true) ?? "<nil>" )")
            }
        }
        
        if result.count == 0 {
            result = req.route?.path.last?.description.capitalized ?? ""
        }
        return result
    }
    
    init(req:Request, tableView:FluentLeafTableview? = nil) throws {
        self.user = try req.auth.get(User.self)?.asPublic()
        self.accessToken = try req.auth.get(AccessToken.self)?.asPublic()
        self.is_logged_in = (self.user?.id != nil) && (self.accessToken?.token != nil)
        let err = Self.extractErrorStruct(for:req)
        self.error = err
        self.title = try Self.extractTitle(for: req, error: err)
        self.table = tableView
    }
}
