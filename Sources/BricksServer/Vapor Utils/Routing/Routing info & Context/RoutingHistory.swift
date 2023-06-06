//
//  File.swift
//  
//
//  Created by Ido on 20/11/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("RoutingHistory")

extension Redirect {
    static let all : [Redirect] = [.normal, .permanent, .temporary]
    static let allHttpStatuses : [HTTPStatus] = [Redirect.normal.status, Redirect.permanent.status, Redirect.temporary.status]
}

struct AppRoutingHistoryStorageKey : ReqStorageKey {
    typealias Value = RoutingHistory
}


class RoutingHistoryItem : JSONSerializable, Hashable, CustomStringConvertible {
    // MARK: Members
    let requestID : String
    let path : String
    let httpMethod : HTTPMethod
    var appError : AppError? = nil // settable
    
    enum CodingKeys : CodingKey {
        case requestID
        case path
        case httpMethod
        case completeCode
        case completeReason
    }
    
    var httpStatus : HTTPStatus? {
        guard let code = appError?.code else {
            return nil
        }
        
        // Only when http status is involved
        if code >= 100 && code < 600 {
            return HTTPStatus(statusCode: code)
        }
        
        return nil
    }
    // MARK: Lifecycle
    init(requestID: String, path: String, httpMethod: HTTPMethod) {
        self.requestID = requestID
        self.path = path.asNormalizedPathOnly()
        self.httpMethod = httpMethod
    }
    
    // MARK: public
    
    // mutating
    private func setAppError(intCode:Int, reason:String?) {
        let err = AppError(code: AppErrorCode(rawValue: intCode)!, reason: reason)
        self.setAppError(err)
    }
    
    private func setAppError(code:AppErrorCode, reason:String?) {
        let err = AppError(code: code, reason: reason)
        self.setAppError(err)
    }
    
    private func setAppError(code:AppErrorCode, reasons:[String]) {
        let err = AppError(code: code, reasons: reasons)
        self.setAppError(err)
    }
    
    private func setAppError(errorable:AppErrorable) {
        // domain:nsError.domain, intCode: errorable.code, reason: errorable.reason
        let adomain = errorable.domain // ?? AppError.DEFAULT_DOMAIN
        let err = AppError(domain: adomain, code: errorable.code, description: "AppError from AppErrorable", reasons: [errorable.reason], underlyingError: nil)
        self.setAppError(err)
    }
    
    private func setAppError(nsError:NSError) {
        let err = AppError(nsError: nsError, defaultErrorCode: .misc_unknown, reason: nsError.reason)
        self.setAppError(err)
    }
    
    private func setAppError(_ newAppError : AppError) {
        let errToSet = newAppError
        if let _ = self.appError, let newStatus = newAppError.httpStatus,
                Redirect.allHttpStatuses.contains(newStatus) {
            // This is a redirect "error":
            // TODO: Should we wrap redirect "error" as underlying or to contain the other error as underlying error
            return
        }
        self.appError = errToSet
    }
    
    func setAppError(abort : Abort) {
        var reasons = [abort.status.reasonPhrase]
        if abort.reason.count > 0 && abort.reason != abort.status.reasonPhrase {
            reasons.append(abort.reason)
        }
        self.setAppError(code:AppErrorCode(rawValue: abort.code)!, reasons: reasons)
    }
    
    func setHttpStatus(_ stt : HTTPStatus) {
        let intCode = Int(stt.code)
        self.setAppError(code:AppErrorCode(rawValue: intCode)!, reason: stt.reasonPhrase)
    }
    
    func clearError() {
        self.appError = nil
    }
    
    func setError(_ appError : AppError) {
        self.setAppError(appError)
    }
    
    func setError(_ appError : AppErrorable) {
        self.setAppError(errorable: appError)
    }
    
    func setError(_ nsError : NSError) {
        self.setAppError(nsError:nsError)
    }
    
    // MARK: Equatable
    static func == (lhs: RoutingHistoryItem, rhs: RoutingHistoryItem) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    // MARK: Hahsable
    func hash(into hasher: inout Hasher) {
        hasher.combine(requestID)
        hasher.combine(path)
        hasher.combine(httpMethod)
        hasher.combine(appError)
    }
    
    // MARK: CustomStringConvertible
    var description: String {
        let mth = "\(httpMethod)".paddingLeft(toLength: 5, withPad: " ")
        var result = "\(mth) \(requestID) \(path)"
        var error = appError
        while error != nil {
            if let err = error {
                let reasonses = err.reasons?.descriptions().joined(separator: ", ") ?? err.reason
                result += " [\(err.code) \(reasonses)]"
                error = err.underlyingError
            } else {
                break
            }
        }
        return result
    }
    
    // MARK: Encode
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.requestID = try container.decode(String.self, forKey:CodingKeys.requestID)
        self.path = try container.decode(String.self, forKey:CodingKeys.path)
        self.httpMethod = try container.decode(HTTPMethod.self, forKey:CodingKeys.httpMethod)
        if let code : Int = try container.decodeIfPresent(Int.self, forKey:CodingKeys.completeCode),
           let reason : String = try container.decodeIfPresent(String.self, forKey:CodingKeys.completeReason) {
            self.appError = AppError(code:AppErrorCode(rawValue: code)!, reason:reason)
            // dlog?.success("init(from:decoder) w/ error: \(self.description) error: >> \(code) >> \(reason)")
        } else {
            // dlog?.fail("init(from:decoder) NO error: \(self.description)")
        }
    }
    
    // MARK: Decode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        do {
            try container.encode(requestID, forKey:CodingKeys.requestID)
            try container.encode(path, forKey:CodingKeys.path)
            try container.encode(httpMethod, forKey:CodingKeys.httpMethod)
        } catch let error {
            dlog?.warning("encode(to encoder:) failed with encoding props into \(self) ERROR: \(String(describing:error))")
        }
        if let appError : AppError = appError {
            do {
                try container.encode(appError.code, forKey:CodingKeys.completeCode)
                try container.encode(appError.reason, forKey:CodingKeys.completeReason)
                //dlog?.success("encode(to encoder:) w/ AppError: \(self)")
            } catch let error {
                dlog?.warning("encode(to encoder:) failed with encoding AppError: \(appError.description) into \(self) ERROR: \(String(describing:error))")
            }
        } else {
            dlog?.fail("encode(to encoder:) NO AppError: \(self)")
        }
    }
}

// This class should NOT save
class RoutingHistory : JSONSerializable, Hashable, CustomStringConvertible {
    static let DEFAULT_MAX_ITEMS = 5
    
    // MARK: static
    static let UNKNOWN_REQ_ID = "UNKNOWN_REQ_ID"
    
    // MARK: members
    var items : [RoutingHistoryItem] = []
    @AppSettable(name: "RoutingHistory.maxItems", default: RoutingHistory.DEFAULT_MAX_ITEMS) static var maxItems : Int
    
    // MARK: Getters / computed properties
    var first : RoutingHistoryItem? {
        return items.first
    }
    
    var last : RoutingHistoryItem? {
        return items.last
    }
    
    var oneBeforeLast : RoutingHistoryItem? {
        guard items.count > 1 else {
            return nil
        }
        return items[items.count - 2]
    }
    
    // MARK: private
    func save(to req:Request) {
        req.saveToSessionStore(key: ReqStorageKeys.appRouteHistory, value: self)
    }
    
    // MARK: public Add / update funcs
    @discardableResult
    func update(path:String, method:HTTPMethod, reqId:String, error:AppError?)->RoutingHistoryItem {
        var result : RoutingHistoryItem!
        if let historyItem = self.items.first(where: { item in
            item.requestID == reqId && item.httpMethod == method
        }) {
            // Item already existed
            result = historyItem
            // dlog?.successOrFail(condition: error != nil, "update EXs \(historyItem) with error:\(error?.reason ?? "<nil>")")
        } else {
            // New item required:
            let newHistoryItem = RoutingHistoryItem(requestID: reqId, path: path, httpMethod: method)
            // dlog?.successOrFail(condition: error != nil, "adding NEW \(newHistoryItem) with error:\(error?.reason ?? "<nil>")")
            self.items.append(newHistoryItem)
            if self.items.count > 0 && self.items.count > Self.maxItems {
                // This class should NOT contain all the browsing history in a session, jut the recent calls to allow managing redirects etc..
                self.items.remove(at: 0)
            }
            result = newHistoryItem
        }
        
        // Udate error or clear it:
        if let err = error {
            result.setError(err)
        } else {
            result.clearError()
        }
        
        return result
    }
    
    @discardableResult
    func update(path:String, method:HTTPMethod, reqId:String, error:Abort?)->RoutingHistoryItem {
        var err : AppError? = nil
        if let error = error {
            err = AppError(code:AppErrorCode(rawValue: Int(error.code))!, reason: error.reason)
        }
        return self.update(path: path, method: method, reqId: reqId, error: err)
    }
    
    @discardableResult
    func update(path:String, method:HTTPMethod, reqId:String, error:Error?)->RoutingHistoryItem {
        var err : AppError? = nil
        if let error = error as? NSError {
            err = AppError(code:AppErrorCode(rawValue: Int(error.code))!, reason: error.reason)
        }
        return self.update(path: path, method: method, reqId: reqId, error: err)
    }
    
    @discardableResult
    func update<Succ>(req:Request, result resultT:Result<Succ, Error>)->RoutingHistoryItem {
        var result :  RoutingHistoryItem!
        switch resultT {
        case .success:
            result = self.update(path: req.url.path,
                                 method: req.method,
                                 reqId: req.requestUUIDString,
                                 error: AppError(code: .http_stt_ok, reason: HTTPStatus.ok.reasonPhrase))
        case .failure(let err):
            if let abort = err as? Abort {
                result =  self.update(path: req.url.path,
                                      method: req.method,
                                      reqId: req.requestUUIDString,
                                      error: AppError(code:AppErrorCode(rawValue: AppErrorInt(abort.status.code))!, reason: abort.reason))
            } else if let appErr = err as? AppError {
                result = self.update(path: req.url.path,
                                     method: req.method,
                                     reqId: req.requestUUIDString,
                                     error:appErr)
            } else {
                let nsErr = err as NSError
                result = self.update(path: req.url.path,
                                     method: req.method,
                                     reqId: req.requestUUIDString,
                                     error:AppError(code:AppErrorCode(rawValue: nsErr.code) ?? AppErrorCode.misc_unknown, reason: nsErr.reason))
            }
        }
        self.save(to: req)
        return result
    }
    
    @discardableResult
    func update(req:Request, error:Error)->RoutingHistoryItem {
        let res : Result<Bool, Error> = .failure(error)
        return self.update(req: req, result: res)
    }
    
    @discardableResult
    func update(req:Request, status:HTTPStatus?)->RoutingHistoryItem {
        var error : AppError? = nil
        if let status = status {
            error = AppError(code:AppErrorCode(rawValue: AppErrorInt(status.code))!, reason: status.reasonPhrase)
        }
        let result = self.update(path: req.url.path, method: req.method, reqId: req.requestUUIDString, error: error)
        self.save(to: req)
        return result
    }
    
    @discardableResult
    func update(req:Request, response:Response? = nil)->RoutingHistoryItem {
        return self.update(req: req, status: response?.status)
    }
    
    // MARK: Equatable
    static func == (lhs: RoutingHistory, rhs: RoutingHistory) -> Bool {
        return lhs.items == rhs.items
    }
    
    // MARK: Hahsable
    func hash(into hasher: inout Hasher) {
        hasher.combine(items)
    }
    
    // MARK: CustomStringConvertible
    var description: String {
        return items.descriptionLines
    }
}
