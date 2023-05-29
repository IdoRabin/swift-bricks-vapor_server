//
//  File.swift
//  
//
//  Created by Ido on 27/05/2023.
//

import Foundation
import MNUtils

extension Result3 where Failure : AppError {
    
    var appError : AppError? {
        switch self {
        case .successNoChange: return nil
        case .successChanged: return nil
        case .failure(let err): return err
            // default: return nil
        }
    }
}
