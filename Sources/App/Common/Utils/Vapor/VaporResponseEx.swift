//
//  VaporResponseEx.swift
//  
//
//  Created by Ido on 04/11/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("VaporResponseEx")

// Response is a final class!
extension Vapor.Response {
    
    @discardableResult
    static func headersForEnrich(with request:Request)->[String:String] {
        var result : [String:String] = [:]
        
        // Return the request UUID for comparisons w/ log / error logs / dashboards / analytics..
        let uuidString = request.requestUUIDString
        if AppSettings.shared.server?.isShouldRespondWithRequestUUID ?? true, uuidString.count > 0 {
            let key = "X-\(AppConstants.APP_NAME)-request-uuid"
            result[key] = uuidString
        }
        
        if AppSettings.shared.server?.isShouldRespondWithSelfUserUUID ?? true,
           let userUUIDStr = request.selfUserUUIDString {
            let key = "X-\(AppConstants.APP_NAME)-request-self-user-uuid"
            result[key] = userUUIDStr
        }
        
        return result
    }
    
    /// Enriches the response headers with debug or other key / values (mutates the instance)
    /// - Parameter request: request to use data to enrich the response headers with
    /// - Returns: keys of all header fields added / updated
    @discardableResult
    func enrich(with request:Request)->[String] {
        let headers = Response.headersForEnrich(with: request)
        for (key, val) in headers {
            self.headers.replaceOrAdd(name: key, value: val)
        }
        return headers.keysArray
    }
}

// HTTPHeadersEx

extension HTTPHeaders {
    
    enum ClientType {
    case browser
    case mobileDevice
    case desktop
    case unknown
    }
    
    var clientType : ClientType {
        let result : ClientType = .unknown
        func get(_ name : String)->[String]? {
            if self.contains(name: name) {
                return self[name]
            }
            return nil
        }
        
        if let ua = get("User-Agent") ?? get("user-agent") ?? get("useragent") {
            // TODO: Implement
            dlog?.todo("Implement detecting user-agent! [\(ua.descriptionsJoined)]")
        }
        
        return result
    }
    
    /// Enriches the headers headers with debug or other key / values (mutates the instance)
    /// - Parameter request: request to use data to enrich the response headers with
    /// - Returns: keys of all header fields added / updated
    @discardableResult
    mutating func enrich(with request:Request)->[String] {
        let headers = Response.headersForEnrich(with: request)
        for (key, val) in headers {
            self.add(name: key, value: val)
        }
        return headers.keysArray
    }
    
}
