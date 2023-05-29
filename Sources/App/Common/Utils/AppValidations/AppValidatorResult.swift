//
//  AppValidatorResult.swift
//  
//
//  Created by Ido on 28/11/2022.
//

import Fluent
#if VAPOR
import Vapor

public typealias AppValidatorResult = Vapor.ValidatorResult
// Vapor.ValidatorResult requires EXACTLY the same protocol implementation / signatures as AppValidatorResult
// This way, we can validate exactly the same way in Client and server.

#else

public protocol AppValidatorResult {
    var isFailure: Bool { get }
    var successDescription: String? { get }
    var failureDescription: String? { get }
    var failureCode: Int? { get }
}

#endif





