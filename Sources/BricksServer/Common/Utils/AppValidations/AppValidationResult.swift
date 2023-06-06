//
//  AppValidationResult.swift
//  
//
//  Created by Ido on 28/11/2022.
//

import Foundation

typealias AppValidatorSuccessReason = String
typealias AppValidationResult = AppResult<AppValidatorSuccessReason>

extension AppValidationResult : AppValidatorResult {
    // Adapt the protocol to return response values from AppResult<AppValidatorSuccessReason>
    
    public var failureCode: Int? {
        return self.appError?.code
    }
    
    public var isFailure: Bool {
        return self.isFailed
    }
    
    public var successDescription: String? {
        switch self {
        case .failure: return nil
        case .success(let successReason): return successReason
        }
    }
    
    public var failureDescription: String? {
        return self.appError?.reasonsLines ?? self.appError?.reason
    }
    
    static func by(test:()->Bool, success:Success, error:AppError)->AppResult<Success> {
        if test() {
            return AppResult.success(success)
        } else {
            return AppResult<Success>.failure(error)
        }
    }
    
    static func by(test:()->Bool, success:Success, errorCode:AppErrorCode, errorReason:String)->AppResult<Success> {
        if test() {
            return AppResult.success(success)
        } else {
            return AppResult<Success>.failure(code: errorCode, reason: errorReason)
        }
    }
}
