//
//  AppAliases.swift
//  
//
//  Created by Ido on 13/07/2023.
//

import Foundation
import MNUtils
import MNSettings
import MNVaporUtils

// This allows sublassing or extending without changing all code appearances:
public typealias AppErrorCode = MNErrorCode
public typealias AppErrorInt = MNErrorInt
public typealias AppDBEnum = MNDBEnum
public typealias AppRoute = MNRoute
public typealias AppRouteInfo = MNRouteInfo
public typealias AppUser = MNUser
public typealias AppSettable = MNSettable
public typealias AppRouteContext = MNRouteContext
public protocol AppPermissionGiver {
    
}

typealias AppError = MNError // NOTE: suclassing will abolish visibility of convenience inits
extension AppError {
    static var DEFAULT_DOMAIN = "com.\(AppConstants.APP_NAME.snakeCaseToCamelCase())"
    
    public func appErrorCode() -> AppErrorCode? {
        return self.mnErrorCode()
    }
}
