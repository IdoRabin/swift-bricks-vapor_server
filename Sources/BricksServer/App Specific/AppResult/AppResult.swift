//
//  AppResult.swift
//
//  Created by Ido on 08/11/2021.
//

import Foundation
import MNUtils

typealias AppResult<Success:Any> = MNResult<Success>
typealias AppResultBlock<Success:Any> = MNResultBlock<Success>

public extension AppResult {
    var appErrorValue : MNError? {
        return self.mnErrorValue
    }
}

func AppResultOrErr<Success:Any>(_ result:Success?, error:AppError)->AppResult<Success> {
    if let result = result {
        return AppResult.success(result)
    } else {
        return AppResult.failure(error)
    }
}

extension Result {
    
    // <Success:Any>
    static func failure(fromError error: any Error)->AppResult<Success> {
        var result : AppResult<Success>
        
        if let appError = error as? AppError {
            result = .failure(appError)
        } else {
            let appError = AppError(nserror: error as NSError)
            result = .failure(appError)
        }
        return result
    }
    
    static func failure(fromAppError appError:AppError)->AppResult<Success> {
        return AppResult.failure(appError)
    }
    
    static func failure(code appErrorCode:AppErrorCode, reason:String? = nil)->AppResult<Success> {
        return AppResult<Success>.failure(fromAppError:AppError(code:appErrorCode, reason:reason))
    }
    
    static func failure(code appErrorCode:AppErrorCode, reasons:[String]? = nil)->AppResult<Success> {
        
        return AppResult<Success>.failure(fromAppError:AppError(code:appErrorCode, reasons:reasons))
    }
    
    static func fromError(_ error:Error?, orSuccess:Success)->AppResult<Success> {
        if let appError = error as? AppError {
            return Self.fromAppError(appError, orSuccess: orSuccess)
        } else if let err = error as? NSError {
            return Self.fromAppError(AppError(nserror: err), orSuccess: orSuccess)
        } else {
            return .success(orSuccess)
        }
    }
    
    static func fromAppError(_ appError:AppError?, orSuccess:Success)->AppResult<Success> {
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
