//
//  ReqStorageKey.swift
//  
//
//  Created by Ido on 03/11/2022.
//

import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("ReqStorageKey")

// MARK: Protocol ReqStorageKey
protocol ReqStorageKey : StorageKey {
    static var asString: String { get }
}

extension ReqStorageKey /* default implementation */  {
    static var asString: String {
        return "\(Self.self)"
    }
}

// MARK: structs implementing ReqStorageKey
struct RedirectedFromStorageKey : ReqStorageKey {
    typealias Value = String
}

struct RequestIdStorageKey : ReqStorageKey {
    typealias Value = String
}

struct ErrorCodeStorageKey : ReqStorageKey {
    typealias Value = Int
}

struct ErrorReasonStorageKey : ReqStorageKey {
    typealias Value = String
}

struct ContextTextStorageKey : ReqStorageKey {
    typealias Value = String
}

struct ErrorTextStorageKey : ReqStorageKey {
    typealias Value = String
}

struct ErrorRequestIDStorageKey : ReqStorageKey {
    typealias Value = String
}

struct ErrorOriginatingPathStorageKey : ReqStorageKey {
    typealias Value = String
}

// MARK: class behaving similar to an enum of all ReqStorageKeys:
class ReqStorageKeys {
    // Equivalents of RouteInfoCodingKeys:
//    static let user = UserStorageKey.self
//    static let selfUserID = SelfUserIDStorageKey.self
//    static let selfUser = SelfUserStorageKey.self
//    static let accessToken = AccessTokenStorageKey.self
//    static let selfAccessToken = SelfAccessTokenStorageKey.self
    static let requestId = RequestIdStorageKey.self
    static let redirectedFrom = RedirectedFromStorageKey.self
    static let contextText = ContextTextStorageKey.self
//    static let appRouteContext = AppRouteContextStorageKey.self
//    static let appRouteHistory = AppRoutingHistoryStorageKey.self
    
    static let errorCode = ErrorCodeStorageKey.self
    static let errorReason = ErrorReasonStorageKey.self
    static let errorText = ErrorTextStorageKey.self
    static let errorRequestID = ErrorRequestIDStorageKey.self
    static let errorOriginatingPath = ErrorOriginatingPathStorageKey.self
    
    // Instructions:
//    static let userTokenCreateIfExpired = UserTokenCreateIfExpiredKey.self
//    static let userTokenMakeIfMissing = UserTokenMakeIfMissingKey.self
    
    static var all : [any ReqStorageKey.Type]  = [
//        ReqStorageKeys.user,
//        ReqStorageKeys.selfUserID,
//        ReqStorageKeys.selfUser,
//        ReqStorageKeys.accessToken,
//        ReqStorageKeys.selfAccessToken,
        ReqStorageKeys.requestId,
        ReqStorageKeys.redirectedFrom,
        ReqStorageKeys.errorCode,
        ReqStorageKeys.errorReason,
        ReqStorageKeys.contextText,
//        ReqStorageKeys.appRouteContext,
//        ReqStorageKeys.appRouteHistory,
//        ReqStorageKeys.userTokenCreateIfExpired,
//        ReqStorageKeys.userTokenMakeIfMissing,
    ]
}
