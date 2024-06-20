//
//  AppAliases.swift
//
//
//  Created by Ido Rabin for Bricks on 17/1/2024.
//

import Foundation
import MNUtils
import MNSettings
import MNVaporUtils

// This allows sublassing or extending without changing all code appearances:
typealias Semver = MNSemver
public typealias AppErrorCode = MNErrorCode
public typealias AppErrorInt = MNErrorInt
public typealias AppDBEnum = MNDBEnum
// public typealias AppUser = MNUser
// public typealias AppAccessToken = MNAccessToken
public typealias AppSettable = MNSettable
public typealias AppResult = MNResult
public typealias AppResult3 = MNResult3

// public typealias AppRouteInfo = MNRouteInfo
// public typealias AppRouteContext = MNRouteContext
public typealias AppErrorStruct = MNErrorStruct

public protocol AppPermissionGiver {
    
}

typealias AppError = MNError // NOTE: suclassing will abolish visibility of convenience inits
extension AppError {
    static var DEFAULT_DOMAIN =  MNDomains.DEFAULT_DOMAIN + ".AppError"
    
    public func appErrorCode() -> AppErrorCode? {
        return self.mnErrorCode()
    }
}
