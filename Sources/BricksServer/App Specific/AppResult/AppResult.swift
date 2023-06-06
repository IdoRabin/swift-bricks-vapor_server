//
//  AppResult.swift
//
//  Created by Ido on 08/11/2021.
//

import Foundation
import MNUtils

typealias AppResult<Success:Any> = Result<Success, AppError>
typealias AppResultBlock<Success:Any> = (AppResult<Success>)->Void

func AppResultOrErr<Success:Any>(_ result:Success?, error:AppError)->AppResult<Success> {
    if let result = result {
        return AppResult.success(result)
    } else {
        return AppResult.failure(error)
    }
}

extension Result {
    
    static func failure<Success:Any>(fromError error:Error)->AppResult<Success> {
        if let apperror = error as? AppError {
            return AppResult.failure(apperror)
        } else {
            return AppResult.failure(AppError(error: error))
        }
        
    }
    
    static func failure<Success:Any>(fromAppError appError:AppError)->AppResult<Success> {
        return AppResult.failure(appError)
    }
    
    static func failure<Success:Any>(code appErrorCode:AppErrorCode, reason:String? = nil)->AppResult<Success> {
        return AppResult.failure(AppError(code:appErrorCode, reason: reason))
    }
    
    static func failure<Success:Any>(code appErrorCode:AppErrorCode, reasons:[String]? = nil)->AppResult<Success> {
        return AppResult.failure(AppError(code:appErrorCode, reasons: reasons))
    }
    
    static func fromError<Success:Any>(_ error:Error?, orSuccess:Success)->AppResult<Success> {
        if let appError = error as? AppError {
            return Self.fromAppError(appError, orSuccess: orSuccess)
        } else if let err = error {
            return Self.fromAppError(AppError(error: err), orSuccess: orSuccess)
        } else {
            return .success(orSuccess)
        }
    }
    
    static func fromAppError<Success:Any>(_ appError:AppError?, orSuccess:Success)->AppResult<Success> {
        if let appError = appError {
            return .failure(appError)
        } else {
            return .success(orSuccess)
        }
    }
}

// Description for CustomStringConvertibles
extension Result where Success : CustomStringConvertible, Failure : CustomStringConvertible {
    var description : String {
        switch self {
        case .success(let success):
            return ".success(\(success.description.safePrefix(maxSize: 180, suffixIfClipped: "...")))"
        case .failure(let err):
            return ".failure(\(err.description.safePrefix(maxSize: 180, suffixIfClipped: "...")))"
        }
    }
}

// UNCOMMENT: 
//extension MNResult3 {
//    var asAppResult : AppResult<Success> {
//        switch self {
//        case .successChanged(let success):  return AppResult.success(success)
//        case .successNoChange(let success): return AppResult.success(success)
//        case .failure(let failure):         return AppResult<Success>.failure(fromError: failure)
//        }
//    }
//}
