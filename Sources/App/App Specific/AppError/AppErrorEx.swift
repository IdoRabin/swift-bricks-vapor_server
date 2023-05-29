//
//  AppErroEx.swift
//  
//
//  Created by Ido on 27/05/2023.
//

import Foundation

extension AppError : Equatable {
    public static func == (lhs: AppError, rhs: AppError) -> Bool {
        var result = lhs.domain == rhs.domain && lhs.code == rhs.code
        if result {
            if lhs.hasUnderlyingError != rhs.hasUnderlyingError {
                result = false
            } else if let lhsu = lhs.underlyingError, let rhsu = rhs.underlyingError {
                result = lhsu == rhsu
            }
        }
        return result
    }
}

extension AppError : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.code)
        hasher.combine(self.reasons)
        hasher.combine(self.reason)
    }
}

extension Result where Failure : AppError {
    
    var appError : AppError? {
        switch self {
        case .success: return nil
        case .failure(let err): return err
            // default: return nil
        }
    }
}
