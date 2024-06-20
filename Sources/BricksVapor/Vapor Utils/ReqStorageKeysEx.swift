//
//  ReqStorageKeysEx.swift
//
//
//  Created by Ido on 24/01/2024.
//

import Foundation
import MNVaporUtils

extension ReqStorageKeys {
    static let userSession = UserSessionStorageKey.self
//    static let user = UserStorageKey.self
//    static let accessToken = AccessTokenStorageKey.self
    
    // static public let selfLoginInfo = SelfLoginInfoStorageKey.self
    // static public let selfUser = SelfUserStorageKey.self
    
//    static public let selfAccessToken = SelfAccessTokenStorageKey.self
//    static public let appRouteContext = MNRouteContextStorageKey.self
//    static public let appRouteHistory = MNRoutingHistoryStorageKey.self
//    static public let userPIIInfos = UserPIIInfosStorageKey.self
//    static public let userPIIs = UserPIIsStorageKey.self
//    static public let loginInfos = UserLoginInfosStorageKey.self
}


struct UserSessionStorageKey : ReqStorageKey {
    typealias Value = UserSession
}
    
//struct UserStorageKey : ReqStorageKey {
//    typealias Value = User
//}
//
//struct AccessTokenStorageKey : ReqStorageKey {
//    typealias Value = AccessToken
//}

//public struct UserPIIInfosStorageKey : ReqStorageKey {
//    public typealias Value = [MNPIIInfo]
//}

//public struct UserPIIsStorageKey : ReqStorageKey {
//    public typealias Value = [MNUserPII]
//}
//
//public struct UserLoginInfosStorageKey : ReqStorageKey {
//    public typealias Value = [MNUserLoginInfo]
//}
//
//public struct SelfUserStorageKey : ReqStorageKey {
//    public typealias Value = MNUser
//}
//
//public struct SelfLoginInfoStorageKey : ReqStorageKey {
//    public typealias Value = MNUserLoginInfo
//}
