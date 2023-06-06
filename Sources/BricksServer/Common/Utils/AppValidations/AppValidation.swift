//
//  File.swift
//  
//
//  Created by Ido on 28/11/2022.
//

import Foundation
#if VAPOR
import Vapor

public typealias AppValidation = Vapor.Validation

#else

public struct AppValidation {
    let run: (KeyedDecodingContainer<AppValidationKey>) -> AppValidationResult
}

#endif
