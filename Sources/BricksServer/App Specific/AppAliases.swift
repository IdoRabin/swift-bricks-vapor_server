//
//  AppAliases.swift
//  
//
//  Created by Ido on 13/07/2023.
//

import Foundation
import MNUtils
import MNVaporUtils

public typealias AppErrorCode = MNErrorCode
public typealias AppErrorInt = MNErrorInt
 public typealias AppDBEnum = MNDBEnum

typealias AppError = MNError // NOTE: suclassing will abolish visibility of convenience inits
extension AppError {
    static var DEFAULT_DOMAIN = "com.\(AppConstants.APP_NAME.snakeCaseToCamelCase())"
    
    public func appErrorCode() -> AppErrorCode? {
        return self.mnErrorCode()
    }
}
