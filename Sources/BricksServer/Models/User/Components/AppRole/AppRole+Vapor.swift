//
//  File.swift
//  
//
//  Created by Ido on 16/12/2022.
//

import Foundation
import DSLogger

#if VAPOR
import Vapor
import Fluent
import FluentKit
import FluentPostgresDriver

fileprivate let dlog : DSLogger? = DLog.forClass("User")

/*
// Extensions requiring no implementations
extension AppRole : Content {} // Convertible to / from content in an HTTP message.

extension AppRole : AsyncResponseEncodable, ResponseEncodable {}

/// Keys for data stored in the User of Requests:
struct AppRoleStorageKey : ReqStorageKey {
    typealias Value = AppRole
}

 */
#endif //  #if VAPOR

